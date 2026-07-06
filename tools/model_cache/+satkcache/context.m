function ctx = context(model, scope, detail)
model = char(model); scope = char(scope); detail = char(detail);
projectRoot = satkcache.findProjectRoot(pwd);
modelFile = satkcache.resolveModel(model, projectRoot);
[~, modelName] = fileparts(modelFile);
cacheRoot = fullfile(projectRoot, '.satk', 'model-cache', modelName);
safeScope = matlab.lang.makeValidName(strrep(strrep(scope,'/','__'),'\','__'));
recordDir = fullfile(cacheRoot, safeScope);
recordPath = fullfile(recordDir, [detail '.json']);
ctx = struct('projectRoot',projectRoot,'modelInput',model,'modelFile',modelFile,'modelName',modelName,'scope',scope,'detail',detail,'cacheRoot',cacheRoot,'recordDir',recordDir,'recordPath',recordPath);
end
