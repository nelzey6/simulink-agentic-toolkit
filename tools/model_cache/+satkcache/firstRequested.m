function detail = firstRequested(value, defaultValue)
if nargin < 2, defaultValue = 'summary'; end
detail = defaultValue;
try
    decoded = jsondecode(char(value));
    if iscell(decoded) && ~isempty(decoded), detail = char(decoded{1}); return; end
    if isstring(decoded) && ~isempty(decoded), detail = char(decoded(1)); return; end
    if ischar(decoded), detail = decoded; return; end
catch
    s = strtrim(char(string(value)));
    if ~isempty(s), detail = s; end
end
if strcmp(detail,'all'), detail = defaultValue; end
end
