function out = model_test_manager_create_case(test_file, suite, test_case, test_type, model, component, harness, stop_time)
%MODEL_TEST_MANAGER_CREATE_CASE Create a native Simulink Test Manager test case.
if nargin < 4 || strlength(string(test_type)) == 0, test_type = 'simulation'; end
if nargin < 5, model = ''; end
if nargin < 6, component = ''; end
if nargin < 7, harness = ''; end
if nargin < 8 || strlength(string(stop_time)) == 0, stop_time = '10'; end
satkproject.requireSimulinkTest('model_test_manager_create_case');
test_file = satkproject.resolveFile(test_file, '.mldatx');
try
    tf = sltest.testmanager.load(test_file);
catch ME
    error('model_test_manager_create_case:LoadFailed', 'Failed to load Simulink Test file %s: %s', test_file, ME.message);
end
ts = getOrCreateSuite(tf, char(string(suite)));
tc = ts.createTestCase(char(string(test_type)), char(string(test_case)));
configureBasic(tc, model, component, harness, stop_time);
tf.saveToFile();
out = struct('status','created','test_file',test_file,'suite',char(string(suite)), ...
    'test_case',char(string(test_case)),'test_path',tc.TestPath);
invalidateCaches(test_file);
end

function ts = getOrCreateSuite(tf, name)
try
    ts = tf.getTestSuiteByName(name);
    if ~isempty(ts), return; end
catch
end
ts = tf.createTestSuite(name);
end
function configureBasic(tc, model, component, harness, stop_time)
if strlength(string(model)) > 0, tc.setProperty('Model', char(string(model))); end
if strlength(string(component)) > 0, tc.setProperty('HarnessOwner', char(string(component))); end
if strlength(string(harness)) > 0, tc.setProperty('HarnessName', char(string(harness))); end
if strlength(string(stop_time)) > 0
    tc.setProperty('OverrideStopTime', true);
    tc.setProperty('StopTime', str2double(stop_time));
end
end
function invalidateCaches(test_file)
try
    satkproject.invalidateCacheCategory(satkproject.findProjectRoot(test_file), 'test_manager');
catch
end
end
