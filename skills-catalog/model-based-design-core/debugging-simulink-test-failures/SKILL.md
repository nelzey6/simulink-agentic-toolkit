---
name: debugging-simulink-test-failures
description: "Diagnose failing Simulink tests, harness simulations, Test Manager cases, and model_test scenarios. Use when a user reports a failed test, failed harness run, assertion failure, unexpected simulation output, or asks why a Simulink test is failing."
license: MathWorks BSD-3-Clause
metadata:
  author: MathWorks
  version: "1.0"
---

# Debugging Simulink Test Failures

Diagnose failing Simulink tests by combining test results, harness context, cached model structure, signal traces, and targeted parameter queries. The goal is to identify the most likely failing interface, subsystem, signal, parameter, or assertion without dumping the whole model.

## When to Use

- A Test Manager case fails
- A harness simulation errors or asserts
- `model_test` returns failing Gherkin scenarios
- A regression test changed from pass to fail
- A user asks why a Simulink test/harness is failing
- Simulation reaches stop time but expected behavior is wrong

## Default Workflow

1. **Capture the failure artifact**
   - Test Manager: use `model_test_manager_list` then `model_test_manager_run` for the selected test(s).
   - Gherkin/SATK: use `model_test` result details.
   - Harness simulation: inspect `SimulationMetadata.ExecutionInfo`, warnings, errors, and SDI/logged signals.

2. **Identify the system under test**
   - Record model, harness, harness owner, test case, stop time, simulation mode, scenario/iteration if present.
   - Use `model_project_inventory` if the target is unclear.

3. **Use cached model context before raw MATLAB dumps**
   - Use `model_context` for the SUT or owning model.
   - Use targeted `model_read` only around the failing subsystem, assertion, or signal path.

4. **Classify the failure**

   | Failure type | Primary investigation |
   |---|---|
   | Simulation error | Diagnostics, missing variables, compile/config errors, invalid dimensions/types |
   | Assertion failure | Assertion input signal, thresholds, expected condition, source signal path |
   | Numeric mismatch | logged signal, reference/baseline, parameter values, solver/sample timing |
   | Missing signal/log | harness logging, `out_dbg`, SDI run contents, signal logging settings |
   | Timeout/stop issue | StopTime, triggers, enable conditions, state machine progression |

5. **Trace only the relevant signals**
   - Use `model_read` and `model_query_params` for Bus Selectors/Assignments, Inports/Outports, From/Goto, and harness inputs.
   - Avoid broad `find_system` dumps.

6. **Summarize likely cause and next action**
   - State evidence, likely root cause, model locations to inspect, and the smallest reproduction/rerun command.

## Output Format

Use this concise structure:

```markdown
## Failure summary
- Test/harness:
- Model/SUT:
- Result:
- Error/assertion:

## Evidence
- Key diagnostics:
- Relevant signals:
- Relevant parameters:

## Likely cause
...

## Where to inspect
1. ...
2. ...

## Recommended next step
...
```

## Guardrails

- Do not rewrite model logic while diagnosing unless explicitly asked.
- Do not run the full regression suite unless the user asks.
- Do not assume binary S-Function internals are visible; treat them as integration points.
- If simulation data is not logged, say so and recommend targeted logging rather than inventing results.

----

Copyright 2026 The MathWorks, Inc.
