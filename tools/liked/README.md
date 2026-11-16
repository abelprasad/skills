# Tools Abel likes

## CodeGraph

Pre-indexed code knowledge graph, auto-syncs on code changes, 100% local. Rust kernel. MIT.

- Repo: [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph)
- Install: `curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh`, then `codegraph install`, then `codegraph init` per project.
- Or run the interactive installer in this repo: `tools/made/codegraph-rtk-setup/`.
- Why Abel picked it: architect-level knowledge of a codebase without re-reading it every session. Benchmarks on the repo page: 88% fewer tool calls, 53% faster, 62% fewer tokens.

## RTK

CLI proxy that reduces LLM token consumption by 60-90% by compressing shell output before it reaches agent context. Apache-2.0.

- Repo: [rtk-ai/rtk](https://github.com/rtk-ai/rtk)
- Install: `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh`, then `rtk init -g`, then restart the agent.
- Or run the interactive installer in this repo: `tools/made/codegraph-rtk-setup/`.
- Why Abel picked it: architects love it — same answers, far less context burned on shell output.
