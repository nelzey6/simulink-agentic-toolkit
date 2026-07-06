function out = model_cache_get(model, scope, detail)
%MODEL_CACHE_GET Return a cached scoped Simulink analysis record without live analysis.
if nargin < 2 || strlength(string(scope)) == 0, scope = "root"; end
if nargin < 3 || strlength(string(detail)) == 0, detail = "summary"; end
req = struct('model', char(model), 'scope', char(scope), 'detail', char(detail), 'depth', '1', 'compile', false);
out = satkcache.get(req);
end
