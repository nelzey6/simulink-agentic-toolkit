---
name: tracing-simulink-signals
description: "Trace Simulink signals through subsystems, buses, Bus Selectors/Assignments, Goto/From, BICO/metabus adapters, and referenced model boundaries. Use when a user asks where a signal comes from, where it goes, or how a value reaches an output/alarm/test."
license: MathWorks BSD-3-Clause
metadata:
  author: MathWorks
  version: "1.0"
---

# Tracing Simulink Signals

Trace a signal from source to sink, or from sink back to source, using structured model context and targeted topology/parameter queries. This skill is especially useful for large models that use buses, Goto/From, subsystem references, BICO/metabus adapters, and logging adapters.

## When to Use

- “Where does this signal come from?”
- “Where is this signal used?”
- “How does this alarm get generated?”
- “Which block writes this bus element?”
- “How does this value reach BICO/metabus/logging/output?”
- “Trace this signal through the harness/model.”

## Workflow

1. **Define trace direction**
   - Source-to-sink: producer → consumers
   - Sink-to-source: observed output/alarm/log/assertion → producer
   - Bidirectional if unclear

2. **Start with cached context**
   - Use `model_context` for the relevant model/scope.
   - Use `model_read` on the smallest known scope containing the signal.

3. **Resolve bus contracts**
   Use `model_query_params` for:
   - Bus Selector `OutputSignals`
   - Bus Assignment `AssignedSignals`
   - In Bus Element / Out Bus Element names
   - Goto/From tags if relevant

4. **Trace across boundaries**
   Check:
   - subsystem Inport/Outport names
   - Model Reference / Subsystem Reference interfaces
   - Goto/From pairs
   - bus element names
   - BICO/metabus/logging adapters
   - harness input/output mappings

5. **Produce a readable path**

   Use a trace chain, not a raw block list:

   ```text
   source block.signal
     -> bus assignment element
     -> subsystem output
     -> referenced model input
     -> Bus Selector element
     -> output/log/alarm block
   ```

## Output Format

```markdown
## Signal trace: <signal>

Direction: source-to-sink / sink-to-source
Scope: <model/subsystem>

### Trace chain
1. ...
2. ...
3. ...

### Important bus mappings
| Bus/block | Element | Direction |
|---|---|---|

### Interpretation
...

### Unresolved gaps
- binary S-Function / external library / missing compiled info, if any
```

## Guardrails

- Do not dump every connection in a large model.
- Do not claim source-level behavior for binary S-Functions.
- If bus element ownership is ambiguous, state the ambiguity and suggest the next targeted query.
- Prefer named signals and bus elements over block IDs in final explanations; include block IDs only as provenance.

----

Copyright 2026 The MathWorks, Inc.
