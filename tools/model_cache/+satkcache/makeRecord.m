function record = makeRecord(ctx, req)
detail = char(ctx.detail);
switch detail
    case 'summary'
        record = satkcache.summaryRecord(ctx, req);
    case 'interfaces'
        record = satkcache.interfacesRecord(ctx, req);
    case 'connections'
        record = satkcache.connectionsRecord(ctx, req);
    otherwise
        error('SATKCACHE:UnsupportedDetail','Unsupported cache detail: %s', detail);
end
end
