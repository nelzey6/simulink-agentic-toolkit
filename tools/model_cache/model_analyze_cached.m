function out = model_analyze_cached(model, scope, checks, cachePolicy)
%MODEL_ANALYZE_CACHED Cache-first, compile-off scoped Simulink analysis.
if nargin < 2 || strlength(string(scope)) == 0, scope = "root"; end
if nargin < 3 || strlength(string(checks)) == 0, checks = '["summary"]'; end
if nargin < 4 || strlength(string(cachePolicy)) == 0, cachePolicy = 'use-if-fresh'; end
req = struct('model', char(model), 'scope', char(scope), 'analysis', char(checks), 'cachePolicy', char(cachePolicy), 'depth', '1', 'compile', false);
out = satkcache.analyze(req);
end
