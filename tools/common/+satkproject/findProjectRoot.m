function root = findProjectRoot(startPath)
%FINDPROJECTROOT Find nearest project/repo root from a file or folder.
if nargin < 1 || strlength(string(startPath)) == 0
    startPath = pwd;
end
startPath = char(string(startPath));
if isfile(startPath)
    root = fileparts(startPath);
else
    root = startPath;
end
try
    root = char(java.io.File(root).getCanonicalPath());
catch
end
markers = {'.git', '.prj', 'matlab', '.satk'};
while true
    for i = 1:numel(markers)
        if exist(fullfile(root, markers{i}), 'dir') || ~isempty(dir(fullfile(root, ['*' markers{i}]))) %#ok<*ISMT>
            return;
        end
    end
    parent = fileparts(root);
    if isempty(parent) || strcmp(parent, root)
        return;
    end
    root = parent;
end
end
