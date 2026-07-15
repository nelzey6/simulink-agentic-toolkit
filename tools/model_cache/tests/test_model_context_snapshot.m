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
add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/Target Controller']);
add_block('simulink/Math Operations/Gain', [modelName '/Target Controller/Controller Output']);
add_block('simulink/Sinks/Terminator', [modelName '/Target Sink']);
add_block('built-in/Subsystem', [modelName '/Wide Scope']);
for i = 1:30
    add_block('simulink/Sources/Constant', ...
        sprintf('%s/Wide Scope/Item%02d',modelName,i));
end
add_line(modelName, 'Input/1', 'Controller/1');
add_line(modelName, 'Controller/1', 'Output/1');
add_line(modelName, 'Target Controller/1', 'Target Sink/1');
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

function testTaskScopePrefersBestMatchingSubsystem(testCase)
out = model_context('inspect target controller output', testCase.TestData.modelFile, ...
    'auto', 'use-if-fresh');

verifyEqual(testCase, out.resolvedScope, ...
    [testCase.TestData.modelName '/Target Controller']);
verifyEqual(testCase, out.candidateScopes(1).blockType, 'SubSystem');
end

function testContextSliceUsesCompactScopeRelativeRecords(testCase)
scope = [testCase.TestData.modelName '/Target Controller'];
out = model_context('inspect target controller', testCase.TestData.modelFile, ...
    scope, 'use-if-fresh');

verifyEqual(testCase, out.context.scope, scope);
verifyTrue(testCase, all(~startsWith({out.context.blocks.path}, ...
    [testCase.TestData.modelName '/'])));
verifyTrue(testCase, any(strcmp({out.context.blocks.path}, 'Controller Output')));
verifyFalse(testCase, isfield(out.context.blocks, 'parent'));
verifyFalse(testCase, isfield(out.context.blocks, 'referenceBlock'));
verifyFalse(testCase, isfield(out.context.blocks, 'linkStatus'));
verifyFalse(testCase, isfield(out.context.blocks, 'maskType'));
verifyFalse(testCase, isfield(out.context.blocks, 'portNames'));
if ~isempty(out.context.connections)
    verifyTrue(testCase, all(~startsWith({out.context.connections.srcBlock}, ...
        [testCase.TestData.modelName '/'])));
    verifyFalse(testCase, isfield(out.context.connections, 'name'));
    externalPath = [testCase.TestData.modelName '/Target Sink'];
    external = out.context.connections(strcmp({out.context.connections.dstBlock}, externalPath));
    verifyNotEmpty(testCase, external);
    verifyEqual(testCase, external(1).srcBlock, '.');
    internal = out.context.connections(~strcmp({out.context.connections.dstBlock}, externalPath));
    verifyTrue(testCase, all(~startsWith({internal.dstBlock}, ...
        [testCase.TestData.modelName '/'])));
end

warm = model_context('inspect target controller', testCase.TestData.modelFile, ...
    scope, 'cache-only');
verifyEqual(testCase, warm.context, out.context);
verifyFalse(testCase, bdIsLoaded(testCase.TestData.modelName));
end

function testTruncatedContextReportsOmissionsAndRecovery(testCase)
scope = [testCase.TestData.modelName '/Wide Scope'];
out = model_context('inspect wide scope', testCase.TestData.modelFile, ...
    scope, 'use-if-fresh');

verifyEqual(testCase, out.context.summary.returnedBlocks, 25);
verifyEqual(testCase, out.context.summary.totalDirectBlocks, 30);
verifyEqual(testCase, out.context.summary.omittedBlocks, 5);
verifyTrue(testCase, out.context.truncated.blocks);
verifyEqual(testCase, out.nextActions(1).tool, 'model_read');
verifyTrue(testCase, contains(out.nextActions(1).reason, 'truncated'));
verifyTrue(testCase, contains(out.nextActions(1).reason, 'candidateScopes'));
verifyTrue(testCase, contains(out.nextActions(1).reason, 'deeper explicit scope'));
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
