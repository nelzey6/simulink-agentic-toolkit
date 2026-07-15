function out = model_test_manager_configure_case(test_file, suite, test_case, config)
%MODEL_TEST_MANAGER_CONFIGURE_CASE Configure a Simulink Test Manager test case.
% config is a JSON object. Supported fields: enabled, model, harness, harness_owner,
% stop_time, start_time, simulation_mode, callbacks, properties.
satkproject.requireSimulinkTest('model_test_manager_configure_case');
test_file = satkproject.resolveFile(test_file, '.mldatx');
cfg = satkproject.jsonObject(config);
try
    tf = sltest.testmanager.load(test_file);
catch ME
    error('model_test_manager_configure_case:LoadFailed', 'Failed to load Simulink Test file %s: %s', test_file, ME.message);
end
tc = findCase(tf, suite, test_case);
if isempty(tc), error('model_test_manager_configure_case:NotFound','Test case not found: %s/%s', suite, test_case); end
if isfield(cfg,'enabled'), tc.Enabled = satkproject.str2logical(cfg.enabled, true); end
if isfield(cfg,'model'), tc.setProperty('Model', char(string(cfg.model))); end
if isfield(cfg,'harness'), tc.setProperty('HarnessName', char(string(cfg.harness))); end
if isfield(cfg,'harness_owner'), tc.setProperty('HarnessOwner', char(string(cfg.harness_owner))); end
if isfield(cfg,'stop_time'), tc.setProperty('OverrideStopTime', true); tc.setProperty('StopTime', str2double(string(cfg.stop_time))); end
if isfield(cfg,'start_time'), tc.setProperty('OverrideStartTime', true); tc.setProperty('StartTime', str2double(string(cfg.start_time))); end
if isfield(cfg,'simulation_mode'), tc.setProperty('SimulationMode', char(string(cfg.simulation_mode))); end
if isfield(cfg,'callbacks') && isstruct(cfg.callbacks)
    cb = cfg.callbacks;
    if isfield(cb,'preload'), tc.setProperty('PreloadCallback', char(string(cb.preload))); end
    if isfield(cb,'postload'), tc.setProperty('PostloadCallback', char(string(cb.postload))); end
    if isfield(cb,'cleanup'), tc.setProperty('CleanupCallback', char(string(cb.cleanup))); end
end
if isfield(cfg,'properties') && isstruct(cfg.properties)
    names = fieldnames(cfg.properties);
    for i=1:numel(names)
        tc.setProperty(names{i}, cfg.properties.(names{i}));
    end
end
tf.saveToFile();
out = struct('status','configured','test_file',test_file,'suite',char(string(suite)), ...
    'test_case',char(string(test_case)),'test_path',tc.TestPath);
try satkproject.invalidateCacheCategory(satkproject.findProjectRoot(test_file), 'test_manager'); catch, end
end

function tc = findCase(tf, suite, test_case)
tc = [];
try
    ts = tf.getTestSuiteByName(char(string(suite)));
    tc = ts.getTestCaseByName(char(string(test_case)));
    return;
catch
end
all = tf.getAllTestCases();
for i=1:numel(all)
    if strcmp(all(i).Name, char(string(test_case))) || strcmp(all(i).TestPath, char(string(test_case)))
        tc = all(i); return;
    end
end
end
