function files = findFiles(root, patterns)
%FINDFILES Return relative paths matching extensions/patterns under root.
files = {};
for i = 1:numel(patterns)
    listing = dir(fullfile(root, '**', patterns{i}));
    for k = 1:numel(listing)
        if ~listing(k).isdir
            p = fullfile(listing(k).folder, listing(k).name);
            rel = erase(p, [root filesep]);
            if ~startsWith(rel, ['.git' filesep]) && ~contains(rel, [filesep '.git' filesep])
                files{end+1} = rel; %#ok<AGROW>
            end
        end
    end
end
files = unique(files, 'stable');
end
