function result = setupCacheAwareSATK(action, varargin)
%SETUPCACHEAWARESATK Bootstrap the cache-aware SATK fork for local MCP use.
%   setupCacheAwareSATK("install") adds this fork to the MATLAB path, runs
%   satk_initialize, and writes MCP config for supported agents. By default,
%   Agent="all" configures Pi, Claude Code, Gemini CLI, Amp, and VS Code/Copilot
%   config locations on a best-effort basis.
%
%   Name-value options:
%     Agent          (string)  default "all". all, pi, claude, gemini, amp, vscode, none
%     MCPConfigPath  (string)  optional override for a single custom MCP config
%     MCPServerPath  (string)  optional existing matlab-mcp-server executable
%     MatlabRoot     (string)  optional MATLAB root for MCP server args
%
%   Backward-compatible option:
%     ConfigurePiMCP (logical) false is equivalent to Agent="none"
%
%   Example:
%     addpath("D:/Repos/GitHub/simulink-agentic-toolkit")
%     setupCacheAwareSATK("install")

arguments
    action (1,1) string = "install"
end
arguments (Repeating)
    varargin
end

opts = parseOptions(varargin{:});
repoRoot = fileparts(mfilename('fullpath'));
toolsFile = fullfile(repoRoot, 'tools', 'tools.json');
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, 'tools', 'common')));
addpath(genpath(fullfile(repoRoot, 'tools', 'model_cache')));
addpath(genpath(fullfile(repoRoot, 'tools', 'model_project')));
addpath(genpath(fullfile(repoRoot, 'tools', 'model_harness')));
addpath(genpath(fullfile(repoRoot, 'tools', 'model_test_manager')));

switch lower(action)
    case "install"
        if exist('satk_initialize', 'file') == 2 || exist('satk_initialize', 'file') == 6
            satk_initialize;
        else
            warning('setupCacheAwareSATK:satkInitializeMissing', ...
                'satk_initialize was not found on the MATLAB path.');
        end
        configured = configureAgents(opts, toolsFile);
        result = verifyInstall(repoRoot, toolsFile, opts, configured);
        printResult(result);
    case "verify"
        result = verifyInstall(repoRoot, toolsFile, opts, {});
        printResult(result);
    otherwise
        error('setupCacheAwareSATK:UnknownAction', 'Unknown action: %s', action);
end
end

function opts = parseOptions(varargin)
opts = struct();
opts.Agent = 'all';
opts.MCPConfigPath = '';
opts.MCPServerPath = '';
opts.MatlabRoot = matlabroot;
if mod(numel(varargin),2) ~= 0
    error('setupCacheAwareSATK:InvalidOptions', 'Options must be name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = char(string(varargin{i}));
    value = varargin{i+1};
    switch lower(name)
        case 'agent'
            opts.Agent = lower(char(string(value)));
        case 'configurepimcp'
            if ~logical(value), opts.Agent = 'none'; end
        case 'mcpconfigpath'
            opts.MCPConfigPath = char(string(value));
        case 'mcpserverpath'
            opts.MCPServerPath = char(string(value));
        case 'matlabroot'
            opts.MatlabRoot = char(string(value));
        otherwise
            error('setupCacheAwareSATK:UnknownOption', 'Unknown option: %s', name);
    end
end
end

function configured = configureAgents(opts, toolsFile)
configured = {};
if strcmp(opts.Agent, 'none')
    return;
end
server = matlabServerConfig(opts.MCPServerPath, opts.MatlabRoot, toolsFile);
if ~isempty(opts.MCPConfigPath)
    writeMcpConfig(opts.MCPConfigPath, server, 'mcpServers');
    configured{end+1} = opts.MCPConfigPath;
    return;
end
for entry = agentConfigPaths(opts.Agent)
    configPath = entry{1}.path;
    rootField = entry{1}.rootField;
    try
        writeMcpConfig(configPath, server, rootField);
        configured{end+1} = configPath;
    catch ME
        warning('setupCacheAwareSATK:ConfigWriteFailed', ...
            'Failed to write MCP config %s: %s', configPath, ME.message);
    end
end
end

function entries = agentConfigPaths(agent)
home = char(java.lang.System.getProperty('user.home'));
appdata = getenv('APPDATA');
if isempty(appdata), appdata = fullfile(home, 'AppData', 'Roaming'); end
all = {
    struct('agent','pi',     'path',fullfile(home,'.config','mcp','mcp.json'),              'rootField','mcpServers')
    struct('agent','claude', 'path',fullfile(home,'.claude.json'),                          'rootField','mcpServers')
    struct('agent','gemini', 'path',fullfile(home,'.gemini','settings.json'),               'rootField','mcpServers')
    struct('agent','amp',    'path',fullfile(home,'.config','amp','settings.json'),         'rootField','amp.mcpServers')
    struct('agent','vscode', 'path',fullfile(appdata,'Code','User','mcp.json'),             'rootField','mcpServers')
};
if strcmp(agent,'all')
    entries = all;
else
    entries = all(strcmp(cellfun(@(x) x.agent, all, 'UniformOutput', false), agent));
    if isempty(entries)
        error('setupCacheAwareSATK:UnknownAgent', 'Unknown Agent option: %s', agent);
    end
end
end

function server = matlabServerConfig(serverPath, matlabRootValue, toolsFile)
if isempty(serverPath)
    candidates = {
        fullfile(char(java.lang.System.getProperty('user.home')), '.matlab', 'agentic-toolkits', 'bin', 'matlab-mcp-server.exe')
        'matlab-mcp-server'
    };
    serverPath = candidates{1};
    for i = 1:numel(candidates)
        if isfile(candidates{i}) || strcmp(candidates{i}, 'matlab-mcp-server')
            serverPath = candidates{i};
            break;
        end
    end
end
server = struct();
server.command = serverPath;
server.args = {['--matlab-root=' matlabRootValue], ['--extension-file=' toolsFile], '--disable-telemetry=true'};
server.lifecycle = 'lazy';
server.idleTimeout = 10;
end

function writeMcpConfig(configPath, server, rootField)
cfg = struct();
if isfile(configPath)
    try
        cfg = jsondecode(fileread(configPath));
    catch
        cfg = struct();
    end
end
switch rootField
    case 'mcpServers'
        if ~isfield(cfg,'mcpServers') || ~isstruct(cfg.mcpServers), cfg.mcpServers = struct(); end
        cfg.mcpServers.matlab = server;
    case 'amp.mcpServers'
        if ~isfield(cfg,'amp') || ~isstruct(cfg.amp), cfg.amp = struct(); end
        if ~isfield(cfg.amp,'mcpServers') || ~isstruct(cfg.amp.mcpServers), cfg.amp.mcpServers = struct(); end
        cfg.amp.mcpServers.matlab = server;
end
folder = fileparts(configPath);
if ~exist(folder, 'dir'), mkdir(folder); end
if isfile(configPath)
    backup = [configPath '.bak.' char(datetime('now','Format','yyyyMMddHHmmss'))];
    copyfile(configPath, backup);
end
fid = fopen(configPath, 'w');
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, jsonencode(cfg, PrettyPrint=true));
end

function result = verifyInstall(repoRoot, toolsFile, opts, configured)
result = struct();
result.repoRoot = repoRoot;
result.toolsFile = toolsFile;
result.toolsFileExists = isfile(toolsFile);
result.modelContext = which('model_context');
result.cacheInvalidate = which('model_cache_invalidate');
result.projectInventory = which('model_project_inventory');
result.testManagerList = which('model_test_manager_list');
result.satkInitialize = which('satk_initialize');
result.agent = opts.Agent;
result.configuredConfigs = configured;
result.ok = result.toolsFileExists && ~isempty(result.modelContext) && ~isempty(result.cacheInvalidate) && ...
    ~isempty(result.projectInventory) && ~isempty(result.testManagerList);
end

function printResult(result)
fprintf('\nCache-aware SATK setup\n');
fprintf('======================\n');
fprintf('Repo root:      %s\n', result.repoRoot);
fprintf('Tools file:     %s\n', result.toolsFile);
fprintf('model_context:  %s\n', result.modelContext);
fprintf('invalidate:     %s\n', result.cacheInvalidate);
fprintf('model_project_inventory: %s\n', result.projectInventory);
fprintf('tm_list:        %s\n', result.testManagerList);
fprintf('satk_init:      %s\n', result.satkInitialize);
fprintf('Agent:          %s\n', result.agent);
for i = 1:numel(result.configuredConfigs)
    fprintf('MCP config:     %s\n', result.configuredConfigs{i});
end
fprintf('Result:         %s\n\n', string(result.ok));
end
