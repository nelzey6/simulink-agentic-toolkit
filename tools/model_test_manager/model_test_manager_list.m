function out = model_test_manager_list(test_file)
%MODEL_TEST_MANAGER_LIST Inspect Simulink Test Manager .mldatx suites/cases.
satkproject.requireSimulinkTest('model_test_manager_list');
test_file = satkproject.resolveFile(test_file, '.mldatx');
try
    tf = sltest.testmanager.load(test_file);
catch ME
    error('model_test_manager_list:LoadFailed', 'Failed to load Simulink Test file %s: %s', test_file, ME.message);
end
suites = listSuites(tf);
allCases = listAllCases(tf);
out = struct('status','ok','test_file',test_file,'name',safeProp(tf,'Name'),'suite_count',numel(suites), ...
    'test_case_count',numel(allCases),'suites',suites,'test_cases',allCases);
end

function suites = listSuites(tf)
objs = tf.getAllTestSuites();
suiteTemplate = struct('name','','test_path','','enabled',true,'test_case_count',0,'test_cases',casesInfo([]));
suites = repmat(suiteTemplate,0,1);
for i=1:numel(objs)
    ts = objs(i);
    cases = ts.getTestCases();
    item = struct('name',safeProp(ts,'Name'),'test_path',safeProp(ts,'TestPath'), ...
        'enabled',safeProp(ts,'Enabled'),'test_case_count',numel(cases));
    item.test_cases = casesInfo(cases);
    suites(end+1,1) = item; %#ok<AGROW>
end
end

function cases = listAllCases(tf)
objs = tf.getAllTestCases();
cases = casesInfo(objs);
end

function cases = casesInfo(objs)
template = satktestmanager.caseInfo();
cases = repmat(template, 0, 1);
for i=1:numel(objs)
    cases(end+1,1) = satktestmanager.caseInfo(objs(i)); %#ok<AGROW>
end
end
function v = safeProp(obj, name), try v=obj.(name); catch, v=''; end, v=normalize(v); end
function v = normalize(v), if isstring(v), v=char(v); elseif islogical(v)||isnumeric(v), return; elseif isobject(v), v=char(string(v)); end, end
