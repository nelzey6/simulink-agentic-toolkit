# Simulink structural snapshot

`model_context` stores one complete compile-free structural snapshot per model:

```text
.satk/model-cache/<modelName>/snapshot.json
```

The first `use-if-fresh` call loads the model and records its hierarchy, blocks, ports, interfaces, connections, and known file dependencies. Later calls validate file metadata once and query the snapshot without loading or traversing the model.

Supported policies:

- `use-if-fresh` — use a fresh snapshot or rebuild it.
- `cache-only` — use a fresh snapshot and never perform live Simulink work.
- `force-refresh` — rebuild the snapshot.

The snapshot covers structural, compile-free facts. Use a targeted `model_read` for algorithmic expressions and current edit identifiers. After an edit batch, call `model_cache_invalidate(model)` once.

Add `.satk/` to the consuming project's ignore file. Legacy per-scope records under the same model-cache directory are removed after a schema-v2 snapshot is written. The separate `.matlab-mcp-cache` directory is not modified.
