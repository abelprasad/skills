# Standup notes — one command, 2 min edit

Drafts your daily standup from yesterday's git log. Local only.
Nothing is sent anywhere. No account, no cloud, no company data leaves your laptop.

## Run it

**Windows:** double-click `standup.bat`, or in a terminal:

```
standup.bat
```

**Mac / Linux:**

```
bash standup.sh
```

The draft prints on screen and is saved to `out/standup-YYYY-MM-DD.md`.

## What it does

1. Reads `git log` in your repo since yesterday 09:00 (changeable in `config.yaml`).
2. Groups commits by ticket ID from the message (for example `ABC-123`).
3. Optionally merges in your Azure DevOps work items from a JSON file (see below — the server is already set up where you work, this just uses what it already gave you).
4. Writes three sections in plain English:
   - **Yesterday** — what shipped, max 5 bullets, ticket plus plain words. No commit hashes in the output. Done work items from Azure DevOps land here too.
   - **Today** — only what git can see: your current branch and uncommitted files. It never invents planned work. You add the plan. Active work items from Azure DevOps land here too.
   - **Blockers** — empty by default. Add yours. Work items tagged blocked land here too.
5. Ends with a "needs your 2 min edit" line. Read it, fix anything, paste it where your team does standup.

If there are no commits, it says so plainly instead of inventing work.

## Set it up once (2 min)

Open `config.yaml` in Notepad or any text editor and fill in:

| Field | What to put |
|---|---|
| `repo_path` | Full path to the repo you work in, for example `C:\code\my-repo`. Leave empty to use the folder you run it from. |
| `since` | How far back to look. Leave empty for yesterday 09:00. |
| `ticket_pattern` | Pattern that finds ticket IDs in commit messages. Leave empty for `ABC-123` style. |
| `author` | Your name or email to show only your commits. Leave empty for everyone's. |
| `azure_devops.enabled` | `true` to merge Azure DevOps work items in, `false` for git only. Default `false`. |
| `azure_devops.items_file` | JSON file of work items (see below). Default `standup-items.json`. |

That is the only setup. No passwords, no tokens, no accounts.

## Azure DevOps (optional) — already installed, just use it

Your Azure DevOps MCP server is already set up where you work. This script does **not** install it, configure it, or sign in to it. It only reads a JSON file that the server's tools already made.

**One-line step, in a session where your Azure DevOps MCP tools are connected** (for example Claude Code on your work laptop). Paste this prompt:

> Using the Azure DevOps MCP tools, list my work items assigned to me and updated since yesterday. For each one get its id, type, title, state, changed date, and tags (use wit_work_item action "my", then action "get_batch" for the details), and save them as a JSON list to standup-items.json in this folder.

Then run the standup as normal. The script merges the file in:

- **Yesterday** — items in Done, Closed, or Resolved, changed since yesterday.
- **Today** — everything else still open (Active, In Progress, New, and so on).
- **Blockers** — items whose state or tags say blocked.
- Items older than yesterday are left out. Items with no date are kept rather than dropped.

**The file shape** (one item per line, plain JSON list):

```json
[
  {"id": 12345, "type": "User Story", "title": "Fix login timeout", "state": "Done", "changed": "2026-11-15T14:30:00Z", "tags": ""},
  {"id": 12346, "type": "Task", "title": "Write the reset email copy", "state": "Active", "changed": "2026-11-16T08:00:00Z", "tags": "blocked"}
]
```

The script also accepts the tools' own shape (`{"id": 12345, "fields": {"System.Title": "...", "System.State": "Done", ...}}`), so you can save the raw tool output without reshaping it.

**If the file is missing or broken**, the script prints a plain-English line saying Azure DevOps was skipped and why, and the draft is git only. It never invents a work item: only items in the file appear, and only with the title and state the file gives them.

**Merge rules.** Git and Azure DevOps are separate sources and the same work can show up in both — a commit that shipped and the work item it closed. The draft marks Azure DevOps lines with `(Azure DevOps, <state>)` so you can spot the double and delete one line in your 2 min edit. The script does not guess which one to drop.

**Privacy.** The script never talks to Azure DevOps itself and makes zero network calls. The only thing that ever touched Azure DevOps is the MCP server you already use, under your own sign-in. The JSON file stays on your laptop, next to the draft.

## Privacy

- The script only runs `git log` and `git status` on your machine, and reads one local JSON file if you turn the Azure DevOps step on.
- It makes **zero network calls**. You can check: search `standup.py` for `http`, `socket`, `urllib`, `requests` — none of them are there.
- It never installs, configures, or signs in to any Azure DevOps MCP server. That server is already set up where you work; the script only reads the file its tools already made.
- Your repo path, ticket numbers, work items, and drafts stay on your laptop.
- It never asks for, stores, or sends repo names, org names, project names, credentials, or company data.

## Files

- `standup.py` — the generator. Python standard library only, plus the `git` command. No installs beyond Python 3.10+.
- `standup.bat` / `standup.sh` — the one command.
- `config.yaml` — your settings (placeholders only until you fill them in).
- `templates/standup.md` — the note layout. Edit the words to match how your team talks.
- `example-standup.md` — a sample draft made from a fake repo plus fake Azure DevOps items, so you can see the merged shape before running it on real work.
- `standup-items.json` — the Azure DevOps items file, made by the one-line step above. Not shipped in this folder; you make it on your laptop. Delete it or leave it — the script only reads it when the step is on.
- `out/` — where each day's draft is saved (created on first run).

## If it goes wrong

- "This folder is not a git repo" — set `repo_path` in `config.yaml` to a folder with a `.git` folder in it.
- "Could not read the git log" — open the repo in a terminal and run `git log` once to see the real error.
- "No commits found" — that is a normal answer when nothing landed since yesterday morning, not an error.
- "Azure DevOps was skipped: no Azure DevOps items file was found" — run the one-line step above first to make `standup-items.json`, or set `azure_devops.enabled` to `false` in `config.yaml` for git only.
- "Azure DevOps was skipped: the items file is not valid JSON" — open the file and check it is a JSON list (square brackets, one object per item). The one-line prompt in the Azure DevOps section makes it in the right shape.
- "Azure DevOps: the items file held no work items updated since yesterday" — the file loaded fine but nothing in it changed since yesterday. That is a normal answer, not an error.

## Example

See [example-standup.md](sandbox://workspace/standup-notes-scaffold/example-standup.md) — made from 3 fake commits, no real data.
