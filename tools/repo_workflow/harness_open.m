function out = harness_open(model, component, harness_name)
%HARNESS_OPEN Open an existing Simulink Test harness for editing.
model = char(string(model)); component = char(string(component)); harness_name = char(string(harness_name));
ensureLoaded(model);
sltest.harness.open(component, harness_name);
out = struct('status','opened','model',model,'component',component,'harness_name',harness_name,'harness_model',harness_name);
end
function ensureLoaded(model), [~,n,e]=fileparts(model); if isempty(e), model=[model '.slx']; end, if ~bdIsLoaded(n), open_system(model); end, end
