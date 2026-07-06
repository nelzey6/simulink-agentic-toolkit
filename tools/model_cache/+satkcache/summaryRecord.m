function record = summaryRecord(ctx, req)
model = ctx.modelName;
scopePath = ctx.scope;
if strcmp(scopePath,'root'), scopePath = model; end
if startsWith(scopePath,'blk_')
    error('SATKCACHE:UnsupportedScope','blk_N aliases are not supported by the prototype cache yet; use a Simulink path or root.');
end
blocks = find_system(scopePath, 'SearchDepth', 1, 'Type', 'Block');
children = struct('name',{},'path',{},'sid',{},'blockType',{},'parent',{},'linkStatus',{});
types = containers.Map('KeyType','char','ValueType','double');
for i = 1:numel(blocks)
    b = blocks{i};
    bt = satkcache.safeGetParam(b,'BlockType');
    if isKey(types,bt), types(bt)=types(bt)+1; else, types(bt)=1; end
    children(end+1) = struct('name',satkcache.safeGetParam(b,'Name'),'path',b,'sid',satkcache.safeSID(b),'blockType',bt,'parent',satkcache.safeGetParam(b,'Parent'),'linkStatus',satkcache.safeGetParam(b,'LinkStatus')); %#ok<AGROW>
end
record = struct();
record.schemaVersion = 1;
record.recordType = 'model_summary';
record.model = ctx.modelFile;
record.modelName = ctx.modelName;
record.scope = ctx.scope;
record.detail = ctx.detail;
record.depth = req.depth;
record.compile = false;
record.createdAt = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
record.updatedAt = record.createdAt;
record.fingerprint = satkcache.fingerprint(ctx);
record.summary = struct('totalBlocksAtDepth', numel(blocks), 'blockTypes', satkcache.mapToStruct(types));
record.children = children;
record.findings = [];
end
