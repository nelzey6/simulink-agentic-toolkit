# Model Project MCP Tools

These tool groups add MCP entry points for OA/Simulink project workflows that combine model edits, Simulink Test harnesses, and native `.mldatx` Test Manager assets.

## Tool families

- `model_project_setup` — add SATK/toolkit path, run project startup, validate tool availability, return inventory.
- `model_project_inventory` — cache-aware discovery of models, libraries, dictionaries, harnesses, Test Manager files, feature files, and MATLAB scripts.
- `model_harness_list`, `model_harness_create`, `model_harness_open`, `model_harness_save`, `model_harness_close` — wrappers around `sltest.harness.*` so harness lifecycle is native in the MCP workflow. Harness contents are still edited through `model_read`/`model_edit`/`model_check` once opened or resolved as an SLX file.
- `model_test_manager_list`, `model_test_manager_create_case`, `model_test_manager_configure_case`, `model_test_manager_run`, `model_test_manager_results` — native Simulink Test Manager `.mldatx` inspection, authoring, execution, and result summarization.

## Cache behavior

Read/list/result tools accept `cachePolicy` where applicable:

- `cache-only`
- `use-if-fresh`
- `refresh-if-stale`
- `force-refresh`
- `do-not-cache`

Caches are stored project-locally under `.satk/model-project-cache/`. Mutating operations invalidate or bypass relevant caches on a best-effort basis.

## Typical workflow

```text
model_project_setup
model_project_inventory
model_test_manager_list
model_read / model_edit / model_check
model_harness_list / model_harness_open or model_harness_create
model_read / model_edit / model_check on harness
model_test_manager_create_case or model_test_manager_configure_case
model_test_manager_run
model_test_manager_results
```
