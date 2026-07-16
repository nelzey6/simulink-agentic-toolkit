# Upstream Adoption Guide

This branch is an implementation proposal for `matlab/simulink-agentic-toolkit`. External pull requests are reviewed but not merged, so the final diff is organized below as three independently reviewable adoption packets. This guide is a handoff artifact; it does not need to ship with the toolkit.

## 1. Cache-aware model context

### Public surface

- `model_context` builds one complete compile-free structural snapshot, then serves compact scoped results from that snapshot.
- `model_cache_invalidate` removes the snapshot after an edit batch.
- Existing model workflows prefer `model_context` before broad live reads.

### Primary files

- `tools/model_cache/**`
- The `model_context` and `model_cache_invalidate` entries in `tools/tools.json` and `tools/registry.json`
- Cache guidance in `AGENTS.md`, `README.md`, and `Configuration_and_Troubleshooting.md`
- `skills-catalog/model-based-design-core/building-simulink-models/**`
- `CACHE_AWARE_MODEL_CONTEXT_CHANGELOG.md`

### Validation

- 9 structural snapshot integration tests pass.
- Cold/warm parity, unloaded warm reads, invalidation, freshness, ambiguity, compaction, cross-scope connections, and truncation are covered.

## 2. Existing project and Test Manager assets

### Public surface

- `model_project_inventory` discovers existing model, harness, dictionary, Test Manager, feature, and MATLAB assets.
- `model_test_manager_author` idempotently creates or updates one simulation case in an existing `.mldatx` file.
- `model_test_manager_list` inspects existing native tests.
- `model_test_manager_run` executes selected or all native tests.
- File and harness lifecycle remain MATLAB-owned; these tools do not create `.mldatx` files or permanent harnesses.

### Primary files

- `tools/common/+satkproject/**`
- `tools/model_project/**`
- `tools/model_test_manager/**`
- The project and Test Manager entries in `tools/tools.json` and `tools/registry.json`
- Test Manager requirements and workflow guidance in `AGENTS.md`, `README.md`, and `Configuration_and_Troubleshooting.md`
- `skills-catalog/model-based-design-core/testing-simulink-models/**`

### Validation

- 1 project inventory integration test passes.
- 12 licensed Test Manager integration tests pass.
- Authoring coverage includes create, unchanged, update, validation failures, execution, external harness association, and rejection of a same-named non-simulation case.
- `validate_model_project_tools` confirms entry points, argument order, removed-tool absence, and exact `tools.json`/`registry.json` schema parity.

## 3. Model workflow skills

### Skills added

- `adding-simulink-logging`
- `debugging-simulink-test-failures`
- `documenting-simulink-models`
- `model-change-impact-analysis`
- `tracing-simulink-signals`

### Primary files

- The five skill directories under `skills-catalog/model-based-design-core/`
- `skills-catalog/README.md`
- Manifest updates to existing building and testing skills

### Validation

- Every changed skill has a parseable manifest.
- Skill directory names, frontmatter names, and versions agree with their manifests.
- Every required `model_*` tool resolves to a registered tool.

## Combined branch validation

Validated against the current `upstream/main` merge base:

- 22 MATLAB integration tests pass: 9 snapshot, 1 inventory, and 12 Test Manager tests.
- Tool contract validation passes with no reported problems.
- MATLAB Code Analyzer reports zero messages across the 25 changed/new MATLAB files in the tool groups.
- Both tool metadata JSON files parse successfully.
- `git diff --check` passes.
- The branch merges cleanly with current `upstream/main` after rebasing.
- `validate_installation` passes when the branch tool directories are placed on the MATLAB path; the local environment reports only the expected missing packaged MCP-server binary warning.

## Packaged-installer acceptance gate

The repository does not contain an `agenticToolkitInstaller.mltbx` built from this branch or a packaging workflow that can produce one. Before release, MathWorks should build the normal installer artifact and execute the five packaged-install checks in `CACHE_AWARE_MODEL_CONTEXT_CHANGELOG.md`. This is the only validation item that cannot be completed from the branch source tree.
