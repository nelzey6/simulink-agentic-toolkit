---
name: model-change-impact-analysis
description: "Analyze the impact of proposed or completed Simulink model changes. Use before editing to identify affected subsystems, interfaces, parameters, harnesses, and regression tests, or after editing to recommend validation scope."
license: MathWorks BSD-3-Clause
metadata:
  author: MathWorks
  version: "1.0"
---

# Model Change Impact Analysis

Assess the likely impact of a proposed or completed model change before editing or before choosing regression tests. The goal is to make edits safer by identifying affected interfaces, buses, referenced models, parameters, harnesses, and Test Manager cases.

## When to Use

- User asks “what will this change affect?”
- Before modifying blocks, signals, buses, parameters, or interfaces
- After a model edit to decide what to rerun
- Before refactoring a subsystem or changing a bus contract
- When selecting minimal regression tests for a change

## Workflow

1. **State the proposed change**
   - Target model/subsystem/block/signal/parameter
   - Change type: structural, parameter, interface, bus, algorithm, logging, harness/test

2. **Gather broad cached context**
   - Use `model_context` at root or relevant broad scope.
   - Use `model_project_inventory` to discover harnesses, Test Manager files, dictionaries, and referenced models.

3. **Inspect the local change area**
   - Use targeted `model_read` for the subsystem or block ID.
   - Use `model_query_params` for Bus Selector/Assignment, Inport/Outport, Model Reference, Subsystem Reference, Variant, mask, and parameter details.

4. **Identify impact categories**

   | Category | What to check |
   |---|---|
   | Interface | Inports, Outports, bus elements, signal names, dimensions/types if available |
   | Upstream | Producers of changed signal/bus/parameter |
   | Downstream | Consumers, alarms, output adapters, logging, tests |
   | Parameters | Data dictionary entries, tunable blocks, masks, resolved workspace variables |
   | Tests | Harnesses, Test Manager cases, Gherkin feature files |
   | Cache | Need `model_cache_invalidate` after edit batch |

5. **Recommend validation**
   - Structural check: `model_check` on edited scope/root
   - Relevant harnesses/Test Manager cases
   - Simulation/logging checks if behavior or signals changed

## Output Format

```markdown
## Proposed change
...

## Affected model areas
- Direct edit scope:
- Upstream dependencies:
- Downstream consumers:

## Interface impact
...

## Parameter/data impact
...

## Test impact
- Harnesses:
- Test Manager cases:
- Suggested minimal regression set:

## Recommended edit/validation plan
1. ...
```

## Guardrails

- Do not perform edits during impact analysis unless the user explicitly asks.
- Do not assume unlisted tests are irrelevant; call out uncertainty.
- If an edit changes model structure, invalidate the SATK model cache once after the edit batch, not after every individual operation.

----

Copyright 2026 The MathWorks, Inc.
