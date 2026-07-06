function findings = basicFindings(ctx)
findings = struct('id',{},'severity',{},'category',{},'message',{});
info = satkcache.projectInfo(ctx.projectRoot);
if ~isempty(info.startupScript)
    findings(end+1)=struct('id','startup_detected','severity','info','category','environment','message',['Startup script detected: ' info.startupScript]); %#ok<AGROW>
end
if ~isempty(info.dataDictionaries)
    findings(end+1)=struct('id','data_dictionaries_detected','severity','info','category','dependency','message',sprintf('%d data dictionaries detected', numel(info.dataDictionaries))); %#ok<AGROW>
end
end
