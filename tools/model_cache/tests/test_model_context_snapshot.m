function tests = test_model_context_snapshot
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
toolkitRoot = char(java.io.File(fullfile(fileparts(mfilename('fullpath')), '..', '..', '..')).getCanonicalPath());
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_cache')));

projectRoot = tempname;
mkdir(projectRoot);
mkdir(fullfile(projectRoot, '.git'));
modelName = 'satk_snapshot_fixture';
modelFile = fullfile(projectRoot, [modelName '.slx']);
dictionaryFile = fullfile(projectRoot, 'fixture_data.sldd');
fid = fopen(dictionaryFile,'w'); fwrite(fid,'initial'); fclose(fid);

new_system(modelName);
add_block('simulink/Sources/In1', [modelName '/Input']);
add_block('simulink/Math Operations/Gain', [modelName '/Controller']);
add_block('simulink/Sinks/Out1', [modelName '/Output']);
add_line(modelName, 'Input/1', 'Controller/1');
add_line(modelName, 'Controller/1', 'Output/1');
save_system(modelName, modelFile);
close_system(modelName, 0);

testCase.TestData.projectRoot = projectRoot;
testCase.TestData.modelName = modelName;
testCase.TestData.modelFile = modelFile;
testCase.TestData.dictionaryFile = dictionaryFile;
end

function teardownOnce(testCase)
if bdIsLoaded(testCase.TestData.modelName)
    close_system(testCase.TestData.modelName, 0);
end
if isfolder(testCase.TestData.projectRoot)
    rmdir(testCase.TestData.projectRoot, 's');
end
end

function setup(testCase)
if bdIsLoaded(testCase.TestData.modelName)
    close_system(testCase.TestData.modelName, 0);
end
cacheRoot = fullfile(testCase.TestData.projectRoot, '.satk');
if isfolder(cacheRoot), rmdir(cacheRoot, 's'); end
end

function testFirstReadBuildsSnapshotAndWarmReadDoesNotLoadModel(testCase)
out = model_context('inspect controller', testCase.TestData.modelFile, 'auto', 'use-if-fresh');

verifyEqual(testCase, out.source, 'live+cache_update');
verifyEqual(testCase, out.coverage, 'structural-compile-free');
verifyTrue(testCase, isfile(fullfile(testCase.TestData.projectRoot, '.satk', 'model-cache', ...
    testCase.TestData.modelName, 'snapshot.json')));
verifyGreaterThanOrEqual(testCase, out.cache.blockCount, 3);

close_system(testCase.TestData.modelName, 0);
warm = model_context('inspect controller', testCase.TestData.modelFile, 'auto', 'use-if-fresh');
verifyEqual(testCase, warm.source, 'cache');
verifyFalse(testCase, bdIsLoaded(testCase.TestData.modelName));
verifyEqual(testCase, warm.resolvedScope, [testCase.TestData.modelName '/Controller']);
end

function testCacheOnlyMissDoesNotLoadModel(testCase)
verifyError(testCase, @() model_context('inspect controller', testCase.TestData.modelFile, ...
    'auto', 'cache-only'), 'SATKCACHE:CacheMissOrStale');
verifyFalse(testCase, bdIsLoaded(testCase.TestData.modelName));
end

function testInvalidationRemovesWholeSnapshotWithoutLoadingModel(testCase)
model_context('inspect controller', testCase.TestData.modelFile, 'auto', 'use-if-fresh');
close_system(testCase.TestData.modelName, 0);

out = model_cache_invalidate(testCase.TestData.modelFile);

verifyTrue(testCase, out.removed);
verifyFalse(testCase, isfile(out.snapshot));
verifyFalse(testCase, bdIsLoaded(testCase.TestData.modelName));
verifyError(testCase, @() model_context('inspect controller', testCase.TestData.modelFile, ...
    'auto', 'cache-only'), 'SATKCACHE:CacheMissOrStale');
end

function testSavedModelChangeRebuildsSnapshot(testCase)
first = model_context('inspect controller', testCase.TestData.modelFile, 'root', 'use-if-fresh');
load_system(testCase.TestData.modelFile);
blockPath = [testCase.TestData.modelName '/AddedAfterSnapshot'];
if isempty(find_system(testCase.TestData.modelName,'SearchDepth',1,'Name','AddedAfterSnapshot'))
    add_block('simulink/Signal Attributes/Data Type Conversion', blockPath);
end
save_system(testCase.TestData.modelName);
close_system(testCase.TestData.modelName, 0);

updated = model_context('inspect added block', testCase.TestData.modelFile, 'auto', 'use-if-fresh');

verifyEqual(testCase, updated.source, 'live+cache_update');
verifyGreaterThan(testCase, updated.cache.blockCount, first.cache.blockCount);
verifyEqual(testCase, updated.resolvedScope, blockPath);
end

function testRepeatedDirtyEditsRebuildByChecksum(testCase)
load_system(testCase.TestData.modelFile);
model_context('inspect controller', testCase.TestData.modelFile, 'root', 'use-if-fresh');
add_block('simulink/Sources/Constant',[testCase.TestData.modelName '/UnsavedOne']);
firstDirty = model_context('inspect unsaved one', testCase.TestData.modelFile, 'auto', 'use-if-fresh');
add_block('simulink/Sinks/Terminator',[testCase.TestData.modelName '/UnsavedTwo']);
secondDirty = model_context('inspect unsaved two', testCase.TestData.modelFile, 'auto', 'use-if-fresh');

verifyEqual(testCase, firstDirty.source, 'live+cache_update');
verifyEqual(testCase, secondDirty.source, 'live+cache_update');
verifyGreaterThan(testCase, secondDirty.cache.blockCount, firstDirty.cache.blockCount);
close_system(testCase.TestData.modelName, 0);
end

function testProjectDictionaryChangeRebuildsSnapshot(testCase)
model_context('inspect controller', testCase.TestData.modelFile, 'root', 'use-if-fresh');
fid = fopen(testCase.TestData.dictionaryFile,'a'); fwrite(fid,'-changed'); fclose(fid);

updated = model_context('inspect controller', testCase.TestData.modelFile, 'root', 'use-if-fresh');

verifyEqual(testCase, updated.source, 'live+cache_update');
end
