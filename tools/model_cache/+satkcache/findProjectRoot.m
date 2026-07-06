function root = findProjectRoot(startDir)
root = char(startDir); cur = root;
while true
    if isfolder(fullfile(cur,'.git')) || isfile(fullfile(cur,'MATLAB.md')) || isfile(fullfile(cur,'mcp.md'))
        root = cur; return;
    end
    parent = fileparts(cur);
    if strcmp(parent,cur) || isempty(parent), root = char(startDir); return; end
    cur = parent;
end
end
