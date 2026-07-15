function out = harness_list(model, component, searchDepth, cachePolicy)
%HARNESS_LIST List Simulink Test harnesses for a model/component.
if nargin < 2 || strlength(string(component)) == 0, component = 'auto'; end
if nargin < 3 || strlength(string(searchDepth)) == 0, searchDepth = 'all'; end
if nargin < 4 || strlength(string(cachePolicy)) == 0, cachePolicy = 'use-if-fresh'; end
model = char(string(model));
component = char(string(component));
if strcmpi(component, 'auto') || isempty(component)
    owner = erase(model, '.slx');
else
    owner = component;
end
ensureLoaded(model);
fingerprint = struct('model', model, 'owner', owner, 'modelHash', modelHash(model), 'searchDepth', char(string(searchDepth)));
repo = localRoot(model);
cp = satkrepo.cachePath(repo, 'harness', ['harness_list_' regexprep(owner,'[^A-Za-z0-9_.-]','_')]);
[hit, payload] = satkrepo.cacheRead(cp, fingerprint, cachePolicy);
if hit, out = payload; out.cache = cacheInfo('hit', cp, cachePolicy); return; end
if strcmp(char(cachePolicy), 'cache-only'), error('harness_list:CacheMiss','No fresh harness list cache.'); end
try
    if strcmpi(char(string(searchDepth)), 'all')
        h = sltest.harness.find(owner);
    else
        h = sltest.harness.find(owner, 'SearchDepth', str2double(searchDepth));
    end
catch ME
    error('harness_list:FindFailed', 'Failed to list harnesses for %s: %s', owner, ME.message);
end
items = cell(0,1);
for i = 1:numel(h)
    item = satkrepo.structify(h(i));
    item = normalizeHarnessItem(item);
    items{end+1,1} = item; %#ok<AGROW>
end
out = struct('status','ok','model',model,'component',owner,'count',numel(items),'harnesses',{items});
out.cache = cacheInfo('miss', cp, cachePolicy);
satkrepo.cacheWrite(cp, fingerprint, rmfield(out,'cache'), cachePolicy);
end

function item = normalizeHarnessItem(item)
fn = fieldnames(item);
for k = 1:numel(fn)
    if isstring(item.(fn{k})), item.(fn{k}) = char(item.(fn{k})); end
end
if isfield(item,'name') && ~isfield(item,'Name'), item.Name = item.name; end
if isfield(item,'Name') && ~isfield(item,'name'), item.name = item.Name; end
if isfield(item,'ownerFullPath') && ~isfield(item,'owner'), item.owner = item.ownerFullPath; end
if isfield(item,'harnessPath') && ~isfield(item,'file'), item.file = item.harnessPath; end
end

function ensureLoaded(model)
[~, name, ext] = fileparts(model);
if isempty(ext), modelFile = [model '.slx']; else, modelFile = model; end
try
    if ~bdIsLoaded(name), open_system(modelFile); end
catch
    try open_system(modelFile); catch, end
end
end
function h = modelHash(model)
[~, name, ext] = fileparts(model); if isempty(ext), ext = '.slx'; end
p = which([name ext]); if isempty(p) && isfile(model), p = model; end
h = satkrepo.fileHash(p);
end
function root = localRoot(~)
root = pwd;
end
function c = cacheInfo(status,path,policy), c=struct('status',status,'path',path,'policy',char(string(policy))); end
