# Flagged Application Board Handoff

## Spot the flagged-board signature

- Watch for the behavioral signature: captcha or verification challenges solve successfully, but the board backend rejects or invalidates every submit, sometimes with a generic verification error.

- Treat two backend invalidations after successful solves as the flag. One fresh-session retry is only worth trying for transient failures like an expired email code or a session timeout.

- Stop solving captchas once the signature is clear. More solves never change what a flagged backend does.

## Stop, save, and hand off

- Stop the session after the second backend invalidation and disclose the wall in the same turn. Name the board and the job, say the backend invalidated the submits, and give the user two paths: take over the browser session to submit, or submit from their own device.

- Save a cheat sheet of everything used so far: board name, job id, every form answer, the attached resume version, and the login state. Put it as a file in the workspace files area and give the user the exact path.

- Record the outcome in memory with the board name and job id marked as flagged for the automation browser, so the next session starts from the cheat sheet instead of re-attempting the same route.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Try one fresh browser session before declaring the board flagged when the failure looks transient, like an expired verification code on the first attempt. Transient failures clear, flagged backends do not.

- Prefer the board saved application draft or the user logged-in device when a cheat sheet exists, since both skip the automation browser entirely.