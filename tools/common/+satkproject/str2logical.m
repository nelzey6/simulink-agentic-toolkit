function tf = str2logical(v, defaultValue)
%STR2LOGICAL Convert string/logical/numeric values used by MCP schemas.
if nargin < 2, defaultValue = false; end
if isempty(v), tf = defaultValue; return; end
if islogical(v), tf = v; return; end
if isnumeric(v), tf = v ~= 0; return; end
s = lower(strtrim(char(string(v))));
tf = any(strcmp(s, {'true','1','yes','on'}));
if ~tf && ~any(strcmp(s, {'false','0','no','off'}))
    tf = defaultValue;
end
end
