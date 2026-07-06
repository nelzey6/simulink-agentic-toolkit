function names = portNameList(handles)
names = cell(1,numel(handles));
for i=1:numel(handles)
    try
        names{i} = get_param(handles(i),'Name');
    catch
        names{i} = '';
    end
end
end
