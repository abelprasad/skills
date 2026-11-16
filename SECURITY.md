# Security

## Privacy rule: recipe vs food in the fridge

Anything that is a secret, a credential, live operational state, or money data stays private and out of git. Code, docs, and config templates can be public. This repo ships the code that builds the state, never the state itself.

Never committed, by design (see `.gitignore`):

- `.auth/`, `queue/`, `clips/`, `vod/`, `recordings/`, `logs/`, `out/`
- `earnings.json`, `campaigns.json`, `submit-outbox/`
- `*.env`, credentials, tokens, cookies, private keys
- `STOP` files and runtime baselines (`out/baseline.json`)

Example configs in this repo use placeholders only. Real IDs, paths, and tokens are scrubbed even when they appear as dict keys, not just values. Verify with a secret scan before every commit.

## What these tools may and may not do

- **note-taker**: records audio on the machine it runs on, transcribes locally, deletes the recording. It makes no network calls except to `http://127.0.0.1:11434` (local Ollama). It never uploads audio or notes anywhere.
- **standup-notes**: makes zero network calls. The Azure DevOps step happens inside a Claude Code session where the MCP server is already connected; the script only reads the JSON file that step writes.
- **dependency-watch**: read-only. It runs `npm outdated`, `pip list --outdated`, `dotnet list package --outdated`, and `npm audit` — those ask public registries for version lists. It never installs, updates, or modifies a lockfile.
- **qa-agent**: drives a browser against the site URL you give it, takes screenshots, writes a local HTML report. It never sends the report anywhere.
- **Setup packs**: install software on the machine you run them on. They never send data anywhere. The CodeGraph/RTK pack clones only the repo URLs you type in.
- **Skills**: text and instructions only. No skill in this repo exfiltrates data, and no skill asks for a password, token, or secret.

## Reporting a problem

Open an issue. Don't include secrets, tokens, or company data in it.
