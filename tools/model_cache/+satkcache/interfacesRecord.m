function record = interfacesRecord(ctx, req)
base = satkcache.summaryRecord(ctx, req);
base.recordType = 'model_interfaces';
interfaces = struct('path',{},'sid',{},'blockType',{},'ports',{},'portNames',{});
for i = 1:numel(base.children)
    b = base.children(i).path;
    ports = satkcache.safeGetParam(b,'Ports');
    portNames = struct('inputs',{{}},'outputs',{{}});
    try
        ph = get_param(b,'PortHandles');
        portNames.inputs = satkcache.portNameList(ph.Inport);
        portNames.outputs = satkcache.portNameList(ph.Outport);
    catch
    end
    interfaces(end+1) = struct('path',b,'sid',base.children(i).sid,'blockType',base.children(i).blockType,'ports',ports,'portNames',portNames); %#ok<AGROW>
end
record = base;
record.detail = 'interfaces';
record.interfaces = interfaces;
end
