function item = caseInfo(tc)
%CASEINFO Return the normalized public representation of a test case.
item = struct('name','','test_path','','test_type','','enabled',true,'model','', ...
    'harness','','harness_owner','','stop_time','','simulation_mode','', ...
    'iterations',0,'assessments',0,'baseline_criteria',0);
if nargin < 1 || isempty(tc)
    return;
end
item.name = safeProp(tc, 'Name');
item.test_path = safeProp(tc, 'TestPath');
item.test_type = safeProp(tc, 'TestType');
item.enabled = safeProp(tc, 'Enabled');
item.model = safeGet(tc, 'Model');
item.harness = safeGet(tc, 'HarnessName');
item.harness_owner = safeGet(tc, 'HarnessOwner');
item.stop_time = safeGet(tc, 'StopTime');
item.simulation_mode = safeGet(tc, 'SimulationMode');
item.iterations = safeCount(@() tc.getIterations());
item.assessments = safeCount(@() tc.getAssessments());
item.baseline_criteria = safeCount(@() tc.getBaselineCriteria());
end

function value = safeProp(obj, name)
try value = obj.(name); catch, value = ''; end
value = normalize(value);
end

function value = safeGet(obj, name)
try value = obj.getProperty(name); catch, value = ''; end
value = normalize(value);
end

function count = safeCount(getter)
try count = numel(getter()); catch, count = 0; end
end

function value = normalize(value)
if isstring(value) || isobject(value)
    value = char(string(value));
end
end
