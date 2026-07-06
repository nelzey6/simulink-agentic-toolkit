function result = setupCacheAwareSATK(action, varargin)
%SETUPCACHEAWARESATK Bootstrap the cache-aware SATK fork for local MCP use.
%   setupCacheAwareSATK("install") adds this fork to the MATLAB path, runs
%   satk_initialize, and optionally writes a Pi MCP config that points to this
%   fork's tools/tools.json.
%
%   Name-value options:
%     ConfigurePiMCP (logical) default true
%     MCPConfigPath   (string)  default ~/.config/mcp/mcp.json
%     MCPServerPath   (string)  optional existing matlab-mcp-server executable
%     MatlabRoot      (string)  optional MATLAB root for MCP server args
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
addpath(genpath(fullfile(repoRoot, 'tools', 'model_cache')));

switch lower(action)
    case "install"
        if exist('satk_initialize', 'file') == 2 || exist('satk_initialize', 'file') == 6
            satk_initialize;
        else
            warning('setupCacheAwareSATK:satkInitializeMissing', ...
                'satk_initialize was not found on the MATLAB path.');
        end
        if opts.ConfigurePiMCP
            writePiMcpConfig(opts.MCPConfigPath, opts.MCPServerPath, opts.MatlabRoot, toolsFile);
        end
        result = verifyInstall(repoRoot, toolsFile, opts);
        printResult(result);
    case "verify"
        result = verifyInstall(repoRoot, toolsFile, opts);
        printResult(result);
    otherwise
        error('setupCacheAwareSATK:UnknownAction', 'Unknown action: %s', action);
end
end

function opts = parseOptions(varargin)
opts = struct();
opts.ConfigurePiMCP = true;
opts.MCPConfigPath = fullfile(char(java.lang.System.getProperty('user.home')), '.config', 'mcp', 'mcp.json');
opts.MCPServerPath = '';
opts.MatlabRoot = matlabroot;
if mod(numel(varargin),2) ~= 0
    error('setupCacheAwareSATK:InvalidOptions', 'Options must be name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = char(string(varargin{i}));
    value = varargin{i+1};
    switch lower(name)
        case 'configurepimcp'
            opts.ConfigurePiMCP = logical(value);
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

function writePiMcpConfig(configPath, serverPath, matlabRootValue, toolsFile)
if isempty(serverPath)
    candidates = {
        fullfile(char(java.lang.System.getProperty('user.home')), '.matlab', 'agentic-toolkits', 'bin', 'matlab-mcp-server.exe')
        fullfile(fileparts(fileparts(fileparts(toolsFile))), 'bin', 'matlab-mcp-server.exe')
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
cfg = struct();
cfg.mcpServers = struct();
matlabServer = struct();
matlabServer.command = serverPath;
matlabServer.args = {['--matlab-root=' matlabRootValue], ['--extension-file=' toolsFile], '--disable-telemetry=true'};
matlabServer.lifecycle = 'lazy';
matlabServer.idleTimeout = 10;
cfg.mcpServers.matlab = matlabServer;
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

function result = verifyInstall(repoRoot, toolsFile, opts)
result = struct();
result.repoRoot = repoRoot;
result.toolsFile = toolsFile;
result.toolsFileExists = isfile(toolsFile);
result.modelContext = which('model_context');
result.cacheInvalidate = which('model_cache_invalidate');
result.satkInitialize = which('satk_initialize');
result.mcpConfigPath = opts.MCPConfigPath;
result.mcpConfigExists = isfile(opts.MCPConfigPath);
result.ok = result.toolsFileExists && ~isempty(result.modelContext) && ~isempty(result.cacheInvalidate);
end

function printResult(result)
fprintf('\nCache-aware SATK setup\n');
fprintf('======================\n');
fprintf('Repo root:      %s\n', result.repoRoot);
fprintf('Tools file:     %s\n', result.toolsFile);
fprintf('model_context:  %s\n', result.modelContext);
fprintf('invalidate:     %s\n', result.cacheInvalidate);
fprintf('satk_init:      %s\n', result.satkInitialize);
fprintf('MCP config:     %s\n', result.mcpConfigPath);
fprintf('Result:         %s\n\n', string(result.ok));
end
