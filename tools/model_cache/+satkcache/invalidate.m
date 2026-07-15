function out = invalidate(req)
[modelFile, modelName] = resolveIdentity(req.model);
root = findRoot(modelFile);
snapshotPath = fullfile(root,'.satk','model-cache',modelName,'snapshot.json');
removed = false;
if isfile(snapshotPath)
    try
        delete(snapshotPath);
        removed = true;
    catch ME
        error('SATKCACHE:InvalidateFailed','Could not remove snapshot %s: %s',snapshotPath,ME.message);
    end
end
out = struct('status','ok','model',modelFile,'snapshot',snapshotPath,'removed',removed);
end

function [file,name] = resolveIdentity(input)
input = char(input);
if strcmpi(input,'auto')
    loaded = find_system('type','block_diagram'); loaded = loaded(~strcmp(loaded,'simulink'));
    if isempty(loaded), error('SATKCACHE:ModelAutoNotFound','No loaded model available for invalidation.'); end
    input = loaded{1};
end
[~,name,ext] = fileparts(input); if isempty(name), name=input; end
file = '';
if bdIsLoaded(name), file=get_param(name,'FileName'); end
if isempty(file) && isfile(input), file=input; end
if isempty(file), if isempty(ext), input=[input '.slx']; end, file=which(input); end
if isempty(file), error('SATKCACHE:ModelNotFound','Could not resolve model: %s',input); end
file=char(java.io.File(file).getCanonicalPath()); [~,name]=fileparts(file);
end

function root = findRoot(file)
root=fileparts(file);
while true
    if isfolder(fullfile(root,'.git')) || ~isempty(dir(fullfile(root,'*.prj'))) || isfile(fullfile(root,'MATLAB.md')) || isfile(fullfile(root,'mcp.md')), return; end
    parent=fileparts(root); if isempty(parent)||strcmp(parent,root), return; end, root=parent;
end
end
