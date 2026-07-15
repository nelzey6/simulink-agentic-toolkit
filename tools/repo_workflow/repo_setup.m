function out = repo_setup(repo, startup, toolkit_root)
%REPO_SETUP Prepare MATLAB for an OA/SATK Simulink repository workflow.
if nargin < 1 || strlength(string(repo)) == 0, repo = 'auto'; end
if nargin < 2 || strlength(string(startup)) == 0, startup = 'matlab/startup.m'; end
if nargin < 3, toolkit_root = ''; end
repo = satkrepo.resolveRepoRoot(repo);
startup = char(string(startup));
if ~isempty(toolkit_root) && strlength(string(toolkit_root)) > 0 && isfolder(toolkit_root)
    addpath(char(string(toolkit_root)));
end
if exist('satk_initialize', 'file') == 2 || exist('satk_initialize', 'file') == 6
    try
        satk_initialize;
    catch ME
        satkWarning = ME.message;
    end
else
    satkWarning = 'satk_initialize not found on MATLAB path';
end
startupPath = startup;
if ~isfile(startupPath)
    startupPath = fullfile(repo, startup);
end
if ~isfile(startupPath)
    error('repo_setup:StartupNotFound', 'Startup file not found: %s', startup);
end
startupDir = fileparts(startupPath);
cd(startupDir);
try
    run(startupPath);
    startupStatus = 'ok';
catch ME
    startupStatus = 'error';
    startupError = ME.message;
end
inv = repo_inventory(repo, 'force-refresh');
out = struct();
out.status = startupStatus;
out.repo = repo;
out.cwd = pwd;
out.startup = startupPath;
out.matlab_release = version('-release');
out.simulink_available = license('test','Simulink');
out.simulink_test_available = satkrepo.toolboxAvailable('Simulink Test');
out.tool_paths = struct('model_read', which('model_read'), 'model_edit', which('model_edit'), ...
    'model_check', which('model_check'), 'model_test', which('model_test'));
out.inventory = inv;
if exist('satkWarning','var'), out.warning = satkWarning; end
if exist('startupError','var'), out.error = startupError; end
end
