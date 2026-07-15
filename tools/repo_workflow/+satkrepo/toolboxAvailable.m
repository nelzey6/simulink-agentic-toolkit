function tf = toolboxAvailable(name)
%TOOLBOXAVAILABLE True if MATLAB toolbox/add-on is installed/licensed enough to discover.
try
    v = ver;
    tf = any(strcmp({v.Name}, name));
catch
    tf = false;
end
end
