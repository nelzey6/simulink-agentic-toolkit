function out = modelContext(req)
%MODELCONTEXT Build or query one complete compile-free structural snapshot.
policy = validatestring(char(req.cachePolicy), {'use-if-fresh','cache-only','force-refresh'});
[modelFile, modelName] = resolveModelIdentity(req.model);
projectRoot = findProjectRootFromModel(modelFile);
cacheRoot = fullfile(projectRoot, '.satk', 'model-cache', modelName);
snapshotPath = fullfile(cacheRoot, 'snapshot.json');

snapshot = struct();
state = 'missing';
if isfile(snapshotPath)
    try
        snapshot = jsondecode(fileread(snapshotPath));
        if isfield(snapshot,'schemaVersion') && snapshot.schemaVersion == 2
            if snapshotIsFresh(snapshot, modelName)
                state = 'fresh';
            else
                state = 'stale';
            end
        else
            state = 'stale';
        end
    catch
        state = 'stale';
    end
end

if strcmp(policy,'cache-only') && ~strcmp(state,'fresh')
    error('SATKCACHE:CacheMissOrStale', ...
        'No fresh structural snapshot exists for %s. Run model_context with use-if-fresh first.', modelName);
end

if strcmp(state,'fresh') && ~strcmp(policy,'force-refresh')
    source = 'cache';
else
    snapshot = buildSnapshot(modelFile, modelName, projectRoot);
    writeSnapshot(snapshotPath, snapshot);
    cleanupLegacyCache(cacheRoot);
    source = 'live+cache_update';
    state = 'fresh';
end

[candidates, resolvedScope] = resolveScope(req.task, req.scope, snapshot);
context = contextSlice(snapshot, resolvedScope);

out = struct();
out.schemaVersion = 2;
out.tool = 'model_context';
out.source = source;
out.coverage = 'structural-compile-free';
out.task = char(req.task);
out.model = snapshot.model.path;
out.modelName = snapshot.model.name;
out.resolvedScope = resolvedScope;
out.candidateScopes = candidates;
out.context = context;
out.cache = struct('path',snapshotPath,'state',state,'builtAt',snapshot.builtAt, ...
    'blockCount',numel(snapshot.blocks),'connectionCount',numel(snapshot.connections));
out.nextActions = nextActions(resolvedScope, snapshot.model.path);
end

function snapshot = buildSnapshot(modelFile, modelName, projectRoot)
wasLoaded = bdIsLoaded(modelName);
if ~wasLoaded
    load_system(modelFile);
end
ownedModel = onCleanup(@() closeIfOwned(modelName, wasLoaded));

blocks = find_system(modelName, 'Type', 'Block');
blockTemplate = struct('name','','path','','parent','','sid','','blockType','', ...
    'referenceBlock','','linkStatus','','maskType','','ports','','portNames',emptyPortNames());
blockRecords = repmat(blockTemplate, 0, 1);
for i = 1:numel(blocks)
    b = blocks{i};
    item = blockTemplate;
    item.name = safeGet(b,'Name');
    item.path = b;
    item.parent = safeGet(b,'Parent');
    item.sid = safeSID(b);
    item.blockType = safeGet(b,'BlockType');
    item.referenceBlock = safeGet(b,'ReferenceBlock');
    item.linkStatus = safeGet(b,'LinkStatus');
    item.maskType = safeGet(b,'MaskType');
    item.ports = safeGet(b,'Ports');
    item.portNames = blockPortNames(b);
    blockRecords(end+1,1) = item; %#ok<AGROW>
end

lineHandles = find_system(modelName, 'FindAll','on', 'Type','line');
connectionTemplate = struct('srcBlock','','srcPort',NaN,'dstBlock','','dstPort',NaN,'name','');
connections = repmat(connectionTemplate, 0, 1);
for i = 1:numel(lineHandles)
    lh = lineHandles(i);
    srcBlock = safeHandlePath(safeLineParam(lh,'SrcBlockHandle'));
    srcPort = safePortNumber(safeLineParam(lh,'SrcPortHandle'));
    dstBlocks = safeLineParam(lh,'DstBlockHandle');
    dstPorts = safeLineParam(lh,'DstPortHandle');
    for j = 1:numel(dstBlocks)
        item = connectionTemplate;
        item.srcBlock = srcBlock;
        item.srcPort = srcPort;
        item.dstBlock = safeHandlePath(dstBlocks(j));
        if numel(dstPorts) >= j, item.dstPort = safePortNumber(dstPorts(j)); end
        item.name = safeGet(lh,'Name');
        connections(end+1,1) = item; %#ok<AGROW>
    end
end

dependencyPaths = discoverDependencies(modelFile, modelName, projectRoot, blockRecords);
snapshot = struct();
snapshot.schemaVersion = 2;
snapshot.coverage = 'structural-compile-free';
snapshot.builtAt = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
snapshot.matlabRelease = version('-release');
snapshot.model = struct('name',modelName,'path',modelFile);
snapshot.dependencies = fileMetadata(dependencyPaths);
snapshot.dirtyChecksum = currentDirtyChecksum(modelName);
snapshot.blocks = blockRecords;
snapshot.connections = connections;

clear ownedModel;
end

function tf = snapshotIsFresh(snapshot, modelName)
tf = isfield(snapshot,'dependencies') && metadataIsFresh(snapshot.dependencies);
if ~tf || ~bdIsLoaded(modelName), return; end
try
    if strcmp(get_param(modelName,'Dirty'),'on')
        checksum = currentDirtyChecksum(modelName);
        tf = isfield(snapshot,'dirtyChecksum') && strcmp(char(snapshot.dirtyChecksum), checksum);
    elseif isfield(snapshot,'dirtyChecksum') && strlength(string(snapshot.dirtyChecksum)) > 0
        tf = false;
    end
catch
    tf = false;
end
end

function checksum = currentDirtyChecksum(modelName)
checksum = '';
try
    if bdIsLoaded(modelName) && strcmp(get_param(modelName,'Dirty'),'on')
        checksum = jsonencode(Simulink.BlockDiagram.getChecksum(modelName));
    end
catch
end
end

function deps = discoverDependencies(modelFile, modelName, projectRoot, blocks)
paths = {modelFile};
startup = fullfile(projectRoot,'matlab','startup.m');
if isfile(startup), paths{end+1} = startup; end

try
    dictionary = char(get_param(modelName,'DataDictionary'));
    if ~isempty(dictionary)
        resolved = resolveDependency(dictionary, fileparts(modelFile), projectRoot);
        if ~isempty(resolved), paths{end+1} = resolved; end
    end
catch
end

projectDictionaries = dir(fullfile(projectRoot,'**','*.sldd'));
for i = 1:numel(projectDictionaries)
    paths{end+1} = fullfile(projectDictionaries(i).folder,projectDictionaries(i).name); %#ok<AGROW>
end

try
    refs = find_mdlrefs(modelName, 'AllLevels', true, 'KeepModelsLoaded', false);
    for i = 1:numel(refs)
        resolved = resolveDependency(char(refs{i}), fileparts(modelFile), projectRoot);
        if ~isempty(resolved), paths{end+1} = resolved; end %#ok<AGROW>
    end
catch
end

for i = 1:numel(blocks)
    ref = char(blocks(i).referenceBlock);
    if isempty(ref), continue; end
    libraryName = strtok(ref, '/');
    resolved = which([libraryName '.slx']);
    if isempty(resolved), resolved = which([libraryName '.mdl']); end
    if ~isempty(resolved) && ~startsWith(resolved, matlabroot)
        paths{end+1} = resolved; %#ok<AGROW>
    end
end
deps = unique(paths, 'stable');
end

function resolved = resolveDependency(value, modelFolder, projectRoot)
resolved = '';
candidates = {value, fullfile(modelFolder,value), fullfile(projectRoot,value)};
[~,~,ext] = fileparts(value);
if isempty(ext), candidates = [candidates, {[value '.slx'], fullfile(modelFolder,[value '.slx'])}]; end
for i = 1:numel(candidates)
    if isfile(candidates{i})
        resolved = canonicalPath(candidates{i});
        return;
    end
    hit = which(candidates{i});
    if ~isempty(hit), resolved = canonicalPath(hit); return; end
end
end

function records = fileMetadata(paths)
template = struct('path','','bytes',0,'modified',0);
records = repmat(template, 0, 1);
for i = 1:numel(paths)
    p = canonicalPath(paths{i});
    d = dir(p);
    if isempty(d), continue; end
    records(end+1,1) = struct('path',p,'bytes',double(d.bytes),'modified',double(d.datenum)); %#ok<AGROW>
end
end

function tf = metadataIsFresh(records)
tf = true;
for i = 1:numel(records)
    d = dir(char(records(i).path));
    if isempty(d) || double(d.bytes) ~= double(records(i).bytes) || double(d.datenum) ~= double(records(i).modified)
        tf = false;
        return;
    end
end
end

function [candidates, scope] = resolveScope(task, requestedScope, snapshot)
template = struct('path','','sid','','name','','blockType','','reason','');
candidates = repmat(template,0,1);
requestedScope = char(requestedScope);
if ~strcmpi(requestedScope,'auto') && ~isempty(requestedScope)
    if strcmpi(requestedScope,'root'), requestedScope = snapshot.model.name; end
    if strcmp(requestedScope,snapshot.model.name)
        root = struct('path',snapshot.model.name,'sid','','name',snapshot.model.name,'blockType','block_diagram');
        candidates(1) = candidate(root,'explicit scope');
        scope = requestedScope;
        return;
    end
    idx = find(strcmp({snapshot.blocks.path},requestedScope),1);
    if isempty(idx)
        error('SATKCACHE:ScopeNotFound','Scope not present in cached snapshot: %s',requestedScope);
    end
    candidates(1) = candidate(snapshot.blocks(idx),'explicit scope');
    scope = requestedScope;
    return;
end

words = meaningfulWords(task);
for pass = 1:2
    for i = 1:numel(snapshot.blocks)
        b = snapshot.blocks(i);
        name = lower(strtrim(char(b.name)));
        path = lower(char(b.path));
        reason = '';
        if pass == 1 && strlength(name) >= 3 && any(strcmp(words,name))
            reason = 'exact block-name token mentioned in task';
        elseif pass == 2
            for k = 1:numel(words)
                if strlength(words{k}) >= 4 && (contains(name,words{k}) || contains(path,words{k}))
                    reason = ['partial match: ' words{k}];
                    break;
                end
            end
        end
        if ~isempty(reason), candidates(end+1,1) = candidate(b,reason); end %#ok<AGROW>
        if numel(candidates) >= 10, break; end
    end
    if ~isempty(candidates), break; end
end
if isempty(candidates)
    root = struct('path',snapshot.model.name,'sid','','name',snapshot.model.name,'blockType','block_diagram');
    candidates(1) = candidate(root,'fallback to root');
end
scope = candidates(1).path;
end

function item = candidate(block, reason)
item = struct('path',char(block.path),'sid',char(block.sid),'name',char(block.name), ...
    'blockType',char(block.blockType),'reason',reason);
end

function words = meaningfulWords(task)
words = regexp(lower(char(task)), '[a-zA-Z0-9_]+', 'match');
stop = {'the','and','or','not','with','from','into','this','that','model','simulink','logic', ...
    'change','edit','context','only','want','need','use','using','get','inspect','describe','block'};
words = setdiff(words, stop, 'stable');
end

function context = contextSlice(snapshot, scope)
paths = {snapshot.blocks.path};
parents = {snapshot.blocks.parent};
selected = find(strcmp(paths,scope),1);
children = find(strcmp(parents,scope));
indices = children;
if isempty(indices) && ~isempty(selected), indices = selected; end
indices = indices(1:min(numel(indices),25));
blocks = snapshot.blocks(indices);

connectionIndices = [];
visiblePaths = [{scope}, {blocks.path}];
for i = 1:numel(snapshot.connections)
    c = snapshot.connections(i);
    if any(strcmp(visiblePaths,char(c.srcBlock))) || any(strcmp(visiblePaths,char(c.dstBlock)))
        connectionIndices(end+1) = i; %#ok<AGROW>
    end
    if numel(connectionIndices) >= 40, break; end
end

typeCounts = struct();
for i = 1:numel(blocks)
    name = matlab.lang.makeValidName(char(blocks(i).blockType));
    if isempty(name), name = 'Unknown'; end
    if isfield(typeCounts,name), typeCounts.(name) = typeCounts.(name)+1; else, typeCounts.(name)=1; end
end
context = struct('scope',scope,'summary',struct('returnedBlocks',numel(blocks), ...
    'totalSnapshotBlocks',numel(snapshot.blocks),'blockTypes',typeCounts), ...
    'blocks',blocks,'connections',snapshot.connections(connectionIndices), ...
    'truncated',struct('blocks',numel(children)>25,'connections',numel(connectionIndices)>=40));
end

function actions = nextActions(scope, model)
actions = repmat(struct('tool','','args',struct(),'reason',''),0,1);
actions(end+1) = struct('tool','model_read','args',struct('model',model,'scope',scope,'depth','0'), ...
    'reason','Get current block IDs and algorithmic expressions before editing.');
actions(end+1) = struct('tool','model_query_params','args',struct('model',model,'targets',['["' scope '"]'], ...
    'params','["all"]','compile','false'),'reason','Resolve parameters only when the task requires values.');
end

function [modelFile, modelName] = resolveModelIdentity(input)
input = char(input);
if strcmpi(input,'auto')
    loaded = find_system('type','block_diagram');
    loaded = loaded(~strcmp(loaded,'simulink'));
    if ~isempty(loaded), input = loaded{1}; else
        hits = dir(fullfile(pwd,'**','*.slx'));
        if isempty(hits), error('SATKCACHE:ModelAutoNotFound','No loaded model or .slx file found.'); end
        input = fullfile(hits(1).folder,hits(1).name);
    end
end
[~, modelName, ext] = fileparts(input);
if isempty(modelName), modelName = input; end
modelFile = '';
if bdIsLoaded(modelName)
    modelFile = get_param(modelName,'FileName');
end
if isempty(modelFile) && isfile(input), modelFile = input; end
if isempty(modelFile)
    candidate = input;
    if isempty(ext), candidate = [input '.slx']; end
    modelFile = which(candidate);
end
if isempty(modelFile)
    error('SATKCACHE:ModelNotFound','Could not resolve model: %s',input);
end
modelFile = canonicalPath(modelFile);
[~, modelName] = fileparts(modelFile);
end

function root = findProjectRootFromModel(modelFile)
root = fileparts(modelFile);
while true
    if isfolder(fullfile(root,'.git')) || ~isempty(dir(fullfile(root,'*.prj'))) || ...
            isfile(fullfile(root,'MATLAB.md')) || isfile(fullfile(root,'mcp.md'))
        return;
    end
    parent = fileparts(root);
    if isempty(parent) || strcmp(parent,root), return; end
    root = parent;
end
end

function writeSnapshot(path, snapshot)
folder = fileparts(path);
if ~isfolder(folder), mkdir(folder); end
temporary = [tempname(folder) '.json'];
fid = fopen(temporary,'w');
if fid < 0, error('SATKCACHE:CacheWriteFailed','Could not open temporary cache file.'); end
cleanup = onCleanup(@() closeFile(fid));
fwrite(fid,jsonencode(snapshot,PrettyPrint=true));
fclose(fid);
clear cleanup;
[ok,msg] = movefile(temporary,path,'f');
if ~ok, error('SATKCACHE:CacheWriteFailed','Could not publish snapshot: %s',msg); end
end

function closeFile(fid)
if fid >= 0
    try fclose(fid); catch, end
end
end

function closeIfOwned(modelName, wasLoaded)
if ~wasLoaded && bdIsLoaded(modelName)
    close_system(modelName,0);
end
end

function cleanupLegacyCache(cacheRoot)
legacyFiles = {fullfile(cacheRoot,'manifest.json')};
for i=1:numel(legacyFiles), if isfile(legacyFiles{i}), delete(legacyFiles{i}); end, end
items = dir(cacheRoot);
for i=1:numel(items)
    if items(i).isdir && ~ismember(items(i).name,{'.','..'})
        rmdir(fullfile(items(i).folder,items(i).name),'s');
    end
end
end

function names = blockPortNames(block)
names = emptyPortNames();
try
    ph = get_param(block,'PortHandles');
    names.inputs = portNames(ph.Inport);
    names.outputs = portNames(ph.Outport);
catch
end
end

function value = emptyPortNames()
value = struct('inputs',{{}},'outputs',{{}});
end

function names = portNames(handles)
names = cell(1,numel(handles));
for i=1:numel(handles), names{i}=safeGet(handles(i),'Name'); end
end

function value = safeGet(object,param)
try value = get_param(object,param); catch, value = ''; end
if isnumeric(value) || islogical(value), value = mat2str(value); end
if isstring(value), value = char(value); end
end

function value = safeSID(block)
try value = Simulink.ID.getSID(block); catch, value = ''; end
end

function value = safeLineParam(line,param)
try value = get_param(line,param); catch, value = []; end
end

function path = safeHandlePath(handle)
path = '';
try
    if ~isempty(handle) && handle ~= -1, path = getfullname(handle); end
catch
end
end

function number = safePortNumber(handle)
number = NaN;
try
    if ~isempty(handle) && handle ~= -1, number = str2double(get_param(handle,'PortNumber')); end
catch
end
end

function path = canonicalPath(path)
path = char(java.io.File(path).getCanonicalPath());
end
