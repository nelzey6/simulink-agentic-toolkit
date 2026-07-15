function out = model_harness_save(model, component, harness_name)
%MODEL_HARNESS_SAVE Save an open Simulink Test harness.
satkproject.requireSimulinkTest('model_harness_save');
model = char(string(model)); component = char(string(component)); harness_name = char(string(harness_name));
try
    sltest.harness.save(component, harness_name);
catch ME
    error('model_harness_save:SaveFailed', 'Failed to save harness %s for %s: %s', harness_name, component, ME.message);
end
out = struct('status','saved','model',model,'component',component,'harness_name',harness_name);
try
    model_cache_invalidate(harness_name, 'root');
catch
end
try
    satkproject.invalidateCacheCategory(satkproject.findProjectRoot(pwd), 'harness');
catch
end
end
