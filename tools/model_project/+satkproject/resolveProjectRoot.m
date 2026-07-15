function repo = resolveProjectRoot(repo)
%RESOLVEPROJECTROOT Resolve project/repo argument or current folder.
if nargin < 1 || strlength(string(repo)) == 0 || strcmpi(char(string(repo)), 'auto')
    repo = pwd;
else
    repo = char(string(repo));
end
repo = char(java.io.File(repo).getCanonicalPath());
end
