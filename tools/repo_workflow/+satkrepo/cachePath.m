function path = cachePath(root, category, key)
%CACHEPATH Project-local SATK repo workflow cache path.
root = char(string(root));
category = regexprep(char(string(category)), '[^A-Za-z0-9_.-]', '_');
key = regexprep(char(string(key)), '[^A-Za-z0-9_.-]', '_');
folder = fullfile(root, '.satk', 'repo-cache', category);
if ~exist(folder, 'dir'), mkdir(folder); end
path = fullfile(folder, [key '.json']);
end
