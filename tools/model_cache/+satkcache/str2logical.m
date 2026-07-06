function tf = str2logical(v)
if islogical(v), tf = v; return; end
s = strtrim(char(string(v)));
tf = any(strcmpi(s, {'true','1','yes','on'}));
end
