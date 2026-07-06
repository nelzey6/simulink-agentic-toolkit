function out = status(req)
ctx = satkcache.context(req.model, req.scope, req.detail);
fp = satkcache.fingerprint(ctx);
out = struct('model', ctx.modelFile, 'scope', req.scope, 'detail', req.detail, 'cacheExists', isfile(ctx.recordPath), 'isStale', true, 'cachePath', ctx.recordPath, 'fingerprint', fp);
if out.cacheExists
    rec = jsondecode(fileread(ctx.recordPath));
    out.lastAnalyzed = rec.updatedAt;
    out.isStale = ~isequaln(rec.fingerprint, fp);
end
end
