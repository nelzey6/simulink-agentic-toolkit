---
name: documenting-simulink-models
description: "Create developer-oriented Markdown documentation for Simulink models and projects. Use when the user asks for model documentation, a developer guide, architecture/logic explanation, interface documentation, or a source-of-truth-style markdown from Simulink/MCP context."
license: MathWorks BSD-3-Clause
metadata:
  author: MathWorks
  version: "1.0"
---

# Documenting Simulink Models

Create **developer-oriented Markdown documentation** from Simulink models using SATK/MCP tools. The output should help a new developer understand how the model works: intent, architecture, interfaces, dataflow, subsystem responsibilities, tests, and debugging entry points.

The goal is **narrative engineering documentation**, not a raw block dump.

## When to Use

Use this skill when the user asks for:

- a `README`, `matlab.md`, model guide, or developer guide for a Simulink project
- documentation explaining how a model or subsystem works
- interface/bus/test/harness documentation
- a source-of-truth-style Markdown artifact derived from Simulink models
- a proof of concept for documenting one `.slx` file deeply
- onboarding documentation for new developers

## When NOT to Use

- Generating formal requirements → use `generate-requirement-drafts`
- Writing or running behavioral tests → use `testing-simulink-models`
- Running simulations for analysis → use `simulating-simulink-models`
- Editing model structure → use `building-simulink-models`
- Producing compliance reports → use `checking-model-compliance`

## Core Principle

Start broad and cache-aware, then write a human guide.

```text
broad cached context -> targeted facts -> narrative markdown
```

Do **not** create documentation by pasting huge raw `model_read`, `find_system`, or block inventory dumps. Raw facts can be saved as source extracts, but the final Markdown must explain what the model does and how a developer should reason about it.

## Default MCP Strategy

1. **Start with broad cache-aware context**

   Use `model_context` first when it works:

   ```json
   {
     "model": "<model>.slx",
     "scope": "root",
     "task": "Create developer-oriented documentation: purpose, architecture, interfaces, major subsystems, dataflow, parameters, tests, and debugging guide.",
     "cachePolicy": "use-if-fresh"
   }
   ```

   If `model_context` times out or is too compact, use `model_overview` and targeted `model_read`.

2. **Avoid raw session dumps**

   Avoid broad MATLAB commands such as session-wide `find_system` over every loaded library unless information is unavailable through SATK tools.

3. **Use structured tools**

   Prefer:

   - `model_project_inventory` for project assets, harnesses, dictionaries, and Test Manager files
   - `model_overview` for hierarchy and interfaces
   - `model_read` for topology and expressions at known scopes
   - `model_query_params` for important Bus Selector, Bus Assignment, mask, block, or configuration parameters
   - `model_check` for structural validation status
   - `model_test_manager_list` for Test Manager suites/cases

4. **Use targeted MATLAB code only for gaps**

   Use `evaluate_matlab_code` only for targeted facts not exposed by SATK tools, such as:

   - data dictionary entry counts and representative names
   - exact `get_param` values for bus contracts
   - saved JSON source extracts under `.satk/doc-sources`

5. **Do not simulate unless asked**

   Documentation generation should not run `sim()` unless the user asks to include fresh simulation behavior or plots.

## Output Conventions

Choose the output filename from user intent:

| Request | Default output |
|---|---|
| Holistic project/model overview | `matlab.md` |
| One model developer guide | `<model>_developer_guide.md` |
| One subsystem guide | `<model>_<subsystem>_developer_guide.md` |
| Raw data appendix, if needed | `.satk/doc-sources/*.json` or `.satk/doc-sources/*.txt` |

Always include a **Contents** section near the beginning for fast navigation.

## Recommended Markdown Structure

For a developer guide, use this structure unless the user requests otherwise:

```markdown
# Developer Guide: How <model-or-subsystem> Works

_One-paragraph purpose of the document._

## Contents
- links to all major sections

## 1. What this model is
- model role
- what it owns
- what it delegates
- what it is not

## 2. One-screen architecture
- compact ASCII diagram
- main components and dataflow

## 3. Execution model
- triggers, sample/control flow, scheduling assumptions if visible
- root-level execution path

## 4. Main dataflow
- inputs -> algorithm/composition -> outputs
- important buses and signal groups

## 5. Interfaces
- input ports/buses/signals
- output ports/buses/signals
- external S-Functions / platform integration points

## 6. Major subsystems/components
For each major subsystem:
- purpose
- inputs
- outputs
- internal algorithm summary
- important parameters/buses
- where to debug

## 7. Parameters and data dictionaries
- dictionaries used
- entry counts
- important parameter families
- how parameters connect to model behavior

## 8. Tests and harnesses
- Test Manager files
- suites and cases relevant to this model
- harness models
- what behavior the tests appear to cover

## 9. Debugging guide
- if input is wrong, where to look
- if output is wrong, where to look
- if alarm/status is wrong, where to look
- if logging/plot is missing, where to look

## 10. Limitations and next documentation passes
- binary S-Functions
- referenced models not yet deeply documented
- assumptions/inferences
```

## Writing Style Rules

### Prefer explanatory prose over exhaustive lists

Bad:

```markdown
- blk_1 Gain
- blk_2 Sum
- blk_3 Saturation
```

Good:

```markdown
The speed-control path computes a torque/current request from speed error, then applies power, DC-link, torque, overspeed, and SCO limits before emitting `Iq_ref_pu` and `sco_bus`.
```

### Separate facts from inferences

Use clear wording:

- **Fact from MCP:** "`out_dbg` contains `metabus_lib/log_signal` blocks for `Iq_ref_pu`, `Speed_ref_ramp_pu`, and `mpr_PI_intOut`."
- **Inference:** "This subsystem is the best place to inspect or extend debug logging."

### Document intent at subsystem level

For each subsystem, answer:

1. Why does this subsystem exist?
2. What does it consume?
3. What does it produce?
4. What other subsystem should a developer inspect next?
5. What tests or harnesses cover it?

### Keep raw details out of the main narrative

If a raw list is useful, put it in:

- an appendix,
- a table with interpretation, or
- `.satk/doc-sources/` as a source extract.

Do not make the main document a chaotic block inventory.

## Recommended Workflow

### Step 1 — Identify target and scope

Determine whether the user wants:

- project-level overview,
- main model guide,
- one referenced library guide,
- one subsystem guide,
- tests/harness documentation.

If unclear, ask a short clarification or pick the active/model-named target.

### Step 2 — Gather broad context

Use cache-aware tools first:

```text
model_context(model, root, task, use-if-fresh)
model_project_inventory(repo=auto)
model_overview(model, root, interfaces)
```

If `model_context` times out, continue with `model_overview` and targeted `model_read` rather than raw MATLAB dumps.

### Step 3 — Identify major components

Use `model_read(model, root, depth="1" or "2")` to identify:

- top-level execution flow,
- referenced models/subsystems,
- major children,
- bus fan-in/fan-out points,
- S-Function integration points,
- algorithmic expressions.

For each major subsystem, classify it as one of:

- algorithm/computation,
- input adapter,
- output adapter,
- alarm/status adapter,
- debug/logging adapter,
- parameter/tuning adapter,
- platform/binary integration point.

### Step 4 — Query important contracts

Use `model_query_params` or targeted `evaluate_matlab_code(get_param(...))` for important contracts:

- Bus Selector `OutputSignals`
- Bus Assignment `AssignedSignals`
- Inport/Outport names
- model reference/subsystem reference targets
- masks or variants
- key parameters, gains, thresholds, sample times if relevant

Do not query every block. Query the contracts that explain how the model works.

### Step 5 — Gather tests and harnesses

Use:

```text
model_project_inventory
model_test_manager_list
```

Document:

- Test Manager files
- suite names
- test case names
- model under test
- harness name
- harness owner
- stop time/enabled state
- what behavior appears to be covered

If no Test Manager file exists, state that clearly.

### Step 6 — Write the guide

Write the Markdown as a coherent document with:

- Contents at the top
- architecture diagram
- subsystem purpose sections
- interface tables
- dataflow explanations
- debugging entry points
- limitations

### Step 7 — Quality gate before final response

Before telling the user it is done, check:

- The doc starts with a Contents section.
- The doc has a one-screen architecture diagram.
- The doc explains purpose and dataflow, not just block names.
- Every major subsystem has a role/purpose.
- Interfaces and bus contracts are summarized.
- Tests/harnesses are mentioned when available.
- Limitations are explicit.
- Raw/generated source extracts are not mistaken for final documentation.

## POC Pattern for Main Model Integration Shells

For a main integration model like `mv_mot_ctrl.slx`, use this mental model:

```text
main model = platform integration shell
referenced composition/libraries = algorithm implementation
```

Document the main model around:

- execution trigger
- input-bus construction
- referenced control composition call
- output/adaptor fanout
- alarms/messages
- debug logging
- metabus/BICO/NVRAM/tuning integration
- where to go next for actual algorithm logic

Do **not** claim the main shell fully explains the algorithm if the algorithm lives in referenced models.

## Example Final Summary

When complete, summarize concisely:

```text
Created <path>/<model>_developer_guide.md.
It is a narrative developer guide with contents, architecture, interfaces, subsystem roles, test context, and debugging guidance.
It does not replace detailed docs for referenced models; next recommended pass is <referenced model>.
```

----

Copyright 2026 The MathWorks, Inc.
