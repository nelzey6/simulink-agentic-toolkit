function obj = jsonObject(value)
%JSONOBJECT Decode MCP JSON object string. Empty/missing -> struct().
if nargin < 1 || isempty(value) || strlength(string(value)) == 0
    obj = struct();
    return;
end
if isstruct(value)
    obj = value;
    return;
end
try
    obj = jsondecode(char(string(value)));
catch ME
    error('satkproject:InvalidJsonObject', 'Expected JSON object string: %s', ME.message);
end
if ~isstruct(obj)
    error('satkproject:InvalidJsonObject', 'Expected JSON object string.');
end
end
