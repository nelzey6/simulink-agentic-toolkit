function index = blockIndex(ctx, cachePolicy)
idxDir = fullfile(ctx.cacheRoot,'indexes');
idxPath = fullfile(idxDir,'blocks.json');
fp = satkcache.fingerprint(ctx);
if ~strcmp(string(cachePolicy),'force-refresh') && isfile(idxPath)
    old = jsondecode(fileread(idxPath));
    if isequaln(old.fingerprint, fp)
        index = old;
        return;
    end
end
if ~exist(idxDir,'dir'), mkdir(idxDir); end
blocks = find_system(ctx.modelName, 'Type','Block');
items = struct('name',{},'path',{},'sid',{},'blockType',{},'parent',{});
for i=1:numel(blocks)
    b = blocks{i};
    items(end+1) = struct('name',satkcache.safeGetParam(b,'Name'),'path',b,'sid',satkcache.safeSID(b),'blockType',satkcache.safeGetParam(b,'BlockType'),'parent',satkcache.safeGetParam(b,'Parent')); %#ok<AGROW>
end
index = struct('schemaVersion',1,'model',ctx.modelFile,'modelName',ctx.modelName,'updatedAt',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z''')),'fingerprint',fp,'blockCount',numel(items),'blocks',items);
fid=fopen(idxPath,'w'); fwrite(fid,jsonencode(index,PrettyPrint=true)); fclose(fid);
end
