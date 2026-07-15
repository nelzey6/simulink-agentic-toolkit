function h = fileHash(path)
%FILEHASH SHA-256 hash for a file. Returns '' when file does not exist.
path = char(string(path));
if ~isfile(path)
    h = '';
    return;
end
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'r');
if fid < 0, h = ''; return; end
cleanup = onCleanup(@() fclose(fid));
while ~feof(fid)
    data = fread(fid, 1024*1024, '*uint8');
    if ~isempty(data), md.update(data); end
end
bytes = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(bytes,2).',1,[]));
end
