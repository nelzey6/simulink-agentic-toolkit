function results = validate_model_project_tools(toolkitRoot)
%VALIDATE_MODEL_PROJECT_TOOLS Validate model project/harness/Test Manager MCP registration.
%   This lightweight validation checks that public tool metadata and MATLAB
%   entry points are aligned, and that stale pre-rename tool names are absent.
if nargin < 1 || strlength(string(toolkitRoot)) == 0
    toolkitRoot = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
end
toolkitRoot = char(java.io.File(toolkitRoot).getCanonicalPath());
addpath(genpath(fullfile(toolkitRoot, 'tools', 'common')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_project')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_harness')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_test_manager')));

toolNames = [
    "model_project_setup"
    "model_project_inventory"
    "model_harness_list"
    "model_harness_create"
    "model_harness_open"
    "model_harness_save"
    "model_harness_close"
    "model_test_manager_list"
    "model_test_manager_create_case"
    "model_test_manager_configure_case"
    "model_test_manager_run"
    "model_test_manager_results"
];
staleNames = [
    "repo_setup"
    "repo_inventory"
    "harness_list"
    "harness_create"
    "harness_open"
    "harness_save"
    "harness_close"
    "test_manager_list"
    "test_manager_create_case"
    "test_manager_configure_case"
    "test_manager_run"
    "test_manager_results"
];

toolsFile = fullfile(toolkitRoot, 'tools', 'tools.json');
registryFile = fullfile(toolkitRoot, 'tools', 'registry.json');
toolsJson = jsondecode(fileread(toolsFile));
registryJson = jsondecode(fileread(registryFile));
registered = string({toolsJson.tools.name});
registryFields = string(fieldnames(registryJson.tools));

missingFunctions = strings(0,1);
missingToolsJson = strings(0,1);
missingRegistry = strings(0,1);
for i = 1:numel(toolNames)
    name = toolNames(i);
    if isempty(which(char(name)))
        missingFunctions(end+1,1) = name; %#ok<AGROW>
    end
    if ~any(registered == name)
        missingToolsJson(end+1,1) = name; %#ok<AGROW>
    end
    if ~any(registryFields == name)
        missingRegistry(end+1,1) = name; %#ok<AGROW>
    end
end
staleInTools = staleNames(ismember(staleNames, registered));
staleInRegistry = staleNames(ismember(staleNames, registryFields));

failed = ~isempty(missingFunctions) || ~isempty(missingToolsJson) || ~isempty(missingRegistry) || ~isempty(staleInTools) || ~isempty(staleInRegistry);
results = struct();
if failed
    results.status = "failed";
else
    results.status = "passed";
end
results.toolkitRoot = toolkitRoot;
results.checkedTools = cellstr(toolNames);
results.missingFunctions = cellstr(missingFunctions);
results.missingToolsJson = cellstr(missingToolsJson);
results.missingRegistry = cellstr(missingRegistry);
results.staleInToolsJson = cellstr(staleInTools(:));
results.staleInRegistry = cellstr(staleInRegistry(:));
if failed
    error('validate_model_project_tools:Failed', 'Model project tool validation failed. Inspect returned results for details.');
end
end
