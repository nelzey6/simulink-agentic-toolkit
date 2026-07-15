function out = model_test_manager_list(test_file, cachePolicy)
%MODEL_TEST_MANAGER_LIST Inspect Simulink Test Manager .mldatx suites/cases.
if nargin < 2 || strlength(string(cachePolicy)) == 0, cachePolicy = 'use-if-fresh'; end
satkproject.requireSimulinkTest('model_test_manager_list');
test_file = satkproject.resolveFile(test_file, '.mldatx');
fingerprint = struct('test_file', test_file, 'hash', satkproject.fileHash(test_file));
repo = satkproject.findProjectRoot(test_file);
[~, baseName, extName] = fileparts(test_file);
cp = satkproject.cachePath(repo, 'test_manager', ['list_' regexprep([baseName extName],'[^A-Za-z0-9_.-]','_')]);
[hit, payload] = satkproject.cacheRead(cp, fingerprint, cachePolicy);
if hit, out = payload; out.cache = cacheInfo('hit', cp, cachePolicy); return; end
if strcmp(char(cachePolicy), 'cache-only'), error('model_test_manager_list:CacheMiss','No fresh test manager cache.'); end
try
    tf = sltest.testmanager.load(test_file);
catch ME
    error('model_test_manager_list:LoadFailed', 'Failed to load Simulink Test file %s: %s', test_file, ME.message);
end
suites = listSuites(tf);
allCases = listAllCases(tf);
out = struct('status','ok','test_file',test_file,'name',safeProp(tf,'Name'),'suite_count',numel(suites), ...
    'test_case_count',numel(allCases),'suites',suites,'test_cases',allCases);
out.cache = cacheInfo('miss', cp, cachePolicy);
satkproject.cacheWrite(cp, fingerprint, rmfield(out,'cache'), cachePolicy);
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
template = caseInfoTemplate();
cases = repmat(template, 0, 1);
for i=1:numel(objs)
    cases(end+1,1) = caseInfo(objs(i)); %#ok<AGROW>
end
end

function item = caseInfoTemplate()
item = struct('name','','test_path','','test_type','','enabled',true,'model','','harness','', ...
    'harness_owner','','stop_time','','simulation_mode','','iterations',0,'assessments',0,'baseline_criteria',0);
end

function item = caseInfo(tc)
item = struct();
item.name = safeProp(tc,'Name');
item.test_path = safeProp(tc,'TestPath');
item.test_type = safeProp(tc,'TestType');
item.enabled = safeProp(tc,'Enabled');
item.model = safeGet(tc,'Model');
item.harness = safeGet(tc,'HarnessName');
item.harness_owner = safeGet(tc,'HarnessOwner');
item.stop_time = safeGet(tc,'StopTime');
item.simulation_mode = safeGet(tc,'SimulationMode');
try
    it = tc.getIterations();
    item.iterations = numel(it);
catch
    item.iterations = 0;
end
try
    ass = tc.getAssessments();
    item.assessments = numel(ass);
catch
    item.assessments = 0;
end
try
    bc = tc.getBaselineCriteria();
    item.baseline_criteria = numel(bc);
catch
    item.baseline_criteria = 0;
end
end
function v = safeProp(obj, name), try v=obj.(name); catch, v=''; end, v=normalize(v); end
function v = safeGet(obj, name), try v=obj.getProperty(name); catch, v=''; end, v=normalize(v); end
function v = normalize(v), if isstring(v), v=char(v); elseif islogical(v)||isnumeric(v), return; elseif isobject(v), v=char(string(v)); end, end
function c = cacheInfo(status,path,policy), c=struct('status',status,'path',path,'policy',char(string(policy))); end
