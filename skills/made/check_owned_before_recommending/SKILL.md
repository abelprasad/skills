# Check Owned Items Before Recommending

## Check the shelf first

- Before recommending a product, read `~/memory/shopping/PROFILE.md` and `~/USER.md` for owned items, sizes, fits, and exclusions in that category.

- Look for a collection file for the category under `~/workspace/user/` and read it when one exists, since a category collection can live outside the shopping profile.

- Compare each candidate against owned items for a duplicate or a near duplicate in function, form, or profile, and compare it against any exclusion list for that category.

- Treat a listed exclusion as blocking unless the user explicitly waives it in the current conversation, and only then proceed with the waived item.

- When no owned record exists for the category and the candidate comes from a creator list or a shared post, ask the user what they already own before picking, rather than picking blind from the creator list.

- When the user says to proceed without that check, say plainly that the pick is unchecked against owned items, and keep the pick to a single best fit.

## Present a checked pick

- Lead with the gap the pick fills, such as a missing occasion, a nearly empty item, or a function the shelf lacks.

- Drop a duplicate or a near duplicate from the recommendation, or explain the tradeoff when the user still wants it despite the overlap.

- Never present an excluded item as a fresh recommendation, and offer the next best gap filler instead when an exclusion blocks the first candidate.

- State the owned fact that shaped the pick in plain words, such as a size or a fit, without naming the memory system behind it.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Ask the user to share a photo or a list of the shelf when no collection file exists, so the next recommendation in that category starts checked.

- Offer a replacement for a nearly empty owned item before offering a new category entry, since replacement closes a known gap first.

- When the user waives an exclusion, record the waiver as applying only to that item in that conversation, and keep the exclusion in place for later picks.
