#!/usr/bin/env python3
"""Standup notes generator.

Reads your local git log since yesterday morning and drafts a
Yesterday / Today / Blockers note in plain English. Optionally
merges in your Azure DevOps work items from a JSON file.

Local only. Stdlib only. The script itself makes no network
calls: it only runs git on your own machine, reads one local
JSON file if you point it at one, and writes a markdown file.
It never talks to Azure DevOps directly. Your Azure DevOps MCP
server is already set up where you work — the script uses what
that server already gave you, via the JSON file. See README.md
for the one-line step that makes the file.

Usage:
    python standup.py
    python standup.py --repo C:\\code\\my-repo --out standup-2026-11-16.md
    python standup.py --config config.yaml
    python standup.py --ado-items standup-items.json
"""

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

HERE = Path(__file__).resolve().parent
MAX_YESTERDAY_BULLETS = 5
MAX_STATUS_FILES = 5


def read_config(path):
    """Read a tiny key: value config file. No YAML library needed.

    Supports one level of nesting: indented keys under a
    `section:` header become `section.key`. Example:

        azure_devops:
          enabled: false
          items_file: "standup-items.json"
    """
    config = {
        "repo_path": "",
        "since": "",
        "ticket_pattern": "",
        "author": "",
        "azure_devops.enabled": "false",
        "azure_devops.items_file": "standup-items.json",
    }
    if not path.exists():
        return config
    section = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if raw[0].isspace():
            # Indented: belongs to the current section.
            if not section or ":" not in stripped:
                continue
            key, value = stripped.split(":", 1)
            key = section + "." + key.strip()
        else:
            # Top level: a section header, or a flat key.
            if stripped.endswith(":") and ":" not in stripped[:-1]:
                section = stripped[:-1]
                continue
            section = ""
            if ":" not in stripped:
                continue
            key, value = stripped.split(":", 1)
            key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key in config:
            config[key] = value
    return config


def default_since():
    """Yesterday at 09:00 local time, in git's date format."""
    yesterday = datetime.now() - timedelta(days=1)
    return yesterday.strftime("%Y-%m-%d 09:00")


def run_git(repo, args):
    result = subprocess.run(
        ["git", "-C", str(repo)] + args,
        capture_output=True,
        text=True,
        timeout=30,
    )
    return result


def get_commits(repo, since, author, ticket_re):
    """Return a list of {ticket, words, merged} for commits since `since`."""
    fmt = "%H%x1f%s%x1f%an%x1e"
    cmd = ["log", "--since=" + since, "--pretty=format:" + fmt]
    if author:
        cmd.append("--author=" + author)
    result = run_git(repo, cmd)
    if result.returncode != 0:
        if "does not have any commits yet" in result.stderr:
            return []
        raise RuntimeError(result.stderr.strip() or "git log failed")
    commits = []
    for record in result.stdout.split("\x1e"):
        record = record.strip()
        if not record:
            continue
        parts = record.split("\x1f")
        if len(parts) < 3:
            continue
        _sha, subject, _who = parts[0], parts[1], parts[2]
        merged = subject.lower().startswith("merge ")
        ticket = ""
        match = ticket_re.search(subject) if ticket_re else None
        if match:
            ticket = match.group(1)
            words = ticket_re.sub("", subject, count=1).strip(" -:[]()")
        else:
            words = subject.strip()
        if merged:
            words = re.sub(r"^merge\s+", "", words, flags=re.IGNORECASE)
            if words.lower().startswith("pull request"):
                words = "Merged: " + words
        commits.append({"ticket": ticket, "words": words, "merged": merged})
    return commits


def get_status(repo):
    """Return {branch, changed_files} from git status. Never invents work."""
    branch = ""
    result = run_git(repo, ["branch", "--show-current"])
    if result.returncode == 0:
        branch = result.stdout.strip()
    changed = []
    result = run_git(repo, ["status", "--porcelain"])
    if result.returncode == 0:
        for line in result.stdout.splitlines():
            if not line.strip():
                continue
            # Porcelain format: XY + space + path. Split on whitespace once.
            parts = line.strip().split(None, 1)
            changed.append(parts[1] if len(parts) > 1 else parts[0])
    return {"branch": branch, "changed": changed}


# --- Azure DevOps (optional) -------------------------------------------
# The server is already set up where you work — this script does
# not install it, configure it, or sign in to it. It only reads a
# JSON file that the server's tools already produced, merges those
# work items into the draft, and moves on. If the file is missing
# or unreadable, the step is skipped with a plain-English line
# and the draft is git only.
#
# How the file is made: in a session where your Azure DevOps MCP
# tools are connected, ask for your assigned work items updated
# since yesterday and save them as JSON. The tools are the
# official ones (wit_work_item action "my" for your items, then
# action "get_batch" for their titles and states). See README.md
# for the exact one-line prompt and the file shape.

MCP_DONE_STATES = {"done", "closed", "resolved"}
MCP_BLOCKED_WORDS = ("blocked", "blocker")


def _parse_changed_date(value):
    """Parse an Azure DevOps date like 2026-11-15T14:30:00Z. None if unreadable."""
    if not value or not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _parse_since(since_str):
    """Parse a since string like 2026-11-15 09:00. None if it is not a date."""
    try:
        return datetime.strptime(since_str, "%Y-%m-%d %H:%M")
    except (ValueError, TypeError):
        return None


def _work_item_from_entry(entry):
    """One work item dict from a flat entry or an MCP fields entry."""
    fields = entry.get("fields")
    if isinstance(fields, dict):
        return {
            "id": entry.get("id"),
            "type": fields.get("System.WorkItemType", "Work item"),
            "title": fields.get("System.Title", "(no title)"),
            "state": fields.get("System.State", ""),
            "changed": _parse_changed_date(fields.get("System.ChangedDate")),
            "tags": fields.get("System.Tags", "") or "",
        }
    return {
        "id": entry.get("id"),
        "type": entry.get("type", "Work item"),
        "title": entry.get("title", "(no title)"),
        "state": entry.get("state", ""),
        "changed": _parse_changed_date(entry.get("changed") or entry.get("changedDate")),
        "tags": entry.get("tags", "") or "",
    }


def load_ado_items(path, since_dt):
    """Read work items from a JSON file made by the Azure DevOps MCP tools.

    The file is a list of items, each either flat:
        {"id": 12345, "type": "User Story", "title": "...",
         "state": "Done", "changed": "2026-11-15T14:30:00Z", "tags": ""}
    or in the MCP tool's own shape:
        {"id": 12345, "fields": {"System.Title": "...",
         "System.State": "Done", "System.ChangedDate": "...", ...}}

    Items older than `since_dt` are left out (nothing touched
    since yesterday does not belong in today's standup). Items
    with no date are kept rather than dropped on a missing field.

    Returns (items, skip_reason). skip_reason is None when the file
    loaded (even if it held no items); otherwise it is a
    plain-English reason the step was skipped. Never raises.
    """
    if not path.exists():
        return [], (
            "no Azure DevOps items file was found at %s. "
            "Make it first with the one-line step in README.md, "
            "or turn the step off in config.yaml." % path
        )
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except ValueError:
        return [], "the Azure DevOps items file %s is not valid JSON." % path
    except OSError as exc:
        return [], "the Azure DevOps items file could not be read: %s" % exc
    if isinstance(data, dict):
        data = data.get("value", data)
    if not isinstance(data, list):
        return [], "the Azure DevOps items file does not hold a list of work items."
    items = []
    for entry in data:
        if not isinstance(entry, dict):
            continue
        item = _work_item_from_entry(entry)
        if item["id"] is None:
            continue
        if since_dt is not None and item["changed"] is not None:
            if item["changed"].replace(tzinfo=None) < since_dt:
                continue
        items.append(item)
    return items, None


def split_mcp_items(items):
    """Sort work items into done / active / blocked buckets."""
    done, active, blocked = [], [], []
    for item in items:
        state = (item["state"] or "").strip().lower()
        tags = (item["tags"] or "").lower()
        if "block" in state or any(word in tags for word in MCP_BLOCKED_WORDS):
            blocked.append(item)
        elif state in MCP_DONE_STATES:
            done.append(item)
        else:
            active.append(item)
    return done, active, blocked


def format_mcp_item(item):
    return "- [#%s] %s (Azure DevOps, %s)" % (
        item["id"], item["title"], item["state"] or "no state",
    )


def render_yesterday(commits, mcp_done=None):
    mcp_done = mcp_done or []
    lines = []
    for commit in commits[:MAX_YESTERDAY_BULLETS]:
        if commit["ticket"]:
            lines.append("- [%s] %s" % (commit["ticket"], commit["words"]))
        else:
            lines.append("- %s" % commit["words"])
    extra = len(commits) - MAX_YESTERDAY_BULLETS
    if extra > 0:
        lines.append("- ...and %d more commit(s) — see git log for the rest." % extra)
    for item in mcp_done[:MAX_YESTERDAY_BULLETS]:
        lines.append(format_mcp_item(item))
    extra = len(mcp_done) - MAX_YESTERDAY_BULLETS
    if extra > 0:
        lines.append("- ...and %d more done work item(s) in Azure DevOps." % extra)
    if not lines:
        return "No commits found since yesterday morning. Nothing shipped in git."
    return "\n".join(lines)


def render_today(status, mcp_active=None):
    mcp_active = mcp_active or []
    branch = status["branch"] or "(no branch checked out)"
    changed = status["changed"]
    lines = ["- Working on branch: %s" % branch]
    if changed:
        lines.append("- %d file(s) changed, not committed yet:" % len(changed))
        for name in changed[:MAX_STATUS_FILES]:
            lines.append("  - %s" % name)
        if len(changed) > MAX_STATUS_FILES:
            lines.append("  - ...and %d more file(s)." % (len(changed) - MAX_STATUS_FILES))
        closing = "- Add today's plan below — this is only what git can see."
    else:
        lines.append("- Nothing in progress in git — working tree is clean.")
        closing = "- Add today's plan below."
    for item in mcp_active[:MAX_YESTERDAY_BULLETS]:
        lines.append(format_mcp_item(item))
    extra = len(mcp_active) - MAX_YESTERDAY_BULLETS
    if extra > 0:
        lines.append("- ...and %d more active work item(s) in Azure DevOps." % extra)
    lines.append(closing)
    return "\n".join(lines)


def render_blockers(mcp_blocked=None):
    mcp_blocked = mcp_blocked or []
    if not mcp_blocked:
        return "- (none — add yours here)"
    lines = [format_mcp_item(item) for item in mcp_blocked[:MAX_YESTERDAY_BULLETS]]
    lines.append("- (add yours here)")
    return "\n".join(lines)


def render_footer(mcp_used):
    if mcp_used:
        return "Drafted from your git log and Azure DevOps. Needs your 2 min edit: check Yesterday, add Today, add any Blockers."
    return "Drafted from your git log. Needs your 2 min edit: check Yesterday, add Today, add any Blockers."


def render_note(template, date_str, yesterday, today, blockers=None, footer=None):
    text = template
    text = text.replace("{{date}}", date_str)
    text = text.replace("{{yesterday}}", yesterday)
    text = text.replace("{{today}}", today)
    if blockers is not None:
        text = text.replace("{{blockers}}", blockers)
    if footer is not None:
        text = text.replace("{{footer}}", footer)
    return text


def main(argv=None):
    parser = argparse.ArgumentParser(description="Draft standup notes from git log.")
    parser.add_argument("--config", default=str(HERE / "config.yaml"))
    parser.add_argument("--repo", default="")
    parser.add_argument("--out", default="")
    parser.add_argument("--since", default="")
    parser.add_argument("--ado-items", default="",
                        help="JSON file of Azure DevOps work items (see README.md).")
    args = parser.parse_args(argv)

    config = read_config(Path(args.config))
    repo = Path(args.repo or config["repo_path"] or ".").expanduser().resolve()
    since = args.since or config["since"] or default_since()
    pattern = config["ticket_pattern"] or r"\b([A-Z]+-\d+)\b"
    try:
        ticket_re = re.compile(pattern)
    except re.error:
        print("The ticket pattern in config.yaml is not valid. Fix it and run again.")
        return 1

    if not (repo / ".git").exists():
        print("This folder is not a git repo: %s" % repo)
        print("Set repo_path in config.yaml to a folder that has a .git folder.")
        return 1

    check = run_git(repo, ["rev-parse", "--git-dir"])
    if check.returncode != 0:
        print("Git could not read this repo: %s" % repo)
        return 1

    try:
        commits = get_commits(repo, since, config["author"], ticket_re)
    except RuntimeError as exc:
        print("Could not read the git log. %s" % exc)
        return 1
    status = get_status(repo)

    ado_enabled = (
        config["azure_devops.enabled"].strip().lower() == "true"
        or bool(args.ado_items)
    )
    mcp_items, mcp_skip = [], None
    if ado_enabled:
        items_name = args.ado_items or config["azure_devops.items_file"] or "standup-items.json"
        items_path = Path(items_name).expanduser()
        if not items_path.is_absolute():
            items_path = HERE / items_path
        since_dt = _parse_since(since) or _parse_since(default_since())
        mcp_items, mcp_skip = load_ado_items(items_path, since_dt)
    mcp_done, mcp_active, mcp_blocked = split_mcp_items(mcp_items)
    mcp_used = bool(mcp_done or mcp_active or mcp_blocked)

    template_path = HERE / "templates" / "standup.md"
    template = template_path.read_text(encoding="utf-8") if template_path.exists() else (
        "# Standup — {{date}}\n\n## Yesterday\n{{yesterday}}\n\n"
        "## Today\n{{today}}\n\n## Blockers\n{{blockers}}\n\n"
        "---\n*{{footer}}*\n"
    )
    today_str = datetime.now().strftime("%A, %B %d, %Y")
    note = render_note(
        template,
        today_str,
        render_yesterday(commits, mcp_done),
        render_today(status, mcp_active),
        render_blockers(mcp_blocked),
        render_footer(mcp_used),
    )

    out_path = Path(args.out) if args.out else (
        HERE / "out" / ("standup-%s.md" % datetime.now().strftime("%Y-%m-%d"))
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(note, encoding="utf-8")

    print(note)
    print("---")
    if mcp_skip:
        print("Azure DevOps was skipped: %s" % mcp_skip)
    elif ado_enabled and not mcp_items:
        print("Azure DevOps: the items file held no work items updated since yesterday.")
    elif ado_enabled:
        print("Azure DevOps: %d work item(s) added (%d done, %d active, %d blocked)."
              % (len(mcp_items), len(mcp_done), len(mcp_active), len(mcp_blocked)))
    print("Saved to: %s" % out_path)
    print("Needs your 2 min edit: check Yesterday, add Today, add any Blockers.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
