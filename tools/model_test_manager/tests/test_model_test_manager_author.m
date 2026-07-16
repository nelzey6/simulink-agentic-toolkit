function tests = test_model_test_manager_author
tests = functiontests(localfunctions);
end

function testAuthorsSimulationCaseIntoExistingEmptyFile(testCase)
[root, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>

definition = struct('model', modelFile, 'stop_time', '5', ...
    'simulation_mode', 'Normal', 'enabled', true);
out = model_test_manager_author(testFile, 'Agent Tests', 'Nominal smoke test', definition);

verifyEqual(testCase, out.status, 'created');
verifyEqual(testCase, out.suite, 'Agent Tests');
verifyEqual(testCase, out.test_case.name, 'Nominal smoke test');
[~, modelName] = fileparts(modelFile);
verifyEqual(testCase, out.test_case.model, modelName);
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.suite_count, 1);
verifyEqual(testCase, listed.test_case_count, 1);
verifyEqual(testCase, listed.test_cases(1).name, 'Nominal smoke test');
verifyEqual(testCase, fieldnames(out.test_case), fieldnames(listed.test_cases(1)));
clear cleanup;
end

function testAuthorsSimulationCaseFromJsonStringDefinition(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
definition = jsonencode(struct('model', modelFile, 'stop_time', '5', ...
    'simulation_mode', 'Normal', 'enabled', true));

out = model_test_manager_author(testFile, 'Agent Tests', 'JSON transport test', definition);

verifyEqual(testCase, out.status, 'created');
verifyEqual(testCase, out.test_case.name, 'JSON transport test');
[~, modelName] = fileparts(modelFile);
verifyEqual(testCase, out.test_case.model, modelName);
clear cleanup;
end

function testRepeatedDefinitionIsUnchangedAndDoesNotDuplicate(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
definition = struct('model', modelFile, 'stop_time', '5', ...
    'simulation_mode', 'Normal', 'enabled', true);
model_test_manager_author(testFile, 'Agent Tests', 'Nominal smoke test', definition);

out = model_test_manager_author(testFile, 'Agent Tests', 'Nominal smoke test', definition);

verifyEqual(testCase, out.status, 'unchanged');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.suite_count, 1);
verifyEqual(testCase, listed.test_case_count, 1);
clear cleanup;
end

function testUpdatesExistingCaseInPlace(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
model_test_manager_author(testFile, 'Agent Tests', 'Nominal smoke test', ...
    struct('model', modelFile, 'stop_time', '5'));

out = model_test_manager_author(testFile, 'Agent Tests', 'Nominal smoke test', ...
    struct('model', modelFile, 'stop_time', '8', 'enabled', false));

verifyEqual(testCase, out.status, 'updated');
verifyFalse(testCase, out.test_case.enabled);
verifyEqual(testCase, double(out.test_case.stop_time), 8);
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.test_case_count, 1);
verifyFalse(testCase, listed.test_cases(1).enabled);
verifyEqual(testCase, double(listed.test_cases(1).stop_time), 8);
clear cleanup;
end

function testRejectsExistingNonSimulationCaseWithSameName(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
tf = sltest.testmanager.load(testFile);
ts = tf.createTestSuite('Agent Tests');
ts.createTestCase('baseline', 'Shared case name');
tf.saveToFile();
sltest.testmanager.clear;

verifyError(testCase, ...
    @() model_test_manager_author(testFile, 'Agent Tests', 'Shared case name', ...
        struct('model', modelFile)), ...
    'model_test_manager_author:IncompatibleTestType');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.test_case_count, 1);
clear cleanup;
end

function testRejectsUnknownDefinitionFieldsWithoutAuthoring(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
definition = struct('model', modelFile, 'callbacks', struct('preload', 'disp(1)'));

verifyError(testCase, ...
    @() model_test_manager_author(testFile, 'Agent Tests', 'Unsafe case', definition), ...
    'model_test_manager_author:UnknownField');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.suite_count, 0);
verifyEqual(testCase, listed.test_case_count, 0);
clear cleanup;
end

function testRejectsIncompleteHarnessPairWithoutAuthoring(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
definition = struct('model', modelFile, 'harness', 'AgentHarness');

verifyError(testCase, ...
    @() model_test_manager_author(testFile, 'Agent Tests', 'Incomplete harness', definition), ...
    'model_test_manager_author:IncompleteHarness');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.test_case_count, 0);
clear cleanup;
end

function testRejectsUnsupportedSimulationModeWithoutAuthoring(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
definition = struct('model', modelFile, 'simulation_mode', 'External');

verifyError(testCase, ...
    @() model_test_manager_author(testFile, 'Agent Tests', 'Unsupported mode', definition), ...
    'model_test_manager_author:UnsupportedSimulationMode');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.test_case_count, 0);
clear cleanup;
end

function testRejectsMissingModelWithoutAuthoring(testCase)
[root, testFile, ~, cleanup] = createFixture(testCase); %#ok<ASGLU>
definition = struct('model', fullfile(root, 'missing_model.slx'));

verifyError(testCase, ...
    @() model_test_manager_author(testFile, 'Agent Tests', 'Missing model', definition), ...
    'model_test_manager_author:ModelNotFound');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.test_case_count, 0);
clear cleanup;
end

function testDoesNotCreateMissingTestFile(testCase)
requireLicenseAvailable(testCase);
toolkitRoot = char(java.io.File(fullfile(fileparts(mfilename('fullpath')), '..', '..', '..')).getCanonicalPath());
addpath(genpath(fullfile(toolkitRoot, 'tools', 'common')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_test_manager')));
root = tempname;
mkdir(root);
cleanup = onCleanup(@() removeFixture(root));
addpath(root);
testFile = fullfile(root, 'missing_tests.mldatx');

verifyError(testCase, ...
    @() model_test_manager_author(testFile, 'Agent Tests', 'Missing file', struct('model', 'unused.slx')), ...
    'satkproject:FileNotFound');
verifyFalse(testCase, isfile(testFile));
clear cleanup;
end

function testAuthoredCaseRunsThroughExistingRunner(testCase)
[root, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
makeModelExecutable(modelFile);
model_test_manager_author(testFile, 'Agent Tests', 'Executable smoke test', ...
    struct('model', modelFile, 'stop_time', '0'));

report = struct('output_dir', fullfile(root, 'results'), 'junit', false, 'pdf', false);
out = model_test_manager_run(testFile, '[]', 'false', report);

verifyEqual(testCase, out.status, 'passed');
verifyEqual(testCase, out.total, 1);
verifyEqual(testCase, out.passed, 1);
clear cleanup;
end

function testAssociatesExistingExternalHarness(testCase)
[root, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
load_system(modelFile);
sltest.harness.create('empty_model', 'Name', 'AgentHarness', ...
    'Source', 'Inport', 'Sink', 'Outport', 'SaveExternally', true, ...
    'HarnessPath', fullfile(root, 'AgentHarness.slx'), 'CreateWithoutCompile', true);
save_system('empty_model');
close_system('empty_model', 0);
definition = struct('model', modelFile, 'harness', 'AgentHarness', ...
    'harness_owner', 'empty_model');

out = model_test_manager_author(testFile, 'Harness Tests', 'Harness smoke test', definition);

verifyEqual(testCase, out.test_case.harness, 'AgentHarness');
verifyEqual(testCase, out.test_case.harness_owner, 'empty_model');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.test_cases(1).harness, 'AgentHarness');
verifyEqual(testCase, listed.test_cases(1).harness_owner, 'empty_model');
clear cleanup;
end

function testRejectsMissingHarnessWithoutSaving(testCase)
[~, testFile, modelFile, cleanup] = createFixture(testCase); %#ok<ASGLU>
definition = struct('model', modelFile, 'harness', 'MissingHarness', ...
    'harness_owner', 'empty_model');
thrown = false;
try
    model_test_manager_author(testFile, 'Harness Tests', 'Missing harness', definition);
catch
    thrown = true;
end
verifyTrue(testCase, thrown, 'A missing harness mapping must be rejected.');
listed = model_test_manager_list(testFile);
verifyEqual(testCase, listed.test_case_count, 0);
clear cleanup;
end

function makeModelExecutable(modelFile)
load_system(modelFile);
add_block('simulink/Sources/Constant', 'empty_model/Constant');
add_block('simulink/Sinks/Terminator', 'empty_model/Terminator');
add_line('empty_model', 'Constant/1', 'Terminator/1');
save_system('empty_model');
close_system('empty_model', 0);
end

function [root, testFile, modelFile, cleanup] = createFixture(testCase)
requireLicenseAvailable(testCase);
toolkitRoot = char(java.io.File(fullfile(fileparts(mfilename('fullpath')), '..', '..', '..')).getCanonicalPath());
addpath(genpath(fullfile(toolkitRoot, 'tools', 'common')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_test_manager')));
root = tempname;
mkdir(root);
cleanup = onCleanup(@() removeFixture(root));
addpath(root);
modelFile = fullfile(root, 'empty_model.slx');
new_system('empty_model');
save_system('empty_model', modelFile);
close_system('empty_model', 0);
testFile = fullfile(root, 'empty_tests.mldatx');
tf = sltest.testmanager.TestFile(testFile);
suites = tf.getAllTestSuites();
for i = 1:numel(suites)
    remove(suites(i));
end
tf.saveToFile();
end

function requireLicenseAvailable(testCase)
testCase.assumeNotEmpty(which('sltest.testmanager.TestFile'), ...
    'Simulink Test is required for this integration test.');
try
    hasLicense = license('test', 'Simulink_Test') ~= 0;
catch
    hasLicense = false;
end
testCase.assumeTrue(hasLicense, ...
    'A Simulink Test license is required for this integration test.');
end

function removeFixture(root)
try sltest.testmanager.clear; catch, end
try close_system('empty_model', 0); catch, end
try rmpath(root); catch, end
if isfolder(root), rmdir(root, 's'); end
end
