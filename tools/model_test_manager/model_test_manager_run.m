function out = model_test_manager_run(test_file, tests, parallel, report)
%MODEL_TEST_MANAGER_RUN Run selected/full native Simulink Test Manager tests.
% tests is JSON array of full/partial test names. report is JSON object with
% fields output_dir, junit, and pdf.
if nargin < 2, tests = '[]'; end
if nargin < 3 || strlength(string(parallel)) == 0, parallel = 'false'; end
if nargin < 4, report = '{}'; end
satkproject.requireSimulinkTest('model_test_manager_run');
test_file = satkproject.resolveFile(test_file, '.mldatx');
out = runWithUnittest(test_file, tests, parallel, report);
end

function out = runWithUnittest(test_file, tests, parallel, report)
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.XMLPlugin;
import matlab.unittest.plugins.TestReportPlugin;
selected = satkproject.jsonList(tests);
rep = satkproject.jsonObject(report);
if isfield(rep,'output_dir'), outputDir = char(string(rep.output_dir)); else, outputDir = fullfile(pwd,'work','results'); end
if ~exist(outputDir,'dir'), mkdir(outputDir); end
suite = testsuite(test_file);
if ~isempty(selected)
    keep = false(size(suite));
    for i=1:numel(suite)
        nm = suite(i).Name;
        for k=1:numel(selected)
            pat = char(string(selected{k}));
            if strcmp(nm, pat) || contains(nm, pat)
                keep(i) = true;
            end
        end
    end
    suite = suite(keep);
end
tr = TestRunner.withTextOutput;
artifacts = struct();
if ~isfield(rep,'junit') || satkproject.str2logical(rep.junit,true)
    artifacts.junit = fullfile(outputDir,'TestReport.xml');
    tr.addPlugin(XMLPlugin.producingJUnitFormat(artifacts.junit));
end
if isfield(rep,'pdf') && satkproject.str2logical(rep.pdf,false)
    artifacts.pdf = fullfile(outputDir,'TestReport.pdf');
    tr.addPlugin(TestReportPlugin.producingPDF(artifacts.pdf,'IncludingPassingDiagnostics',true,'IncludingCommandWindowText',true));
end
tr.ArtifactsRootFolder = outputDir;
useParallel = satkproject.str2logical(parallel,false);
if useParallel
    results = tr.runInParallel(suite);
else
    results = tr.run(suite);
end
out = summarizeUnittest(results, test_file, artifacts, outputDir);
end

function out = summarizeUnittest(results, test_file, artifacts, outputDir)
n = numel(results);
failed = [results.Failed];
incomplete = [results.Incomplete];
passed = [results.Passed];
fails = repmat(struct('name','','failed',false,'incomplete',false,'duration',0,'diagnostics',''),0,1);
for i=1:n
    if failed(i) || incomplete(i)
        item = struct('name',results(i).Name,'failed',failed(i),'incomplete',incomplete(i),'duration',results(i).Duration,'diagnostics','');
        try item.diagnostics = evalc('disp(results(i).Details)'); catch, end
        fails(end+1,1) = item; %#ok<AGROW>
    end
end
status = 'passed'; if any(failed) || any(incomplete), status = 'failed'; end
out = struct('status',status,'test_file',test_file,'total',n,'passed',sum(passed), ...
    'failed',sum(failed),'incomplete',sum(incomplete),'failures',fails,'artifacts',artifacts,'output_dir',outputDir);
end
