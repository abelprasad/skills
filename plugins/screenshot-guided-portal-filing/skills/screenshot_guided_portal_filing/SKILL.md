# Screenshot Guided Portal Filing

## Choose screenshots over driving the portal

- Use screenshot guidance when a portal blocks the automation browser, when the filing needs the user's own login, or when a wrong submit would be hard to undo.

- Ask the user to open the portal on their own device and to share a screenshot of the current screen before you give any field advice.

- Work from the screenshot the user shared, not from a page you fetched, and ask for a fresh screenshot whenever the screen changes.

- Avoid asking the user to paste a sensitive identifier in chat, such as a tax identifier or a government number, and have them keep any confirmation letter as a saved file instead.

- Stop and hand the user a clear next step when a screen will not load or a field cannot be read, instead of guessing the field from memory.

## Transcribe and check each screen

- Transcribe every field on the current screen in your own words before you advise the user what to enter or confirm.

- Read back the entity name, address, dates, and category exactly as shown, and ask the user to confirm any value you cannot read clearly.

- Compare each value against the values the user already confirmed for the filing, and flag any mismatch before the user moves to the next screen.

- Check that a date field holds the filing date when it asks for a filing date, and that a personal date has not been entered in its place.

- Check that an address is complete, including any digit that a portal screen may have dropped, and that an optional address field is left blank when blank protects privacy.

- Confirm the category or activity mapping matches the real activity, rather than accepting the portal default or the first close match.

## Confirm before submit

- Ask the user to share the review screen before they submit, and read the full review back field by field.

- Name any field that is still blank, wrong, or inconsistent, and wait for the user to correct it before you approve the submit.

- Tell the user what the submit will create or file, and what confirmation to expect, before they press submit.

- After submit, ask the user to share the confirmation screen or letter, and record the confirmation type and where the saved file lives, without recording the identifier itself.

- If a filing returns to a pending or review status, tell the user what to download or check next, and what deadline applies to that download.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Use a portal saved draft or a filing service when the portal offers one and the user prefers not to click through each screen.

- Split a long filing into one screen per turn when the screens are long, so each screen gets a full read back before the next one starts.

- When a portal offers a different filing route that does not need a sensitive identifier in chat, prefer that route and keep the identifier in the saved confirmation file only.
