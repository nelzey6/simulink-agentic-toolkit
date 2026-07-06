function out = model_cache_update(model, scope, analysis, force)
%MODEL_CACHE_UPDATE Run cheap scoped analysis and update the persistent cache.
if nargin < 2 || strlength(string(scope)) == 0, scope = "root"; end
if nargin < 3 || strlength(string(analysis)) == 0, analysis = '["summary"]'; end
if nargin < 4 || strlength(string(force)) == 0, force = 'false'; end
req = struct('model', char(model), 'scope', char(scope), 'analysis', char(analysis), 'force', satkcache.str2logical(force), 'depth', '1', 'compile', false);
out = satkcache.update(req);
end
