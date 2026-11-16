#!/usr/bin/env python3
"""Dependency Watch — read-only outdated check for one repo.

What it does:
  - Runs each enabled ecosystem's own read-only outdated command locally
    (npm outdated, pip list --outdated, dotnet list package --outdated).
  - Groups findings by risk: Security (npm audit advisories) > Major > Minor > Patch.
  - Writes a report with the top N per ecosystem plus a full table appendix.
  - Compares against out/baseline.json and reports "no changes since last
    run" when nothing moved, so the scheduled run is quiet most weeks.

What it NEVER does:
  - Never installs, updates, or modifies anything. No lockfile is touched.
  - No network calls from this script itself. The only network traffic is
    the package managers asking their public registries for version lists
    (npm -> registry.npmjs.org, pip -> pypi.org, dotnet -> nuget.org).
    No code is sent anywhere.

Exit codes: 0 = check done (including no changes, nothing to check, STOP
present). 1 = config problem (repo_path missing, repo folder not found).
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
TODAY = date.today().isoformat()


# ---------------------------------------------------------------- config ----
def _scalar(text):
    text = text.strip()
    if text in ("true", "True"):
        return True
    if text in ("false", "False"):
        return False
    if re.fullmatch(r"-?\d+", text):
        return int(text)
    if (text.startswith('"') and text.endswith('"')) or (
        text.startswith("'") and text.endswith("'")
    ):
        return text[1:-1]
    return text


def load_config(path):
    """Minimal YAML reader for this scaffold's simple config shape only:
    top-level `key: value`, one level of nested `key:` dicts, and `- item`
    lists. Comments (# ...) and blank lines are ignored."""
    config = {}
    current_key = None
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0]
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip(" "))
        line = line.strip()
        if line.startswith("- ") and current_key is not None:
            config.setdefault(current_key, []).append(_scalar(line[2:]))
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if indent == 0:
            current_key = key
            if value == "":
                config[key] = {}
            else:
                config[key] = _scalar(value)
        else:
            parent = config.get(current_key)
            if isinstance(parent, dict):
                parent[key] = _scalar(value) if value != "" else {}
    return config


# -------------------------------------------------------------- versions ----
def _parts(version):
    """Leading numeric segments of a version string, e.g. '4.17.15' -> [4,17,15]."""
    version = str(version).split("-")[0].split("+")[0]
    out = []
    for piece in version.split("."):
        digits = re.match(r"\d+", piece)
        out.append(int(digits.group()) if digits else 0)
    while len(out) < 3:
        out.append(0)
    return out[:3]


def bump_type(current, latest):
    """major / minor / patch / unknown, from two version strings."""
    try:
        c, l = _parts(current), _parts(latest)
    except Exception:
        return "unknown"
    if l[0] != c[0]:
        return "major"
    if l[1] != c[1]:
        return "minor"
    if l[2] != c[2]:
        return "patch"
    return "unknown"


RISK_ORDER = {"security": 0, "major": 1, "minor": 2, "patch": 3, "unknown": 4}


# ------------------------------------------------------------ ecosystems ----
def run(cmd, cwd, timeout=180):
    """Run a command, return (exit_code, stdout, stderr). Never raises."""
    try:
        proc = subprocess.run(
            cmd, cwd=str(cwd), capture_output=True, text=True, timeout=timeout
        )
        return proc.returncode, proc.stdout, proc.stderr
    except FileNotFoundError:
        return None, "", "command not found"
    except subprocess.TimeoutExpired:
        return None, "", "timed out"


def check_npm(repo, security_scan=True):
    """npm outdated --json. npm exits 1 when outdated packages exist, so
    exit 0 or 1 with parseable JSON both count as a result."""
    if shutil.which("npm") is None:
        return [], "npm is not installed, npm check skipped."
    code, out, _ = run(["npm", "outdated", "--json"], repo)
    findings = []
    if code in (0, 1) and out.strip():
        try:
            data = json.loads(out)
        except json.JSONDecodeError:
            return [], "npm outdated returned output I could not read, npm check skipped."
        for name, info in data.items():
            current = str(info.get("current", ""))
            latest = str(info.get("latest", ""))
            if not current or current == "MISSING" or not latest:
                continue
            if current == latest:
                continue
            findings.append(
                {
                    "ecosystem": "npm",
                    "name": name,
                    "current": current,
                    "latest": latest,
                    "bump": bump_type(current, latest),
                    "risk": bump_type(current, latest),
                    "note": "",
                }
            )
    advisories = {}
    if findings and security_scan:
        # Best-effort: npm audit flags packages with known advisories.
        # Needs node_modules; fails quietly when it cannot run.
        _, audit_out, _ = run(["npm", "audit", "--json"], repo, timeout=120)
        try:
            audit = json.loads(audit_out) if audit_out.strip() else {}
            vulns = audit.get("vulnerabilities", {}) or {}
            for name, info in vulns.items():
                advisories[name] = str(info.get("severity", ""))
        except (json.JSONDecodeError, AttributeError):
            pass
        for item in findings:
            sev = advisories.get(item["name"])
            if sev:
                item["risk"] = "security"
                item["note"] = f"npm audit advisory, severity {sev}"
    return findings, ""


def check_pip(repo, pip_executable):
    """pip list --outdated --format=json, via system python or a venv pip."""
    if pip_executable:
        cmd = [pip_executable, "list", "--outdated", "--format=json"]
    else:
        cmd = [sys.executable, "-m", "pip", "list", "--outdated", "--format=json"]
    code, out, err = run(cmd, repo)
    if code is None:
        return [], f"pip could not run ({err}), pip check skipped."
    if code != 0:
        return [], "pip list --outdated failed, pip check skipped."
    findings = []
    try:
        data = json.loads(out) if out.strip() else []
    except json.JSONDecodeError:
        return [], "pip returned output I could not read, pip check skipped."
    for entry in data:
        current = str(entry.get("version", ""))
        latest = str(entry.get("latest_version", ""))
        if not current or not latest or current == latest:
            continue
        bump = bump_type(current, latest)
        findings.append(
            {
                "ecosystem": "pip",
                "name": str(entry.get("name", "")),
                "current": current,
                "latest": latest,
                "bump": bump,
                "risk": bump,
                "note": "",
            }
        )
    return findings, ""


def check_nuget(repo):
    """dotnet list package --outdated. Skipped plainly when dotnet is missing
    or the folder has no .NET project."""
    if shutil.which("dotnet") is None:
        return [], "dotnet is not installed, NuGet check skipped."
    if not list(Path(repo).rglob("*.csproj")) and not list(Path(repo).rglob("*.sln")):
        return [], "no .NET project found in this repo, NuGet check skipped."
    code, out, _ = run(
        ["dotnet", "list", "package", "--outdated", "--format", "json"], repo
    )
    if code != 0 or not out.strip():
        return [], "dotnet list package --outdated failed, NuGet check skipped."
    findings = []
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return [], "dotnet returned output I could not read, NuGet check skipped."
    for project in data.get("projects", []):
        for framework in project.get("frameworks", []):
            for pkg in framework.get("topLevelPackages", []):
                current = str(pkg.get("resolvedVersion", "") or pkg.get("requestedVersion", ""))
                latest = str(pkg.get("latestVersion", ""))
                if not current or not latest or current == latest:
                    continue
                bump = bump_type(current, latest)
                findings.append(
                    {
                        "ecosystem": "nuget",
                        "name": str(pkg.get("id", "")),
                        "current": current,
                        "latest": latest,
                        "bump": bump,
                        "risk": bump,
                        "note": "",
                    }
                )
    return findings, ""


CHECKERS = {"npm": check_npm, "pip": check_pip, "nuget": check_nuget}


# --------------------------------------------------------------- report -----
def render_report(template, ctx):
    text = Path(template).read_text(encoding="utf-8")
    for key, value in ctx.items():
        text = text.replace("{{" + key + "}}", value)
    return text


def top_section(findings, top_n):
    lines = []
    for eco in ("npm", "pip", "nuget"):
        items = [f for f in findings if f["ecosystem"] == eco]
        if not items:
            continue
        items.sort(key=lambda f: (RISK_ORDER[f["risk"]], f["name"]))
        lines.append(f"### {eco} — top {min(top_n, len(items))} of {len(items)}")
        for item in items[:top_n]:
            note = f" ({item['note']})" if item["note"] else ""
            lines.append(
                f"- **{item['name']}** {item['current']} -> {item['latest']} "
                f"— {item['bump']} bump, risk: {item['risk']}{note}"
            )
        lines.append("")
    return "\n".join(lines).strip() or "No outdated dependencies found."


def appendix_table(findings):
    if not findings:
        return "No outdated dependencies found."
    rows = ["| Ecosystem | Package | Current | Latest | Bump | Risk |",
            "|---|---|---|---|---|---|"]
    for item in sorted(findings, key=lambda f: (RISK_ORDER[f["risk"]], f["ecosystem"], f["name"])):
        rows.append(
            f"| {item['ecosystem']} | {item['name']} | {item['current']} | "
            f"{item['latest']} | {item['bump']} | {item['risk']} |"
        )
    return "\n".join(rows)


def signature(findings):
    return sorted(
        [
            {
                "ecosystem": f["ecosystem"],
                "name": f["name"],
                "current": f["current"],
                "latest": f["latest"],
            }
            for f in findings
        ],
        key=lambda d: (d["ecosystem"], d["name"]),
    )


# ----------------------------------------------------------------- main -----
def main():
    parser = argparse.ArgumentParser(description="Dependency Watch — read-only outdated check.")
    parser.add_argument("--config", default=str(HERE / "config.yaml"))
    parser.add_argument("--repo", default=None, help="Override repo_path from config.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print what would be checked, write nothing.")
    args = parser.parse_args()

    # Kill switch: a file named STOP in this folder stops the run silently.
    if (HERE / "STOP").exists():
        return 0

    try:
        config = load_config(args.config)
    except OSError as exc:
        print(f"Could not read config file {args.config}: {exc}")
        return 1

    # Check the raw string first: Path("") collapses to "." (the current
    # folder), which would silently watch the wrong repo.
    repo_raw = (args.repo or config.get("repo_path", "") or "").strip()
    if not repo_raw:
        print("repo_path is empty.")
        print("Set repo_path in config.yaml to the full path of the repo to watch.")
        return 1
    repo = Path(repo_raw).expanduser()
    if not repo.is_dir():
        print(f"repo_path does not point to a folder: {repo}")
        print("Set repo_path in config.yaml to the full path of the repo to watch.")
        return 1

    ecosystems = config.get("ecosystems", {}) or {}
    if isinstance(ecosystems, dict):
        enabled = [name for name, on in ecosystems.items() if on]
    else:
        enabled = []
    top_n = int(config.get("top_n", 3) or 3)
    report_path = str(config.get("report_path", "out/dependency-watch-YYYY-MM-DD.md") or
                      "out/dependency-watch-YYYY-MM-DD.md")
    report_path = report_path.replace("YYYY-MM-DD", TODAY)
    report_file = Path(report_path)
    if not report_file.is_absolute():
        report_file = HERE / report_file
    security_scan = bool(config.get("security_scan", True))

    if args.dry_run:
        print(f"Repo: {repo}")
        print(f"Ecosystems to check: {', '.join(enabled) if enabled else '(none enabled)'}")
        print(f"Report would go to: {report_file}")
        print("Dry run — nothing was checked, nothing was written.")
        return 0

    if not enabled:
        print("All ecosystems are disabled in config.yaml. Nothing to check.")
        report_file.parent.mkdir(parents=True, exist_ok=True)
        report_file.write_text(
            render_report(HERE / "templates" / "report.md", {
                "date": TODAY,
                "repo": str(repo),
                "top_section": "All ecosystems are disabled in config.yaml. Nothing to check.",
                "appendix": "Nothing checked.",
                "skipped": "- (none — nothing was enabled)",
                "baseline_note": "No baseline written — nothing was checked.",
            }),
            encoding="utf-8",
        )
        print(f"Report written to {report_file}")
        return 0

    findings = []
    skipped = []
    for eco in enabled:
        checker = CHECKERS.get(eco)
        if checker is None:
            skipped.append(f"{eco}: unknown ecosystem in config, skipped.")
            continue
        if eco == "pip":
            items, note = checker(repo, str(config.get("pip_executable", "") or ""))
        elif eco == "npm":
            items, note = checker(repo, security_scan)
        else:
            items, note = checker(repo)
        findings.extend(items)
        if note:
            skipped.append(note)

    findings.sort(key=lambda f: (RISK_ORDER[f["risk"]], f["ecosystem"], f["name"]))
    sig = signature(findings)
    baseline_file = HERE / "out" / "baseline.json"
    baseline_note = ""
    changed = True
    if baseline_file.exists():
        try:
            old = json.loads(baseline_file.read_text(encoding="utf-8"))
            if old.get("signature") == sig:
                changed = False
        except (json.JSONDecodeError, AttributeError):
            pass

    report_file.parent.mkdir(parents=True, exist_ok=True)
    if not changed:
        print("No changes since last run.")
        report_file.write_text(
            render_report(HERE / "templates" / "report.md", {
                "date": TODAY,
                "repo": str(repo),
                "top_section": "No changes since last run. Nothing new is outdated.",
                "appendix": appendix_table(findings),
                "skipped": "\n".join(f"- {s}" for s in skipped) or "- (none)",
                "baseline_note": f"Baseline unchanged (last written {baseline_file}).",
            }),
            encoding="utf-8",
        )
        print(f"Report written to {report_file}")
        return 0

    baseline_file.parent.mkdir(parents=True, exist_ok=True)
    baseline_file.write_text(
        json.dumps({"date": TODAY, "signature": sig}, indent=2), encoding="utf-8"
    )
    baseline_note = "Baseline updated — next run will only report if this changes."
    report_file.write_text(
        render_report(HERE / "templates" / "report.md", {
            "date": TODAY,
            "repo": str(repo),
            "top_section": top_section(findings, top_n),
            "appendix": appendix_table(findings),
            "skipped": "\n".join(f"- {s}" for s in skipped) or "- (none)",
            "baseline_note": baseline_note,
        }),
        encoding="utf-8",
    )
    print(f"Checked {len(findings)} outdated package(s) across: {', '.join(enabled)}.")
    print(f"Report written to {report_file}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
