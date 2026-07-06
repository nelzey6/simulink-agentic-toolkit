function out = model_cache_invalidate(model, scope)
%MODEL_CACHE_INVALIDATE Invalidate cached records for a model/scope and block index.
if nargin < 2 || strlength(string(scope)) == 0, scope = 'root'; end
req = struct('model',char(model),'scope',char(scope),'detail','summary');
out = satkcache.invalidate(req);
end
