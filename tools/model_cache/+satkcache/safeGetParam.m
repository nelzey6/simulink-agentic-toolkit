function v = safeGetParam(obj, param)
try
    v = get_param(obj,param);
catch
    v = '';
end
if isnumeric(v) || islogical(v), v = mat2str(v); end
end
