function out = model_test_manager_results(result_source, cachePolicy)
%MODEL_TEST_MANAGER_RESULTS Summarize JUnit XML result artifact or Test Manager result sets.
if nargin < 1 || strlength(string(result_source)) == 0, result_source = fullfile(pwd,'work','results','TestReport.xml'); end
if nargin < 2 || strlength(string(cachePolicy)) == 0, cachePolicy = 'use-if-fresh'; end
satkproject.requireSimulinkTest('model_test_manager_results');
src = char(string(result_source));
fingerprint = struct('source',src,'hash',satkproject.fileHash(src));
[~, baseName, extName] = fileparts(src);
root = satkproject.findProjectRoot(src);
cp = satkproject.cachePath(root, 'results', ['results_' regexprep([baseName extName],'[^A-Za-z0-9_.-]','_')]);
[hit,payload] = satkproject.cacheRead(cp, fingerprint, cachePolicy);
if hit, out=payload; out.cache=cacheInfo('hit',cp,cachePolicy); return; end
if strcmp(char(cachePolicy),'cache-only'), error('model_test_manager_results:CacheMiss','No fresh results cache.'); end
if isfile(src) && endsWith(lower(src), '.xml')
    out = parseJUnit(src);
else
    out = latestTestManagerResults();
end
out.cache = cacheInfo('miss',cp,cachePolicy);
satkproject.cacheWrite(cp, fingerprint, rmfield(out,'cache'), cachePolicy);
end

function out = parseJUnit(src)
doc = xmlread(src);
root = doc.getDocumentElement();
total = str2double(char(root.getAttribute('tests')));
failures = str2double(char(root.getAttribute('failures')));
errors = str2double(char(root.getAttribute('errors')));
skipped = str2double(char(root.getAttribute('skipped')));
if isnan(total), total = 0; end, if isnan(failures), failures = 0; end, if isnan(errors), errors = 0; end, if isnan(skipped), skipped = 0; end
nodes = doc.getElementsByTagName('testcase');
items = repmat(struct('name','','classname','','failure',''),0,1);
for i=0:nodes.getLength()-1
    tc = nodes.item(i);
    f = tc.getElementsByTagName('failure');
    e = tc.getElementsByTagName('error');
    if f.getLength()>0 || e.getLength()>0
        msg = '';
        if f.getLength()>0, msg = char(f.item(0).getTextContent()); elseif e.getLength()>0, msg = char(e.item(0).getTextContent()); end
        items(end+1,1) = struct('name',char(tc.getAttribute('name')), 'classname',char(tc.getAttribute('classname')), 'failure',msg); %#ok<AGROW>
    end
end
status = 'passed'; if failures+errors > 0, status='failed'; end
out = struct('status',status,'source',src,'total',total,'passed',max(0,total-failures-errors-skipped), ...
    'failed',failures,'errors',errors,'skipped',skipped,'failures_detail',items);
end

function out = latestTestManagerResults()
try
    sets = sltest.testmanager.getResultSets();
    out = struct('status','ok','source','testmanager','result_set_count',numel(sets));
catch ME
    out = struct('status','error','source','testmanager','error',ME.message);
end
end
function c = cacheInfo(status,path,policy), c=struct('status',status,'path',path,'policy',char(string(policy))); end
