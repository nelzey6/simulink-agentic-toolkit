function items = jsonList(value)
%JSONLIST Decode MCP JSON array string. Empty/missing -> {}.
if nargin < 1 || isempty(value) || strlength(string(value)) == 0
    items = {};
    return;
end
if iscell(value)
    items = value;
    return;
end
if isstring(value) && numel(value) > 1
    items = cellstr(value);
    return;
end
s = char(string(value));
try
    decoded = jsondecode(s);
catch
    if isempty(strtrim(s))
        decoded = {};
    else
        decoded = {s};
    end
end
if iscell(decoded)
    items = decoded(:).';
elseif isstring(decoded)
    items = cellstr(decoded(:)).';
elseif ischar(decoded)
    items = {decoded};
else
    items = num2cell(decoded(:).');
end
end
