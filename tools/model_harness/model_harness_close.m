function out = model_harness_close(model, component, harness_name, save_before_close)
%MODEL_HARNESS_CLOSE Close an open Simulink Test harness.
if nargin < 4 || strlength(string(save_before_close)) == 0, save_before_close = 'true'; end
model = char(string(model)); component = char(string(component)); harness_name = char(string(harness_name));
if satkproject.str2logical(save_before_close,true)
    try, sltest.harness.save(component, harness_name); catch, end
end
sltest.harness.close(component, harness_name);
out = struct('status','closed','model',model,'component',component,'harness_name',harness_name);
end
