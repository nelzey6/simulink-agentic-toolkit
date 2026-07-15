function out = model_context(task, model, scope, cachePolicy)
%MODEL_CONTEXT Return compact cache-first Simulink working context for an engineering task.
if nargin < 1, task = ''; end
if nargin < 2 || strlength(string(model)) == 0, model = 'auto'; end
if nargin < 3 || strlength(string(scope)) == 0, scope = 'auto'; end
if nargin < 4 || strlength(string(cachePolicy)) == 0, cachePolicy = 'use-if-fresh'; end
req = struct('task',char(task),'model',char(model),'scope',char(scope),'cachePolicy',char(cachePolicy));
out = satkcache.modelContext(req);
end
