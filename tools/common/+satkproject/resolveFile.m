function path = resolveFile(path, requiredExtension)
%RESOLVEFILE Resolve relative/which-able file references and validate existence.
if nargin < 2, requiredExtension = ''; end
path = char(string(path));
if isempty(path)
    error('satkproject:EmptyPath', 'File path must not be empty.');
end
if ~isAbsolutePath(path) && isfile(fullfile(pwd, path))
    path = fullfile(pwd, path);
elseif ~isfile(path)
    candidate = which(path);
    if ~isempty(candidate), path = candidate; end
end
if ~isfile(path)
    error('satkproject:FileNotFound', 'File not found: %s', path);
end
if ~isempty(requiredExtension)
    [~,~,ext] = fileparts(path);
    if ~strcmpi(ext, char(string(requiredExtension)))
        error('satkproject:UnexpectedFileType', 'Expected a %s file, got: %s', char(string(requiredExtension)), path);
    end
end
try
    path = char(java.io.File(path).getCanonicalPath());
catch
end
end

function tf = isAbsolutePath(path)
path = char(string(path));
tf = startsWith(path, filesep) || ~isempty(regexp(path, '^[A-Za-z]:[\\/]', 'once')) || startsWith(path, '\\');
end
