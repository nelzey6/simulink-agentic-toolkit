# Cache-aware Simulink model context changelog

This branch adds a deliberately small cache-aware context and existing-test workflow.

## Structural snapshot

`model_context` builds one complete compile-free structural snapshot on the first call and stores it at:

```text
.satk/model-cache/<modelName>/snapshot.json
```

The snapshot contains model hierarchy, block identity and type, ports, interfaces, connections, known referenced model/library files, project data dictionaries, and `matlab/startup.m` metadata. Later calls validate those file dependencies once and query the snapshot without loading the model.

The supported policies are `use-if-fresh`, `cache-only`, and `force-refresh`. The response identifies its source as `cache` or `live+cache_update` and declares `coverage="structural-compile-free"`.

`model_cache_invalidate(model)` removes the complete snapshot. Agent guidance calls it once after an edit batch, or immediately after a partial edit.

The snapshot does not replace P-coded SATK tools. Exact algorithmic expressions, current edit identifiers, parameter values, and structural checks remain targeted live calls.

## Why use the cache

The cache pays one full compile-free traversal up front, then supports repeated orientation and scope selection without reopening or traversing the model. On the 4,643-block `mv_mot_ctrl` benchmark:

| Benefit | Measured result |
|---|---:|
| Complete cold snapshot build | About 73 seconds |
| Warm task-oriented lookup | About 0.33 seconds |
| Warm lookup versus rebuilding the snapshot | About 220x faster |
| Warm MATLAB model state | Model remains unloaded |
| Complete snapshot stored on disk | 4.0 MB |
| Root context returned to the agent | 637 bytes, approximately 160-210 tokens |
| Median subsystem context | 1.4 KB, approximately 350-470 tokens |
| 95th-percentile subsystem context | 8.9 KB, approximately 2,200-3,000 tokens |
| Response compaction improvement | 44% smaller on average across 470 subsystem scopes |

The 4.0 MB snapshot is local cache data and is never returned wholesale to the agent. If transmitted directly, it would be roughly 1.0-1.3 million tokens; instead, `model_context` returns at most 25 blocks and 40 relevant connections for the resolved scope. Token estimates use a range of three to four serialized characters per token and exclude the small MCP response envelope, so exact counts depend on the model and LLM tokenizer.

This is most beneficial during multi-step work on large models: the agent can repeatedly locate engineering areas and inspect their immediate structure cheaply, then use targeted live calls only for exact algorithms, parameters, edits, checks, simulations, and tests. For a single known parameter or one narrowly scoped read, calling the targeted live tool directly can still be faster than paying the cold snapshot cost.

## Existing project and test assets

The retained workflow tools are:

- `model_project_inventory` — live discovery of models, libraries, dictionaries, external harness models, and `.mldatx` files.
- `model_test_manager_author` — idempotent creation or update of one simulation case in an existing `.mldatx` file.
- `model_test_manager_list` — inspection of existing native test suites and cases.
- `model_test_manager_run` — selected/full native test execution with result summaries and optional JUnit/PDF artifacts.

Harness lifecycle tools were removed. External harness `.slx` files use normal model tools; Gherkin tests and automatic temporary harness generation remain available through `model_test`. The retained authoring tool deliberately operates only on existing Test Manager files and does not create files or harnesses.

## Removed prototype surface

The lower-level cache status/get/update/analyze tools, secondary project/Test Manager caches, project setup tool, fork-specific installer, harness lifecycle tools, broad Test Manager file/case lifecycle and standalone results tools, redundant cache policies, and `budget` planner input were removed.

## Validation

Automated tests cover cold build, warm unloaded reads, cache-only behavior, invalidation, saved and dirty model changes, dictionary changes, project inventory, Test Manager author/list/run behavior, and registry/schema parity.

On `mv_mot_ctrl`, validation captured 4,643 blocks and 5,176 connections. The cold build took about 73 seconds; a warm task-oriented lookup took about 0.33 seconds without loading the model. Inventory found 62 external harness models, Test Manager inspection found 67 cases, and one selected native test passed.

Task-based scope selection now ranks complete name phrases, name-token matches, partial name matches, and path-only matches, with a preference for matching scope containers. Context responses use scope-relative block and connection paths and omit slice-wide unused fields. Replaying all 470 subsystem scopes from the `mv_mot_ctrl` snapshot reduced serialized context size by 44% on average: the median fell from about 2.8 KB to 1.4 KB and the 95th percentile from 20.5 KB to 8.9 KB. Direct cache-only calls returned 637 bytes for the model root and 11.9 KB for a capped 25-block/40-connection deep scope while leaving the model unloaded.

## Release acceptance

Before release, run one smoke test from the packaged installer rather than a source checkout:

1. Install `agenticToolkitInstaller.mltbx` into a clean test environment and run `setupAgenticToolkit("install")`.
2. Start a fresh MATLAB session, run `satk_initialize`, and confirm the MCP server advertises every name in `tools/registry.json`.
3. Run a cold `model_context` call on a generated model and confirm that it writes one schema-v2 snapshot.
4. Close the model, run a warm `model_context` call, and confirm that the model remains unloaded.
5. Confirm `model_project_inventory`, `model_test_manager_author`, `model_test_manager_list`, and `model_test_manager_run` are registered; execute the Test Manager checks when Simulink Test is licensed.
