function out = model_cache_status(model, scope, detail)
%MODEL_CACHE_STATUS Report whether a scoped Simulink analysis cache record exists and is fresh.
if nargin < 2 || strlength(string(scope)) == 0, scope = "root"; end
if nargin < 3 || strlength(string(detail)) == 0, detail = "summary"; end
req = struct('model', char(model), 'scope', char(scope), 'detail', char(detail), 'depth', '1', 'compile', false);
out = satkcache.status(req);
end
