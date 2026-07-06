function writeManifest(ctx, record)
if ~exist(ctx.cacheRoot,'dir'), mkdir(ctx.cacheRoot); end
manifest = struct('schemaVersion',1,'model',ctx.modelFile,'modelName',ctx.modelName,'updatedAt',record.updatedAt,'records',struct());
manifest.records.(matlab.lang.makeValidName([ctx.scope '_' ctx.detail])) = ctx.recordPath;
fid = fopen(fullfile(ctx.cacheRoot,'manifest.json'),'w'); fwrite(fid,jsonencode(manifest, PrettyPrint=true)); fclose(fid);
end
