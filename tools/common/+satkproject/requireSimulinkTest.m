function requireSimulinkTest(caller)
%REQUIRESIMULINKTEST Throw a clear error when Simulink Test is unavailable.
if nargin < 1 || strlength(string(caller)) == 0
    caller = 'satkproject';
end
hasTestManager = ~isempty(which('sltest.testmanager.load'));
hasHarness = ~isempty(which('sltest.harness.find'));
if ~hasTestManager && ~hasHarness
    error('%s:SimulinkTestUnavailable', char(string(caller)), ...
        ['Simulink Test is required for this tool, but sltest APIs were not found on the MATLAB path. ' ...
         'Install/license Simulink Test or use model_read/model_edit/model_check for model-only workflows.']);
end
try
    if license('test', 'Simulink_Test') == 0
        warning('%s:SimulinkTestLicenseUnknown', char(string(caller)), ...
            'Simulink Test APIs are on the path, but license(''test'',''Simulink_Test'') returned false. Continuing; MATLAB may still prompt or fail when the API is used.');
    end
catch
end
end
