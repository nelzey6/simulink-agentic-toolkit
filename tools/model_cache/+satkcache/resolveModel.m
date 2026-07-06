function modelFile = resolveModel(model, projectRoot)
if isfile(model), modelFile = char(java.io.File(model).getCanonicalPath()); return; end
cand = fullfile(projectRoot, model);
if isfile(cand), modelFile = char(java.io.File(cand).getCanonicalPath()); return; end
[~,~,e] = fileparts(model);
if isempty(e), model = [model '.slx']; end
hits = dir(fullfile(projectRoot, '**', model));
if ~isempty(hits), modelFile = fullfile(hits(1).folder, hits(1).name); return; end
modelFile = cand;
end
