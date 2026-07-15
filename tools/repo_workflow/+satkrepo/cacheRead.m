function [hit, payload] = cacheRead(path, fingerprint, cachePolicy)
%CACHEREAD Return cached payload if policy permits and fingerprint matches.
hit = false; payload = struct();
cachePolicy = char(string(cachePolicy));
if strcmp(cachePolicy, 'do-not-cache') || strcmp(cachePolicy, 'force-refresh') || ~isfile(path)
    return;
end
try
    rec = jsondecode(fileread(path));
catch
    return;
end
if strcmp(cachePolicy, 'cache-only')
    hit = true; payload = rec.payload; return;
end
if isfield(rec, 'fingerprint') && isequaln(rec.fingerprint, fingerprint)
    hit = true; payload = rec.payload;
end
end
