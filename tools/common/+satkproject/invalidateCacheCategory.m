function invalidateCacheCategory(root, category)
%INVALIDATECACHECATEGORY Best-effort deletion of a model-project cache category.
if nargin < 1 || isempty(root), root = pwd; end
if nargin < 2 || isempty(category), category = '*'; end
folder = fullfile(char(string(root)), '.satk', 'model-project-cache', char(string(category)));
try
    if isfolder(folder)
        delete(fullfile(folder, '*.json'));
    elseif contains(folder, '*')
        delete(fullfile(folder, '*.json'));
    end
catch
end
end
