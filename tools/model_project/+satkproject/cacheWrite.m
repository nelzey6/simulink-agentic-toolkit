function cacheWrite(path, fingerprint, payload, cachePolicy)
%CACHEWRITE Store payload unless disabled.
if strcmp(char(string(cachePolicy)), 'do-not-cache'), return; end
rec = struct();
rec.schemaVersion = 1;
rec.updatedAt = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'));
rec.fingerprint = fingerprint;
rec.payload = payload;
fid = fopen(path, 'w');
if fid < 0, return; end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, jsonencode(rec, PrettyPrint=true));
end
