function params = targetedParams(scope)
params = struct();
if strcmp(scope,'root'), return; end
names = {'BlockType','ReferenceBlock','LinkStatus','MaskType','Ports','Description'};
for i=1:numel(names)
    params.(names{i}) = satkcache.safeGetParam(scope,names{i});
end
end
