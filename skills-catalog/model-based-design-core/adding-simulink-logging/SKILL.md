---
name: adding-simulink-logging
description: "Add or configure targeted Simulink logging, debug outputs, SDI/logsout visibility, or project-specific log_signal blocks. Use when the user wants plots, simulation traces, debug signals, or persistent logged outputs for selected model signals."
license: MathWorks BSD-3-Clause
metadata:
  author: MathWorks
  version: "1.0"
---

# Adding Simulink Logging

Add or configure logging for selected Simulink signals in a targeted, minimally invasive way. The goal is to make signals visible in simulation outputs or SDI without randomly instrumenting the model.

## When to Use

- User wants to see plots from simulation
- `SimulationOutput` only contains `tout` but useful signals are missing
- Need to expose internal signals for debugging
- Need to add signals to an existing debug/logging adapter such as `out_dbg`
- Need to decide whether to use signal logging, SDI, `logsout`, To Workspace, or project-specific `log_signal` blocks

## Workflow

1. **Identify desired signals**
   - Ask the user which signals matter if unclear.
   - If the user names behavior, use `tracing-simulink-signals` to find candidate signals.

2. **Check existing logging first**
   - Use `model_context` / `model_read` around existing debug/logging subsystems.
   - Look for existing `log_signal`, To Workspace, Outport, Assertion, SDI, or signal logging setup.
   - Prefer extending the project’s established logging pattern.

3. **Choose logging mechanism**

   | Situation | Preferred mechanism |
   |---|---|
   | Existing project-specific debug adapter exists | Extend that adapter, e.g. `out_dbg` / `metabus_lib/log_signal` |
   | Need quick temporary simulation trace | Enable signal logging / SDI on targeted signal |
   | Need persistent test output | Harness output/logging or Test Manager logging configuration |
   | Need workspace analysis | `logsout` or Dataset logging, not arbitrary base-workspace writes |

4. **Make minimal edits**
   - Use `model_edit` for structural additions or parameter changes.
   - Do not add logging to broad bus roots unless needed.
   - Avoid changing algorithm behavior.

5. **Validate**
   - Run `model_check` on the edited scope/root.
   - Invalidate cache once after edit batch with `model_cache_invalidate`.
   - If user asks, run the relevant harness/simulation and list `logsout`/SDI signals.

## Output Format

```markdown
## Logging plan
- Signal(s):
- Existing logging path:
- Proposed mechanism:
- Model changes:

## Validation
- Structural check:
- Simulation/logging verification:

## How to view results
- MATLAB/SDI/logsout commands:
```

## Guardrails

- Do not add broad, noisy logging by default.
- Do not use base workspace side effects as the primary logging mechanism.
- Do not run long simulations unless the user asks.
- Preserve existing project logging conventions.
- After structural edits, invalidate the model cache once per edit batch.

## Useful MATLAB Patterns

For quick inspection after a run:

```matlab
who(out)
if any(strcmp(who(out), 'logsout'))
    disp(out.logsout.getElementNames')
end
Simulink.sdi.view
```

For SimulationInput-based rerun:

```matlab
in = Simulink.SimulationInput(mdl);
out = sim(in);
```

----

Copyright 2026 The MathWorks, Inc.
