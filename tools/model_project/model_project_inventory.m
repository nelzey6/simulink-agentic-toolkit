function out = model_project_inventory(repo)
%MODEL_PROJECT_INVENTORY Discover models, libraries, dictionaries, harnesses, and test files.
if nargin < 1 || strlength(string(repo)) == 0, repo = 'auto'; end
repo = satkproject.resolveProjectRoot(repo);
allSlx = satkproject.findFiles(repo, {'*.slx'});
models = allSlx(~contains(allSlx, [filesep 'libs' filesep]) & ~contains(allSlx, [filesep 'unit_tests' filesep 'test_harness' filesep]));
libraries = allSlx(contains(allSlx, [filesep 'libs' filesep]));
harnesses = allSlx(contains(allSlx, [filesep 'unit_tests' filesep 'test_harness' filesep]) | contains(lower(allSlx), 'harness'));
dicts = satkproject.findFiles(repo, {'*.sldd'});
testFiles = satkproject.findFiles(repo, {'*.mldatx'});
features = satkproject.findFiles(repo, {'*.feature'});
scripts = satkproject.findFiles(repo, {'*.m'});
out = struct();
out.status = 'ok';
out.repo = repo;
out.updatedAt = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'));
out.models = satkproject.listToStructArray(models, 'path');
out.libraries = satkproject.listToStructArray(libraries, 'path');
out.harnesses = satkproject.listToStructArray(harnesses, 'path');
out.dictionaries = satkproject.listToStructArray(dicts, 'path');
out.test_manager_files = satkproject.listToStructArray(testFiles, 'path');
out.feature_files = satkproject.listToStructArray(features, 'path');
out.matlab_scripts = satkproject.listToStructArray(scripts, 'path');
out.counts = struct('models', numel(models), 'libraries', numel(libraries), 'harnesses', numel(harnesses), ...
    'dictionaries', numel(dicts), 'test_manager_files', numel(testFiles), 'feature_files', numel(features), 'matlab_scripts', numel(scripts));
end
