function path = resolveBlkAlias(alias, modelName)
path = '';
if ~startsWith(alias,'blk_'), return; end
n = extractAfter(alias,'blk_');
try
    path = Simulink.ID.getFullName([modelName ':' char(n)]);
catch
    path = '';
end
end
