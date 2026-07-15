function out = harness_create(model, component, harness_name, save_externally, harness_path, source, sink, create_without_compile)
%HARNESS_CREATE Create a Simulink Test harness.
if nargin < 4 || strlength(string(save_externally)) == 0, save_externally = 'true'; end
if nargin < 5, harness_path = ''; end
if nargin < 6 || strlength(string(source)) == 0, source = 'Inport'; end
if nargin < 7 || strlength(string(sink)) == 0, sink = 'Outport'; end
if nargin < 8 || strlength(string(create_without_compile)) == 0, create_without_compile = 'true'; end
model = char(string(model)); component = char(string(component)); harness_name = char(string(harness_name));
if ~isempty(model), ensureLoaded(model); end
args = {'Name', harness_name, 'Source', char(string(source)), 'Sink', char(string(sink)), ...
    'SaveExternally', satkrepo.str2logical(save_externally,true), 'CreateWithoutCompile', satkrepo.str2logical(create_without_compile,true)};
if strlength(string(harness_path)) > 0
    hp = char(string(harness_path));
    folder = fileparts(hp); if ~isempty(folder) && ~exist(folder,'dir'), mkdir(folder); end
    args = [args {'HarnessPath', hp}];
end
result = sltest.harness.create(component, args{:});
out = struct('status','created','model',model,'component',component,'harness_name',harness_name,'result',satkrepo.structify(result));
try, model_cache_invalidate(model, 'root'); catch, end
end
function ensureLoaded(model), [~,n,e]=fileparts(model); if isempty(e), model=[model '.slx']; end, if ~bdIsLoaded(n), open_system(model); end, end
