# Simulink structural snapshot

`model_context` stores one complete compile-free structural snapshot per model:

```text
.satk/model-cache/<modelName>/snapshot.json
```

The first `use-if-fresh` call loads the model and records its hierarchy, blocks, ports, interfaces, connections, and known file dependencies. Later calls validate file metadata once and query the snapshot without loading or traversing the model.

For `scope="auto"`, candidates are ranked by complete block-name phrase, name-token overlap, partial name match, and path-only match. Subsystems and Model Reference blocks receive a scope-container preference so a matching engineering area wins over descendants that match only because their path contains the same words.

Returned slices are compact without changing the stored snapshot:

- `resolvedScope`, `candidateScopes`, and `context.scope` use complete model paths.
- Block paths and connection endpoints inside `context.scope` are relative to that scope; `.` identifies the scope itself.
- Connection endpoints outside the scope retain complete paths.
- `parent` is omitted, and optional block/connection fields are omitted when unused by the complete returned slice.
- `summary.totalDirectBlocks` and `summary.omittedBlocks` report exact block coverage when the 25-block response limit is reached.
- `truncated.connections=true` means the 40-connection response limit was reached and additional connections may exist. It intentionally avoids another counting pass.

When either response limit is reached, `nextActions` directs the agent to inspect another candidate or a deeper explicit scope, or to use a targeted `model_read` when exact current structure is required.

Supported policies:

- `use-if-fresh` — use a fresh snapshot or rebuild it.
- `cache-only` — use a fresh snapshot and never perform live Simulink work.
- `force-refresh` — rebuild the snapshot.

The snapshot covers structural, compile-free facts. Use a targeted `model_read` for algorithmic expressions and current edit identifiers. After an edit batch, call `model_cache_invalidate(model)` once.

Add `.satk/` to the consuming project's ignore file. Legacy per-scope records under the same model-cache directory are removed after a schema-v2 snapshot is written. The separate `.matlab-mcp-cache` directory is not modified.
