function h = fileHash(file)
%FILEHASH SHA-256 hash for a file using shared SATK cache implementation when available.
if exist('satkcache.fileHash', 'file') == 2
    h = satkcache.fileHash(file);
    return;
end
file = char(string(file));
if ~isfile(file), h = ''; return; end
md = java.security.MessageDigest.getInstance('SHA-256');
fis = java.io.FileInputStream(java.io.File(file));
cleaner = onCleanup(@() fis.close());
buf = zeros(1, 8192, 'int8');
while true
    n = fis.read(buf, 0, numel(buf));
    if n < 0, break; end
    md.update(buf, 0, n);
end
bytes = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(bytes)',1,[]));
end
