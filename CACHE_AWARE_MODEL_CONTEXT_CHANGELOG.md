# Cache-Aware Simulink Model Context Prototype Changelog

This branch adds a prototype cache-aware model context layer for the Simulink Agentic Toolkit. The goal is to reduce repeated broad model reads, repeated MATLAB runtime calls, and repeated LLM token spend during iterative engineering workflows.

## Summary

Added a first-choice `model_context` MCP tool plus lower-level cache tools. The new layer provides compact, task-oriented Simulink working context using project-local JSON cache records. It avoids full recursive traversal and model compile by default.

## Bootstrap installer

Added `setupCacheAwareSATK.m` as a fork-local installer/bootstrap wrapper. It:

- adds the fork and cache tools to the MATLAB path,
- runs `satk_initialize` when available,
- writes MCP config for supported agents pointing to this fork's `tools/tools.json`,
- defaults to `Agent="all"` for Pi, Claude Code, Gemini CLI, Amp, and VS Code/Copilot config locations,
- backs up existing MCP configs before modifying,
- verifies that `model_context` and `model_cache_invalidate` are visible.

Example:

```matlab
addpath("D:/Repos/GitHub/simulink-agentic-toolkit")
setupCacheAwareSATK("install")
```

## New MCP tools

### `model_context`

First-choice cache-aware context tool for engineering tasks.

Inputs:

- `task` — natural-language engineering task or question.
- `model` — model name/path or `auto`.
- `scope` — `root`, `auto`, block path, subsystem path, or `blk_N` alias.
- `budget` — currently optimized for `cheap` behavior.
- `cachePolicy` — `cache-only`, `use-if-fresh`, `refresh-if-stale`, `force-refresh`, or `do-not-cache`.

Returns:

- resolved project/model/scope,
- candidate scopes,
- compact summary/interface/connection context,
- targeted high-value parameters,
- basic findings,
- ambiguity information,
- suggested next tool calls.

### `model_cache_status`

Checks whether a cache record exists and whether it is stale.

### `model_cache_get`

Returns a cached record without live analysis.

### `model_cache_update`

Runs cheap scoped analysis and updates the cache.

### `model_analyze_cached`

Cache-first analysis wrapper for summary/interface/connection details.

### `model_cache_invalidate`

Invalidates scope-local cache records plus the block index. Intended for use after `model_edit` or manual model changes.

## Cache storage

Cache records now use SATK-style project-local storage:

```text
.satk/model-cache/<modelName>/
```

This mirrors existing SATK conventions such as:

```text
.satk/library-cache/
.satk/library-kg/
```

## Supported cached details

### `summary`

- depth-1 block list,
- block type counts,
- block path,
- SID where available,
- parent,
- link status.

### `interfaces`

Includes `summary` plus:

- `Ports`,
- input port names,
- output port names.

### `connections`

Includes `summary` plus depth-1 signal connections:

- source block,
- source port,
- destination block,
- destination port,
- signal name.

## Project/model discovery

Added lightweight project discovery that detects:

- project root,
- `matlab/startup.m`,
- `.slx` model candidates,
- `.sldd` data dictionaries,
- notes from `MATLAB.md` / `mcp.md` when present.

`model=auto` now uses project information and loaded models before falling back to `.slx` search.

## Scope resolution

Improved `scope=auto` resolution with:

- explicit scope support,
- `blk_N` alias resolution through Simulink SID APIs,
- current Simulink selection via `gcb`,
- exact block-name token matching,
- partial path/name matching,
- stop-word filtering to avoid common false positives,
- ambiguity reporting when multiple candidates are found.

## Targeted parameters

`model_context` now returns high-value parameters for the resolved target without dumping all parameters:

- `BlockType`,
- `ReferenceBlock`,
- `LinkStatus`,
- `MaskType`,
- `Ports`,
- `Description`.

## Findings

Added a basic findings mechanism. Current findings include:

- startup script detected,
- data dictionaries detected.

This provides a place to persist future diagnostics such as unresolved libraries, numeric precision warnings, startup requirements, and known model issues.

## Freshness and invalidation

Cache fingerprints include:

- cache schema version,
- MATLAB release,
- model file hash,
- model file timestamp,
- model dirty flag when loaded,
- `matlab/startup.m` hash when present.

Lazy refresh occurs when a requested cache record is missing or stale.

`model_cache_invalidate` provides explicit invalidation after edits. Updated skill guidance now instructs agents to invalidate the edited scope after `model_edit`.

## Agent/tool guidance updates

Updated tool descriptions so agents naturally prefer `model_context` before broad `model_overview` or `model_read` calls.

Updated `building-simulink-models` skill workflow:

1. perform existing library/policy gates,
2. call `model_context` first for existing-model edits/debugging,
3. call targeted `model_read` only when algorithmic expressions or deeper topology are needed,
4. call `model_cache_invalidate` after `model_edit`,
5. verify with `model_context` or scoped `model_read`,
6. run `model_check` on the narrowest relevant scope.

Updated `AGENTS.md` to list the new tools and clarify that `model_context` is the first-choice cache-aware context tool.

## End-to-end validation

Validated through MATLAB and fresh Pi sessions using a temporary MCP config pointing to the modified local `tools/tools.json`.

Observed behavior:

- `matlab_model_context` is exposed as an MCP tool.
- `matlab_model_cache_invalidate` is exposed as an MCP tool.
- Fresh Pi sessions naturally selected `matlab_model_context` first for an engineering prompt.
- `model_context('change func1 logic','mv_mot_ctrl','auto','cheap','use-if-fresh')` resolved `mv_mot_ctrl/func1` and returned compact context.
- Cache records were written under `.satk/model-cache/<modelName>/`.

## Design constraints intentionally preserved

The prototype does not:

- compile/update the model by default,
- run full recursive traversal by default,
- replace SATK P-coded implementations,
- perform background watching,
- build a complex dependency invalidation graph,
- dump all parameters,
- require users to manually call low-level cache tools in normal workflows.

## Known limitations / next steps

- Scope ranking is still heuristic and should be improved with better scoring.
- Findings are basic and should ingest diagnostics/check results over time.
- The cache does not yet export a Markdown model knowledge graph.
- Existing `model_read`/`model_overview` are not internally wrapped; behavior is currently guided by tool descriptions and skills.
- Compiled facts are intentionally unsupported until explicitly designed with stricter invalidation.
- The temporary Pi MCP config used for testing is not intended to be committed.
