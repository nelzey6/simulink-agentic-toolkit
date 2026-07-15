function out = cacheFreshness(reqs)
%CACHEFRESHNESS Return compact freshness state for one or more cache requests.
if ~iscell(reqs), reqs = {reqs}; end
out = repmat(struct('detail','','exists',false,'stale',true,'state','missing','path',''), 0, 1);
for i = 1:numel(reqs)
    s = satkcache.status(reqs{i});
    state = 'missing';
    if isfield(s,'cacheExists') && s.cacheExists
        if isfield(s,'isStale') && s.isStale
            state = 'stale';
        else
            state = 'fresh';
        end
    end
    out(end+1,1) = struct('detail',char(reqs{i}.detail),'exists',logical(s.cacheExists), ...
        'stale',logical(s.isStale),'state',state,'path',s.cachePath); %#ok<AGROW>
end
end
