#!/usr/bin/env python3
"""qa_runner.py — run a YAML checklist against a site with Playwright and
write a standalone HTML report with a screenshot per step.

Usage:
    python qa_runner.py --checklist checklists/example-checklist.yaml
    python qa_runner.py --checklist my-checklist.yaml --site https://qa.example.com --out out
    python qa_runner.py --checklist my-checklist.yaml --timeout-ms 60000 --headed

Checklist format (YAML):
    name: "Demo site smoke test"
    site: "https://the-internet.herokuapp.com"
    steps:
      - id: homepage-loads
        name: "Homepage loads"
        action: goto
        url: "/"
      - id: heading-shows
        action: assert_text
        selector: "h1"
        text: "Welcome to the Internet"
      - id: open-ab-testing
        action: click
        selector: "text=A/B Testing"
      - id: fill-input
        action: fill
        selector: "input[type='text']"
        value: "42"            # or value_env: QA_DEMO_VALUE
      - id: input-holds-value
        action: assert_value
        selector: "input[type='text']"
        value: "42"
      - id: wait-a-bit
        action: wait
        ms: 1000

Supported actions: goto, click, fill, assert_text, assert_visible,
assert_value, wait. Every step is screenshotted (pass or fail) and recorded
in out/report.html. A failed step does not stop the run. Exit code is 0 only
when every step passes.
"""

import argparse
import html
import os
import shutil
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from string import Template

import yaml

DEFAULT_TIMEOUT_MS = 30000


def run_step(page, site, step, timeout_ms):
    """Execute one checklist step. Returns (ok, error_text)."""
    action = step.get("action")
    selector = step.get("selector", "")

    if action == "goto":
        url = step.get("url", "/")
        if "://" not in url:
            url = site.rstrip("/") + "/" + url.lstrip("/")
        page.goto(url, timeout=timeout_ms, wait_until="domcontentloaded")
    elif action == "click":
        page.click(selector, timeout=timeout_ms)
    elif action == "fill":
        if "value_env" in step:
            env_name = step["value_env"]
            value = os.environ.get(env_name)
            if value is None:
                raise RuntimeError(f"environment variable {env_name} is not set")
        else:
            value = step.get("value", "")
        page.fill(selector, str(value), timeout=timeout_ms)
    elif action == "assert_text":
        expected = step.get("text", "")
        actual = page.locator(selector).first.inner_text(timeout=timeout_ms)
        if expected not in actual:
            raise AssertionError(f"expected text {expected!r} not in {actual!r}")
    elif action == "assert_visible":
        page.locator(selector).first.wait_for(state="visible", timeout=timeout_ms)
    elif action == "assert_value":
        expected = str(step.get("value", ""))
        actual = page.locator(selector).first.input_value(timeout=timeout_ms)
        if actual != expected:
            raise AssertionError(f"expected value {expected!r}, got {actual!r}")
    elif action == "wait":
        page.wait_for_timeout(int(step.get("ms", 1000)))
    else:
        raise ValueError(f"unknown action {action!r}")
    return True, ""


# Plain-English names for actions, so the report reads without jargon.
ACTION_LABELS = {
    "goto": "Open page",
    "click": "Click",
    "fill": "Type into a box",
    "assert_text": "Check words on the page",
    "assert_visible": "Check it shows up",
    "assert_value": "Check the box value",
    "wait": "Wait",
}


def plain_error(error):
    """Turn a technical error into plain English with a next step.

    Returns (plain_message, technical_detail). The plain message is what a
    non-technical reader sees; the detail stays in the report in small print
    for anyone who needs it.
    """
    text = error or ""
    low = text.lower()
    if "err_tunnel_connection_failed" in low or "err_proxy" in low \
            or "err_internet_disconnected" in low or "err_name_not_resolved" in low:
        return ("Couldn't reach the website. Check your internet connection and "
                "that the website address is right, then run it again.", text)
    if "timeout" in low and ("locator" in low or "waiting for" in low):
        return ("The page took too long to respond (over 30 seconds). The site may "
                "be slow or down, or the thing this check looks for may have moved. "
                "Try running it again, and if it still fails, the checklist may "
                "need updating.", text)
    if "expected text" in low:
        return ("The page loaded, but the words this check looks for weren't there. "
                "The page may have changed — the checklist may need updating.", text)
    if "expected value" in low:
        return ("The box didn't hold the value this check expected. The page may "
                "have changed — the checklist may need updating.", text)
    if "environment variable" in low and "is not set" in low:
        return ("This step needs a password or secret value that isn't set on this "
                "computer. Set it before running, or ask whoever gave you the "
                "checklist what to put in.", text)
    if "unknown action" in low:
        return ("The checklist has a step type I don't know. Ask whoever wrote the "
                "checklist to fix that step.", text)
    if "executable doesn't exist" in low or "browser has not been found" in low:
        return ("No web browser is installed for the test runner. Run "
                "'playwright install chromium' once, or point the runner at a "
                "browser you already have with --executable-path.", text)
    if text:
        return ("Something went wrong on this step. The detail is below — show it "
                "to whoever looks after the checklist.", text)
    return ("", "")


def render_report(template_path, context):
    """Fill the HTML template. Step rows are pre-rendered HTML."""
    template = Template(Path(template_path).read_text(encoding="utf-8"))
    return template.safe_substitute(context)


def main():
    parser = argparse.ArgumentParser(description="Run a QA checklist and write an HTML report.")
    parser.add_argument("--checklist", required=True, help="Path to the checklist YAML file.")
    parser.add_argument("--site", help="Override the site URL from the checklist.")
    parser.add_argument("--out", default="out", help="Output directory for the report (default: out).")
    parser.add_argument("--template", default="templates/report.html",
                        help="HTML report template (default: templates/report.html).")
    parser.add_argument("--timeout-ms", type=int, default=DEFAULT_TIMEOUT_MS,
                        help="Per-step timeout in ms (default: 30000).")
    parser.add_argument("--headed", action="store_true", help="Run the browser headed (default: headless).")
    parser.add_argument("--executable-path",
                        default=os.environ.get("QA_CHROME_PATH", ""),
                        help="Path to a system Chromium/Chrome binary to use instead of "
                             "the Playwright-managed browser (also via QA_CHROME_PATH).")
    args = parser.parse_args()

    checklist_path = Path(args.checklist)
    if not checklist_path.is_file():
        print(f"I couldn't find the checklist file: {checklist_path}\n"
              "Check the file name and the folder it's in, then try again.",
              file=sys.stderr)
        return 2
    checklist = yaml.safe_load(checklist_path.read_text(encoding="utf-8")) or {}
    site = args.site or checklist.get("site", "")
    if not site:
        print("No website address was given.\n"
              "Add a line like this to your checklist:\n"
              "  site: https://your-qa-site.example.com\n"
              "or pass the address when you run the command:\n"
              "  run-qa https://your-qa-site.example.com checklists/my-checklist.yaml",
              file=sys.stderr)
        return 2
    steps = checklist.get("steps", [])
    run_name = checklist.get("name", checklist_path.stem)

    out_dir = Path(args.out)
    shot_dir = out_dir / "screenshots"
    # Start clean: remove the previous run's report and screenshots so a
    # shorter run never leaves stale files behind.
    if out_dir.exists():
        shutil.rmtree(out_dir)
    shot_dir.mkdir(parents=True, exist_ok=True)

    from playwright.sync_api import sync_playwright

    started = datetime.now(timezone.utc)
    results = []
    with sync_playwright() as pw:
        launch_kwargs = {"headless": not args.headed, "args": ["--no-sandbox"]}
        if args.executable_path:
            launch_kwargs["executable_path"] = args.executable_path
        # Honor the standard proxy env vars (corporate proxies). Credentials
        # stay in the environment, never in code or checklists. The username
        # and password are passed separately because Chrome ignores userinfo
        # embedded in a proxy URL, which makes proxy auth fail silently.
        from urllib.parse import urlparse

        proxy_server = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy") \
            or os.environ.get("HTTP_PROXY") or os.environ.get("http_proxy")
        if proxy_server:
            parsed = urlparse(proxy_server)
            server = f"{parsed.scheme}://{parsed.hostname}"
            if parsed.port:
                server += f":{parsed.port}"
            launch_kwargs["proxy"] = {
                "server": server,
                "username": parsed.username or "",
                "password": parsed.password or "",
                "bypass": os.environ.get("NO_PROXY") or os.environ.get("no_proxy") or "",
            }
        try:
            browser = pw.chromium.launch(**launch_kwargs)
        except Exception as exc:  # noqa: BLE001 — no browser means no run at all
            message, _detail = plain_error(str(exc))
            print(f"I couldn't start a web browser.\n{message}", file=sys.stderr)
            return 2
        context = browser.new_context(viewport={"width": 1280, "height": 800})
        page = context.new_page()
        for i, step in enumerate(steps, start=1):
            step_id = step.get("id", f"step-{i}")
            step_name = step.get("name", step_id)
            action = step.get("action", "?")
            shot_name = f"{i:02d}-{step_id}.png"
            shot_path = shot_dir / shot_name
            t0 = time.monotonic()
            try:
                run_step(page, site, step, args.timeout_ms)
                ok, error = True, ""
            except Exception as exc:  # noqa: BLE001 — record the real error, keep going
                ok, error = False, str(exc)
            try:
                page.screenshot(path=str(shot_path))
            except Exception as exc:  # noqa: BLE001 — a dead page must not kill the report
                error = (error + f" [screenshot failed: {exc}]").strip()
            duration_ms = int((time.monotonic() - t0) * 1000)
            plain, detail = plain_error(error) if error else ("", "")
            results.append({
                "n": i, "id": step_id, "name": step_name, "action": action,
                "ok": ok, "error": plain, "detail": detail, "ms": duration_ms,
                "shot": f"screenshots/{shot_name}",
            })
            status = "Passed" if ok else "Failed"
            print(f"[{i:02d}/{len(steps)}] {status} — {step_name} ({duration_ms}ms)"
                  + (f" — {plain}" if plain else ""))
        browser.close()
    finished = datetime.now(timezone.utc)

    passed = sum(1 for r in results if r["ok"])
    failed = len(results) - passed
    rows = []
    for r in results:
        status = "Passed" if r["ok"] else "Failed"
        cls = "pass" if r["ok"] else "fail"
        action_label = ACTION_LABELS.get(r["action"], r["action"])
        err = ""
        if r["error"]:
            err = f'<div class="err">{html.escape(r["error"])}</div>'
            if r.get("detail") and r["detail"] != r["error"]:
                err += f'<div class="detail">{html.escape(r["detail"])}</div>'
        rows.append(
            f'<tr class="{cls}">'
            f"<td>{r['n']}</td>"
            f"<td>{html.escape(r['name'])}</td>"
            f"<td>{html.escape(action_label)}</td>"
            f'<td class="status">{status}</td>'
            f"<td>{r['ms']} ms</td>"
            f'<td><a href="{r["shot"]}" target="_blank">'
            f'<img src="{r["shot"]}" alt="screenshot for check {r["n"]}"></a></td>'
            f"<td>{err}</td></tr>"
        )
    context_vars = {
        "run_name": html.escape(str(run_name)),
        "site": html.escape(site),
        "started": started.strftime("%Y-%m-%d %H:%M:%S UTC"),
        "finished": finished.strftime("%Y-%m-%d %H:%M:%S UTC"),
        "duration": f"{(finished - started).total_seconds():.1f}s",
        "total": len(results),
        "passed": passed,
        "failed": failed,
        "overall": "All checks passed" if failed == 0 else "Some checks failed",
        "overall_class": "pass" if failed == 0 else "fail",
        "summary_sentence": (f"{passed} of {len(results)} checks passed."
                             if failed == 0 else
                             f"{passed} of {len(results)} checks passed and "
                             f"{failed} failed. See the failed rows below."),
        "step_rows": "\n".join(rows),
    }
    report_path = out_dir / "report.html"
    report_path.write_text(render_report(args.template, context_vars), encoding="utf-8")

    print(f"\nDone! {passed} of {len(results)} checks passed, {failed} failed "
          f"in {(finished - started).total_seconds():.1f}s")
    print(f"Report: {report_path} — open it in your browser to see each check "
          "with its screenshot.")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
