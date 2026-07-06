function model = resolveAutoModel(model)
model = char(model);
if ~strcmp(model,'auto')
    return;
end
loaded = find_system('type','block_diagram');
loaded = loaded(~strcmp(loaded,'simulink'));
if ~isempty(loaded)
    model = loaded{1};
    return;
end
root = satkcache.findProjectRoot(pwd);
info = satkcache.projectInfo(root);
if ~isempty(info.mainModel)
    model = info.mainModel;
    return;
end
hits = dir(fullfile(root,'**','*.slx'));
if isempty(hits)
    error('SATKCACHE:ModelAutoNotFound','No loaded model or .slx file found for model=auto.');
end
model = fullfile(hits(1).folder,hits(1).name);
end
