function ensureLoaded(modelFile)
[folder, name] = fileparts(modelFile);
if ~bdIsLoaded(name)
    old = pwd; c = onCleanup(@() cd(old));
    if isfolder(folder), cd(folder); end
    load_system(modelFile);
end
end
