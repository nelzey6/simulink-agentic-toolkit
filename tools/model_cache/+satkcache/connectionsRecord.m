function record = connectionsRecord(ctx, req)
base = satkcache.summaryRecord(ctx, req);
scopePath = ctx.scope; if strcmp(scopePath,'root'), scopePath = ctx.modelName; end
lines = find_system(scopePath, 'FindAll','on', 'SearchDepth', 1, 'Type','line');
connections = struct('srcBlock',{},'srcPort',{},'dstBlock',{},'dstPort',{},'name',{});
for i=1:numel(lines)
    lh = lines(i);
    try
        srcB = get_param(lh,'SrcBlockHandle'); srcP = get_param(lh,'SrcPortHandle');
        dstB = get_param(lh,'DstBlockHandle'); dstP = get_param(lh,'DstPortHandle');
        if srcB == -1 || isempty(dstB), continue; end
        for j=1:numel(dstB)
            connections(end+1) = struct( ... %#ok<AGROW>
                'srcBlock', satkcache.handlePath(srcB), ...
                'srcPort', satkcache.portNumber(srcP), ...
                'dstBlock', satkcache.handlePath(dstB(j)), ...
                'dstPort', satkcache.portNumber(dstP(j)), ...
                'name', satkcache.safeGetParam(lh,'Name'));
        end
    catch
    end
end
record = base;
record.recordType = 'model_connections';
record.detail = 'connections';
record.connections = connections;
end
