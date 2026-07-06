function out = analyze(req)
if ~isfield(req,'detail') && isfield(req,'analysis')
    req.detail = satkcache.firstRequested(req.analysis, 'summary');
end
policy = string(req.cachePolicy);
if policy ~= "do-not-cache" && policy ~= "force-refresh"
    s = satkcache.status(req);
    if isfield(s,'cacheExists') && s.cacheExists && ~s.isStale
        out = satkcache.get(req); out.source = 'cache'; return;
    elseif policy == "cache-only"
        out = s; out.error = 'CACHE_MISS_OR_STALE'; return;
    end
end
if policy == "cache-only"
    out = struct('error','CACHE_MISS_OR_STALE'); return;
end
out = satkcache.update(req);
end
