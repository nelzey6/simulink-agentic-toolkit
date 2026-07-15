function out = model_project_inventory(repo, cachePolicy)
%MODEL_PROJECT_INVENTORY Discover models, libraries, dictionaries, harnesses, and test files.
if nargin < 1 || strlength(string(repo)) == 0, repo = 'auto'; end
if nargin < 2 || strlength(string(cachePolicy)) == 0, cachePolicy = 'use-if-fresh'; end
repo = satkproject.resolveProjectRoot(repo);
fingerprint = inventoryFingerprint(repo);
cp = satkproject.cachePath(repo, 'inventory', 'model_project_inventory');
[hit, payload] = satkproject.cacheRead(cp, fingerprint, cachePolicy);
if hit, out = payload; out.cache = cacheInfo('hit', cp, cachePolicy); return; end
if strcmp(char(cachePolicy), 'cache-only')
    error('model_project_inventory:CacheMiss', 'No fresh model project inventory cache at %s', cp);
end
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
out.cache = cacheInfo('miss', cp, cachePolicy);
satkproject.cacheWrite(cp, fingerprint, rmfield(out,'cache'), cachePolicy);
end

function fp = inventoryFingerprint(repo)
fp = struct();
fp.repo = repo;
fp.gitHead = '';
try
    [status, txt] = system(sprintf('git -C "%s" rev-parse HEAD', repo));
    if status == 0, fp.gitHead = strtrim(txt); end
catch
end
fp.startupHash = satkproject.fileHash(fullfile(repo, 'matlab', 'startup.m'));
fp.toolsHash = satkproject.fileHash(fullfile(repo, 'tools.json'));
end

function c = cacheInfo(status, path, policy)
c = struct('status', status, 'path', path, 'policy', char(string(policy)));
end
