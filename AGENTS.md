<!-- Copyright 2026 The MathWorks, Inc. -->

# Simulink Agentic Toolkit — Agent Instructions

## Setup

If the user asks to set up the Simulink Agentic Toolkit, direct them to run the following in MATLAB:

```matlab
setupAgenticToolkit("install")
```

This handles platform detection, MCP server download, toolkit installation, agent configuration, and skill registration. Do not attempt to run setup commands on the user's behalf.

## Domain Skills

Simulink domain skills are in `skills-catalog/model-based-design-core/`. Each skill has a `SKILL.md` with instructions and a `manifest.yaml` with metadata.

## MCP Tools

MCP tools are available when the MCP server is connected (see `tools/registry.json`):
- `model_context` — first-choice structural context; builds one compile-free snapshot and reuses it on later calls
- `model_overview` — hierarchical model visualization
- `model_read` — block topology and expression notation
- `model_edit` — structural modifications
- `model_check` — structural validation (unconnected ports, dangling lines, Edit-Time Checks on States and Subcharts)
- `model_query_params` — random access to parameters
- `model_resolve_params` — resolve workspace variables
- `model_test` — Gherkin-based behavioral testing (requires Simulink Test)
- `model_cache_invalidate` — remove the complete model snapshot after an edit batch
- `model_project_inventory` — discover existing models, external harness models, dictionaries, and Test Manager assets
- `model_test_manager_list`, `model_test_manager_run` — inspect and run existing native Test Manager tests (requires Simulink Test)

## MATLAB Prerequisite

The MCP server uses `--matlab-session-mode=existing`. MATLAB must be running with `satk_initialize` executed (which calls `shareMATLABSession`) before MCP tools will work. The MATLAB MCP Server Toolbox must be installed once per MATLAB version. If tools fail to connect, guide the user to run `addpath('<toolkit_root>'); satk_initialize` in MATLAB.
