function out = update(req)
if ~isfield(req,'detail')
    if isfield(req,'analysis'), req.detail = satkcache.firstRequested(req.analysis, 'summary');
    else, req.detail = 'summary'; end
end
ctx = satkcache.context(req.model, req.scope, req.detail);
if ~exist(ctx.recordDir,'dir'), mkdir(ctx.recordDir); end
s = satkcache.status(req);
if isfield(req,'force') && ~req.force && s.cacheExists && ~s.isStale
    out = satkcache.get(req); return;
end
satkcache.ensureLoaded(ctx.modelFile);
record = satkcache.makeRecord(ctx, req);
json = jsonencode(record, PrettyPrint=true);
fid = fopen(ctx.recordPath,'w'); fwrite(fid,json); fclose(fid);
satkcache.writeManifest(ctx, record);
out = record; out.source = 'live+cache_update';
end
