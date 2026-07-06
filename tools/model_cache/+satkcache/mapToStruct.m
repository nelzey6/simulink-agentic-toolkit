function s = mapToStruct(m)
s = struct(); ks = keys(m);
for i=1:numel(ks)
    k = matlab.lang.makeValidName(ks{i}); s.(k) = m(ks{i});
end
end
