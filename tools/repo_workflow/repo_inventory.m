function out = repo_inventory(repo, cachePolicy)
%REPO_INVENTORY Discover models, libraries, dictionaries, harnesses, and test files.
if nargin < 1 || strlength(string(repo)) == 0, repo = 'auto'; end
if nargin < 2 || strlength(string(cachePolicy)) == 0, cachePolicy = 'use-if-fresh'; end
repo = satkrepo.resolveRepoRoot(repo);
fingerprint = inventoryFingerprint(repo);
cp = satkrepo.cachePath(repo, 'inventory', 'repo_inventory');
[hit, payload] = satkrepo.cacheRead(cp, fingerprint, cachePolicy);
if hit, out = payload; out.cache = cacheInfo('hit', cp, cachePolicy); return; end
if strcmp(char(cachePolicy), 'cache-only')
    error('repo_inventory:CacheMiss', 'No fresh repo inventory cache at %s', cp);
end
allSlx = satkrepo.findFiles(repo, {'*.slx'});
models = allSlx(~contains(allSlx, [filesep 'libs' filesep]) & ~contains(allSlx, [filesep 'unit_tests' filesep 'test_harness' filesep]));
libraries = allSlx(contains(allSlx, [filesep 'libs' filesep]));
harnesses = allSlx(contains(allSlx, [filesep 'unit_tests' filesep 'test_harness' filesep]) | contains(lower(allSlx), 'harness'));
dicts = satkrepo.findFiles(repo, {'*.sldd'});
testFiles = satkrepo.findFiles(repo, {'*.mldatx'});
features = satkrepo.findFiles(repo, {'*.feature'});
scripts = satkrepo.findFiles(repo, {'*.m'});
out = struct();
out.status = 'ok';
out.repo = repo;
out.updatedAt = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'));
out.models = satkrepo.listToStructArray(models, 'path');
out.libraries = satkrepo.listToStructArray(libraries, 'path');
out.harnesses = satkrepo.listToStructArray(harnesses, 'path');
out.dictionaries = satkrepo.listToStructArray(dicts, 'path');
out.test_manager_files = satkrepo.listToStructArray(testFiles, 'path');
out.feature_files = satkrepo.listToStructArray(features, 'path');
out.matlab_scripts = satkrepo.listToStructArray(scripts, 'path');
out.counts = struct('models', numel(models), 'libraries', numel(libraries), 'harnesses', numel(harnesses), ...
    'dictionaries', numel(dicts), 'test_manager_files', numel(testFiles), 'feature_files', numel(features), 'matlab_scripts', numel(scripts));
out.cache = cacheInfo('miss', cp, cachePolicy);
satkrepo.cacheWrite(cp, fingerprint, rmfield(out,'cache'), cachePolicy);
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
fp.startupHash = satkrepo.fileHash(fullfile(repo, 'matlab', 'startup.m'));
fp.toolsHash = satkrepo.fileHash(fullfile(repo, 'tools.json'));
end

function c = cacheInfo(status, path, policy)
c = struct('status', status, 'path', path, 'policy', char(string(policy)));
end
