function out = get(req)
ctx = satkcache.context(req.model, req.scope, req.detail);
if ~isfile(ctx.recordPath)
    out = struct('error','CACHE_RECORD_NOT_FOUND','cachePath',ctx.recordPath); return;
end
out = jsondecode(fileread(ctx.recordPath));
out.source = 'cache';
end
