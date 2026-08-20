# Claude Code specifics

@AGENTS.md

[`AGENTS.md`](https://ehrlinger.github.io/hvtiPlotR/AGENTS.md), imported
above, is the operational contract and applies in full. It is written to
be tool neutral so that Codex and other agents read the same rules. Only
the Claude Code affordances live here.

## Before you touch code

`AGENTS.md` says to orient before editing, which matters more here than
in most of the family: 76 exports and 47 S3 methods is too much surface
to infer from a partial file read. In Claude Code the way to do that is
the codemap — it lives in the Obsidian vault under `Claude/repomaps/`
and is read via the `read-codemap` skill (`/codemap hvtiPlotR`). If the
codemap looks stale, say so and offer to refresh it
(`/regenerate-codemap`) rather than working from a guess.

If the vault is not available, say so rather than staying quiet about
it, then orient from the repo itself — `NAMESPACE`, `CONTRIBUTING.md`,
and `_pkgdown.yml`’s reference sections, which group the 76 exports by
concept — before editing.

## Prose

`AGENTS.md` points at the house voice. In Claude Code, apply the
`ehrlinger-writing` skill: it carries the same voice, reader persona and
project context, kept in sync from the vault sources. For documentation
*structure* — README shape, roxygen contract, vignette roles — the
`r-package-style` skill is the companion.
