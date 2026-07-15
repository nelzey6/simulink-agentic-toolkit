function out = model_test_manager_author(test_file, suite, test_case, definition)
%MODEL_TEST_MANAGER_AUTHOR Author a simulation case in an existing .mldatx.
satkproject.requireSimulinkTest('model_test_manager_author');
test_file = satkproject.resolveFile(test_file, '.mldatx');
suite = requiredText(suite, 'suite');
test_case = requiredText(test_case, 'test_case');
cfg = satkproject.jsonObject(definition);
validateDefinition(cfg);
model = resolveModel(requiredFieldText(cfg, 'model'));

try
    tf = sltest.testmanager.load(test_file);
catch ME
    error('model_test_manager_author:LoadFailed', ...
        'Failed to load Simulink Test file %s: %s', test_file, ME.message);
end

ts = tf.getTestSuiteByName(suite);
createdSuite = false;
if isempty(ts)
    ts = tf.createTestSuite(suite);
    createdSuite = true;
end
tc = ts.getTestCaseByName(test_case);
createdCase = false;
if isempty(tc)
    tc = ts.createTestCase('simulation', test_case);
    createdCase = true;
    status = 'created';
elseif definitionMatches(tc, cfg, model)
    status = 'unchanged';
else
    status = 'updated';
end
if ~strcmp(status, 'unchanged')
    try
        applyDefinition(tc, cfg, model);
        tf.saveToFile();
    catch ME
        if createdCase
            try remove(tc); catch, end
        end
        if createdSuite
            try remove(ts); catch, end
        end
        rethrow(ME);
    end
end

out = struct('status', status, 'test_file', test_file, 'suite', suite, ...
    'test_case', satktestmanager.caseInfo(tc));
end

function applyDefinition(tc, cfg, model)
[harness, owner] = desiredHarness(cfg);
tc.setProperty('Model', model, 'HarnessName', harness, 'HarnessOwner', owner);
tc.Enabled = desiredEnabled(cfg);
tc.setProperty('SimulationMode', desiredSimulationMode(cfg));
[overrideStopTime, stopTime] = desiredStopTime(cfg);
tc.setProperty('OverrideStopTime', overrideStopTime);
if overrideStopTime
    tc.setProperty('OverrideStopTime', true);
    tc.setProperty('StopTime', stopTime);
end
end

function tf = definitionMatches(tc, cfg, model)
[overrideStopTime, stopTime] = desiredStopTime(cfg);
[harness, owner] = desiredHarness(cfg);
tf = strcmp(normalizeModel(safeGet(tc, 'Model')), normalizeModel(model)) && ...
    isequal(logical(tc.Enabled), desiredEnabled(cfg)) && ...
    strcmp(char(string(safeGet(tc, 'SimulationMode'))), desiredSimulationMode(cfg)) && ...
    isequal(logical(safeGet(tc, 'OverrideStopTime')), overrideStopTime) && ...
    strcmp(char(string(safeGet(tc, 'HarnessName'))), harness) && ...
    strcmp(char(string(safeGet(tc, 'HarnessOwner'))), owner);
if tf && overrideStopTime
    tf = isequal(double(safeGet(tc, 'StopTime')), stopTime);
end
end

function value = desiredEnabled(cfg)
value = true;
if isfield(cfg, 'enabled')
    value = satkproject.str2logical(cfg.enabled, true);
end
end

function value = desiredSimulationMode(cfg)
value = 'Normal';
if isfield(cfg, 'simulation_mode') && strlength(string(cfg.simulation_mode)) > 0
    requested = char(string(cfg.simulation_mode));
    names = {'Normal','Accelerator','Rapid Accelerator','SIL','PIL'};
    values = {'Normal','Accelerator','Rapid Accelerator', ...
        'Software-in-the-Loop (SIL)','Processor-in-the-Loop (PIL)'};
    index = find(strcmpi(requested, names), 1);
    if isempty(index)
        error('model_test_manager_author:UnsupportedSimulationMode', ...
            'definition.simulation_mode must be Normal, Accelerator, Rapid Accelerator, SIL, or PIL.');
    end
    value = values{index};
end
end

function [override, value] = desiredStopTime(cfg)
override = isfield(cfg, 'stop_time') && strlength(string(cfg.stop_time)) > 0;
value = [];
if override
    value = str2double(string(cfg.stop_time));
    if ~isscalar(value) || ~isfinite(value) || value < 0
        error('model_test_manager_author:InvalidStopTime', ...
            'definition.stop_time must be a finite nonnegative number.');
    end
end
end

function [harness, owner] = desiredHarness(cfg)
hasHarness = isfield(cfg, 'harness') && strlength(string(cfg.harness)) > 0;
hasOwner = isfield(cfg, 'harness_owner') && strlength(string(cfg.harness_owner)) > 0;
if xor(hasHarness, hasOwner)
    error('model_test_manager_author:IncompleteHarness', ...
        'definition.harness and definition.harness_owner must be supplied together.');
end
harness = '';
owner = '';
if hasHarness
    harness = char(string(cfg.harness));
    owner = char(string(cfg.harness_owner));
end
end

function value = normalizeModel(value)
value = char(string(value));
[folder, name, extension] = fileparts(value);
if strcmpi(extension, '.slx') || strcmpi(extension, '.mdl')
    value = fullfile(folder, name);
end
end

function validateDefinition(cfg)
allowed = {'model','harness','harness_owner','enabled','stop_time','simulation_mode'};
unknown = setdiff(fieldnames(cfg), allowed);
if ~isempty(unknown)
    error('model_test_manager_author:UnknownField', ...
        'Unknown definition field(s): %s.', strjoin(unknown, ', '));
end
desiredEnabled(cfg);
desiredSimulationMode(cfg);
desiredStopTime(cfg);
desiredHarness(cfg);
end

function model = resolveModel(model)
candidate = model;
if ~isfile(candidate)
    found = which(candidate);
    if isempty(found) && isempty(fileparts(candidate))
        found = which([candidate '.slx']);
    end
    if isempty(found)
        error('model_test_manager_author:ModelNotFound', ...
            'definition.model was not found: %s', candidate);
    end
    candidate = found;
end
[~,model,extension] = fileparts(candidate);
if ~any(strcmpi(extension, {'.slx','.mdl'}))
    error('model_test_manager_author:InvalidModelFile', ...
        'definition.model must resolve to a .slx or .mdl file: %s', candidate);
end
end

function value = safeGet(tc, name)
try
    value = tc.getProperty(name);
catch
    value = '';
end
if isstring(value) || isobject(value)
    value = char(string(value));
end
end

function value = requiredFieldText(cfg, name)
if ~isfield(cfg, name)
    error('model_test_manager_author:MissingField', ...
        'definition.%s is required.', name);
end
value = requiredText(cfg.(name), ['definition.' name]);
end

function value = requiredText(value, name)
value = char(string(value));
if isempty(strtrim(value))
    error('model_test_manager_author:MissingValue', '%s must not be empty.', name);
end
end
