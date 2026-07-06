# Prototype Simulink model cache tools

This folder contains experimental cache-aware MCP tool entry points for Simulink model analysis.

The prototype is intentionally independent of the SATK P-coded `model_read`, `model_overview`, and `model_check` implementations. It uses public MATLAB/Simulink APIs directly and stores project-local JSON cache records using the SATK project-local convention under:

```text
.satk/model-cache/<modelName>/
```

## Tool entry points

- `model_cache_status(model, scope, detail)` — check whether a cache record exists and is fresh.
- `model_cache_get(model, scope, detail)` — return a cached record without live analysis.
- `model_cache_update(model, scope, analysis, force)` — run cheap scoped analysis and update cache.
- `model_analyze_cached(model, scope, checks, cachePolicy)` — cache-first analysis wrapper.

## Currently supported details

- `summary` — depth-1 block list and block type counts.
- `interfaces` — summary plus per-block port metadata.
- `connections` — summary plus depth-1 signal connections.

## Deliberate constraints

- No model compile/update is performed.
- No full recursive traversal is performed.
- `blk_N` aliases are not resolved yet; use `root` or direct Simulink paths.
- Cache freshness currently uses file hash/timestamp, MATLAB release, and `matlab/startup.m` hash when present.

## Example

```matlab
addpath(genpath('tools/model_cache'))
openExample('simulink_general/sldemo_househeatExample')

r = model_analyze_cached('sldemo_househeat', 'root', '["interfaces"]', 'use-if-fresh');
s = model_cache_status('sldemo_househeat', 'root', 'interfaces');
```

