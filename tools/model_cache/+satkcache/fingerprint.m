function fp = fingerprint(ctx)
fp = struct();
fp.schemaVersion = 1;
fp.matlabRelease = version('-release');
fp.modelFile = ctx.modelFile;
fp.modelFileHash = satkcache.fileHash(ctx.modelFile);
d = dir(ctx.modelFile); if ~isempty(d), fp.modelFileMTime = d.datenum; else, fp.modelFileMTime = NaN; end
try
    if bdIsLoaded(ctx.modelName)
        fp.modelDirty = get_param(ctx.modelName, 'Dirty');
    else
        fp.modelDirty = 'off';
    end
catch
    fp.modelDirty = 'unknown';
end
startup = fullfile(ctx.projectRoot,'matlab','startup.m');
if isfile(startup), fp.startupFile = startup; fp.startupHash = satkcache.fileHash(startup); end
end
