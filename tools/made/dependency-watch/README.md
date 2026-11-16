# Dependency Watch

One job: once a week, check which dependencies in your repo are out of
date, tell you the riskiest 3 per ecosystem, and stay quiet the weeks
nothing changed. It never updates anything. You decide what to update,
by hand, after reading the report.

## Quick start (5 minutes)

1. Copy this whole folder to your machine.
2. Open `config.yaml` and set `repo_path` to the full path of the repo
   you want watched. That is the only required setting.
3. Run it once by hand to prove it works:
   - Windows: double-click `run-watch.bat`
   - macOS/Linux: `bash run-watch.sh`
4. Read the report in `out/dependency-watch-YYYY-MM-DD.md`.
5. If the report looks right, turn on the schedule (below). If not,
   fix `config.yaml` and run it again.

## What it watches

| Ecosystem | How it checks | Needs |
|---|---|---|
| npm | `npm outdated --json` + `npm audit --json` (best-effort) | Node.js + npm, `package.json` in the repo |
| pip | `pip list --outdated --format=json` | Python + pip; set `pip_executable` in config to point at a venv pip |
| NuGet | `dotnet list package --outdated` | .NET SDK + a `.csproj` or `.sln` in the repo |

Any ecosystem that cannot run is skipped with a plain-English line in
the report, not an error. Turn one off with `false` in `config.yaml`.

One gotcha, proved on indra: `pip` checks whatever Python you point
it at. If the repo has no Python code, the system pip reports the
machine's own packages (84 system packages on indra, vs 21 real npm
deps for the repo) — mostly noise. For a JS-only repo, set `pip: false`
or point `pip_executable` at the repo's own venv.

## How it stays on (the schedule)

It does **not** run 24/7. It wakes on a schedule, checks, reports only
if something changed, and sleeps again. The scheduler is the alarm
clock; the check itself is the brain.

**Windows (your Dell) — Task Scheduler, Monday 08:00:**

```
register-watch.bat
```

That creates a task named `DependencyWatch` that runs `run-watch.bat`
every Monday at 08:00. Check what it would do first with:

```
register-watch.bat --dry-run
```

To run the check through Claude Code instead (non-interactive print
mode, so the CLI reads the report and explains it in plain English):

```
register-watch.bat --use-claude
```

**Kill switch — stop the schedule any time:**

```
unregister-watch.bat
```

Your old reports in `out/` are kept; only the schedule is removed.
There is also a `STOP` file kill switch: create an empty file named
`STOP` in this folder and any run exits quietly without checking.
Delete the file to resume.

**Linux / macOS — cron, Monday 08:00:**

```
0 8 * * 1 cd /home/abel/dependency-watch-scaffold && /usr/bin/python3 dependency-watch.py --config config.yaml
```

Claude Code equivalent (needs the `claude` CLI on PATH):

```
0 8 * * 1 cd /home/abel/dependency-watch-scaffold && claude -p "run dependency watch from config.yaml and report only what changed since the baseline"
```

## Reading a report

- **Top outdated (by risk)** — the top 3 per ecosystem, riskiest first.
  Risk order: Security (a known advisory from `npm audit`) > Major
  version bump > Minor bump > Patch bump.
- **All findings** — the full table, every outdated package.
- **Skipped** — ecosystems that could not run, and why, in plain English.
- **Baseline** — the first run saves `out/baseline.json`. Later runs
  compare against it. If nothing changed, the report says so and the
  run stays quiet. That is the normal week.

## Privacy

- Your code and lockfiles never leave your machine. The script itself
  makes **no network calls at all**.
- The only network traffic is the package managers asking their public
  registries which versions exist: npm asks registry.npmjs.org, pip
  asks pypi.org, dotnet asks nuget.org. They send package names, not
  your code.
- `config.yaml` holds only paths and toggles. No tokens, no passwords,
  no org names. If a check ever needs credentials, that is a different
  tool — this one stays read-only and public-registry-only.

## Troubleshooting

- "repo_path is empty" — open `config.yaml` and set `repo_path`.
- "dotnet is not installed, NuGet check skipped" — install the .NET
  SDK, or set `nuget: false` in config if you do not watch .NET code.
- "npm is not installed" — install Node.js, or set `npm: false`.
- Report says "All ecosystems are disabled" — at least one of
  `npm` / `pip` / `nuget` must be `true` in config.
- The scheduled task never runs — run `register-watch.bat` as
  Administrator once; Task Scheduler needs that to create tasks.
- Nothing changed for weeks — that is the point. The baseline only
  moves when a version actually moves.
