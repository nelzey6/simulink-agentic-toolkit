function out = model_harness_open(model, component, harness_name)
%MODEL_HARNESS_OPEN Open an existing Simulink Test harness for editing.
satkproject.requireSimulinkTest('model_harness_open');
model = char(string(model)); component = char(string(component)); harness_name = char(string(harness_name));
ensureLoaded(model);
try
    sltest.harness.open(component, harness_name);
catch ME
    error('model_harness_open:OpenFailed', 'Failed to open harness %s for %s: %s', harness_name, component, ME.message);
end
out = struct('status','opened','model',model,'component',component,'harness_name',harness_name,'harness_model',harness_name);
end
function ensureLoaded(model)
[~,n,e]=fileparts(model); if isempty(e), model=[model '.slx']; end
if ~bdIsLoaded(n)
    try
        open_system(model);
    catch ME
        error('model_harness_open:ModelLoadFailed', 'Failed to open model %s: %s', model, ME.message);
    end
end
end
