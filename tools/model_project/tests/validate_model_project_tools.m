function results = validate_model_project_tools(toolkitRoot)
%VALIDATE_MODEL_PROJECT_TOOLS Validate the simplified public tool contract.
if nargin < 1 || strlength(string(toolkitRoot)) == 0
    toolkitRoot = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
end
toolkitRoot = char(java.io.File(toolkitRoot).getCanonicalPath());
addpath(genpath(fullfile(toolkitRoot, 'tools', 'common')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_cache')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_project')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_test_manager')));

retained = [
    "model_context"
    "model_cache_invalidate"
    "model_project_inventory"
    "model_test_manager_author"
    "model_test_manager_list"
    "model_test_manager_run"
];
removed = [
    "model_cache_status"
    "model_cache_get"
    "model_cache_update"
    "model_analyze_cached"
    "model_project_setup"
    "model_harness_list"
    "model_harness_create"
    "model_harness_open"
    "model_harness_save"
    "model_harness_close"
    "model_test_manager_create_case"
    "model_test_manager_configure_case"
    "model_test_manager_results"
];
expectedOrder = struct();
expectedOrder.model_context = {'task','model','scope','cachePolicy'};
expectedOrder.model_cache_invalidate = {'model'};
expectedOrder.model_project_inventory = {'repo'};
expectedOrder.model_test_manager_author = {'test_file','suite','test_case','definition'};
expectedOrder.model_test_manager_list = {'test_file'};
expectedOrder.model_test_manager_run = {'test_file','tests','parallel','report'};

toolsJson = jsondecode(fileread(fullfile(toolkitRoot, 'tools', 'tools.json')));
registryJson = jsondecode(fileread(fullfile(toolkitRoot, 'tools', 'registry.json')));
toolNames = string({toolsJson.tools.name});
registryNames = string(fieldnames(registryJson.tools));
signatureNames = string(fieldnames(toolsJson.signatures));
problems = strings(0,1);

for i = 1:numel(retained)
    name = retained(i);
    if isempty(which(char(name))), problems(end+1) = name + " function missing"; end %#ok<AGROW>
    if ~any(toolNames == name), problems(end+1) = name + " missing from tools.json"; end %#ok<AGROW>
    if ~any(registryNames == name), problems(end+1) = name + " missing from registry.json"; end %#ok<AGROW>
    if ~any(signatureNames == name), problems(end+1) = name + " signature missing"; end %#ok<AGROW>
    if any(toolNames == name) && any(registryNames == name)
        tool = toolsJson.tools(find(toolNames == name,1));
        registered = registryJson.tools.(char(name));
        if ~isequaln(tool.inputSchema, registered.inputSchema)
            problems(end+1) = name + " schema mismatch"; %#ok<AGROW>
        end
        propertyNames = fieldnames(tool.inputSchema.properties);
        for j = 1:numel(propertyNames)
            property = tool.inputSchema.properties.(propertyNames{j});
            if ~isfield(property, 'type') || ...
                    ~any(string(property.type) == ["string","number","integer","boolean"])
                problems(end+1) = name + "." + propertyNames{j} + ...
                    " uses an unsupported MATLAB MCP extension argument type"; %#ok<AGROW>
            end
        end
    end
    if any(signatureNames == name)
        actual = toolsJson.signatures.(char(name)).input.order;
        if ~isequal(cellstr(string(actual(:))), expectedOrder.(char(name))(:))
            problems(end+1) = name + " argument order mismatch"; %#ok<AGROW>
        end
    end
end

for i = 1:numel(removed)
    name = removed(i);
    if any(toolNames == name), problems(end+1) = name + " remains in tools.json"; end %#ok<AGROW>
    if any(registryNames == name), problems(end+1) = name + " remains in registry.json"; end %#ok<AGROW>
    if any(signatureNames == name), problems(end+1) = name + " signature remains"; end %#ok<AGROW>
end

context = registryJson.tools.model_context.inputSchema;
if ~isequal(string(context.properties.cachePolicy.enum(:)), ["use-if-fresh";"cache-only";"force-refresh"])
    problems(end+1) = "model_context cache policies differ from contract";
end
if isfield(context.properties,'budget'), problems(end+1) = "model_context budget remains"; end
if isfield(registryJson.tools.model_project_inventory.inputSchema.properties,'cachePolicy')
    problems(end+1) = "project inventory cache policy remains";
end
author = registryJson.tools.model_test_manager_author.inputSchema;
if ~isequal(cellstr(string(author.required(:))), {'test_file';'suite';'test_case';'definition'})
    problems(end+1) = "model_test_manager_author required inputs differ from contract";
end
definition = author.properties.definition;
if ~strcmp(string(definition.type), "string")
    problems(end+1) = "model_test_manager_author definition must use the JSON-string transport";
end

results = struct('status','passed','toolkitRoot',toolkitRoot,'retained',{cellstr(retained)}, ...
    'removed',{cellstr(removed)},'problems',{cellstr(problems)});
if ~isempty(problems)
    error('validate_model_project_tools:Failed','%s',strjoin(cellstr(problems),newline));
end
end
