function out = harness_save(model, component, harness_name)
%HARNESS_SAVE Save an open Simulink Test harness.
model = char(string(model)); component = char(string(component)); harness_name = char(string(harness_name));
sltest.harness.save(component, harness_name);
out = struct('status','saved','model',model,'component',component,'harness_name',harness_name);
try, model_cache_invalidate(harness_name, 'root'); catch, end
end
