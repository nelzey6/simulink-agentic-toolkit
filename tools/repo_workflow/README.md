# Repo Workflow MCP Tools

This folder adds MCP entry points for OA/Simulink repository workflows that combine model edits, Simulink Test harnesses, and native `.mldatx` Test Manager assets.

## Tool families

- `repo_setup` — add SATK/toolkit path, run repo startup, validate tool availability, return inventory.
- `repo_inventory` — cache-aware discovery of models, libraries, dictionaries, harnesses, Test Manager files, feature files, and MATLAB scripts.
- `harness_list`, `harness_create`, `harness_open`, `harness_save`, `harness_close` — wrappers around `sltest.harness.*` so harness lifecycle is native in the MCP workflow. Harness contents are still edited through `model_read`/`model_edit`/`model_check` once opened or resolved as an SLX file.
- `test_manager_list`, `test_manager_create_case`, `test_manager_configure_case`, `test_manager_run`, `test_manager_results` — native Simulink Test Manager `.mldatx` inspection, authoring, execution, and result summarization.

## Cache behavior

Read/list/result tools accept `cachePolicy` where applicable:

- `cache-only`
- `use-if-fresh`
- `refresh-if-stale`
- `force-refresh`
- `do-not-cache`

Caches are stored project-locally under `.satk/repo-cache/`. Mutating operations invalidate or bypass relevant caches on a best-effort basis.

## Typical workflow

```text
repo_setup
repo_inventory
test_manager_list
model_read / model_edit / model_check
harness_list / harness_open or harness_create
model_read / model_edit / model_check on harness
test_manager_create_case or test_manager_configure_case
test_manager_run
test_manager_results
```
