function p = normalizePath(p)
%NORMALIZEPATH Convert to absolute-ish char path without requiring existence.
p = char(string(p));
p = strrep(p, '\', filesep);
p = strrep(p, '/', filesep);
end
