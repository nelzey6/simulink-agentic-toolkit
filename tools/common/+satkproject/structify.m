function s = structify(x)
%STRUCTIFY Convert MATLAB objects/structs into JSON-friendly structs.
if isstruct(x)
    s = x;
elseif isobject(x)
    s = struct();
    props = properties(x);
    for i = 1:numel(props)
        name = props{i};
        try
            v = x.(name);
            if isstring(v), v = char(v); end
            if isobject(v), v = char(string(v)); end
            s.(name) = v;
        catch
        end
    end
else
    s = x;
end
end
