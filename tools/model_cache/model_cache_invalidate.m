function out = model_cache_invalidate(model)
%MODEL_CACHE_INVALIDATE Remove the complete structural snapshot for a model.
if nargin < 1 || strlength(string(model)) == 0, model = 'auto'; end
out = satkcache.invalidate(struct('model',char(model)));
end
