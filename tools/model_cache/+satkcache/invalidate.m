function out = invalidate(req)
ctx = satkcache.context(req.model, req.scope, 'summary');
removed = {};
if isfolder(ctx.recordDir)
    files = dir(fullfile(ctx.recordDir,'*.json'));
    for i=1:numel(files)
        p = fullfile(files(i).folder, files(i).name);
        delete(p); removed{end+1} = p; %#ok<AGROW>
    end
end
idx = fullfile(ctx.cacheRoot,'indexes','blocks.json');
if isfile(idx)
    delete(idx); removed{end+1} = idx;
end
manifest = fullfile(ctx.cacheRoot,'manifest.json');
if isfile(manifest)
    delete(manifest); removed{end+1} = manifest;
end
out = struct('status','ok','model',ctx.modelFile,'scope',req.scope,'removed',{removed},'message','Cache records for scope and block index invalidated. Next model_context call will refresh lazily.');
end
