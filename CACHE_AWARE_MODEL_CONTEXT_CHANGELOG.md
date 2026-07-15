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

## Existing project and test assets

The retained workflow tools are:

- `model_project_inventory` — live discovery of models, libraries, dictionaries, external harness models, and `.mldatx` files.
- `model_test_manager_list` — inspection of existing native test suites and cases.
- `model_test_manager_run` — selected/full native test execution with result summaries and optional JUnit/PDF artifacts.

Harness lifecycle and Test Manager authoring tools were removed. External harness `.slx` files use normal model tools; Gherkin tests and automatic temporary harness generation remain available through `model_test`.

## Removed prototype surface

The lower-level cache status/get/update/analyze tools, secondary project/Test Manager caches, project setup tool, fork-specific installer, harness lifecycle tools, Test Manager authoring/results tools, redundant cache policies, and `budget` planner input were removed.

## Validation

Automated tests cover cold build, warm unloaded reads, cache-only behavior, invalidation, saved and dirty model changes, dictionary changes, project inventory, and registry/schema parity.

On `mv_mot_ctrl`, validation captured 4,643 blocks and 5,176 connections. The cold build took about 73 seconds; a warm task-oriented lookup took about 0.33 seconds without loading the model. Inventory found 62 external harness models, Test Manager inspection found 67 cases, and one selected native test passed.
