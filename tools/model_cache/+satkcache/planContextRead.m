function plan = planContextRead(~, resolvedScope, summary, freshness)
%PLANCONTEXTREAD Deterministic cache-first, shallow-by-default context plan.
%   This planner bases decisions on cache freshness, scope size, and
%   root-vs-target scope.
summaryBlocks = 0;
try
    summaryBlocks = summary.summary.totalBlocksAtDepth;
catch
end
modelName = '';
try
    modelName = char(summary.modelName);
catch
end
scopeText = char(resolvedScope);
isRoot = strcmp(scopeText, 'root') || strcmp(scopeText, modelName);
largeScope = summaryBlocks > 50;

plan = struct();
plan.planner = 'scope-aware-cache-planner';
plan.strategy = 'cache-first shallow-by-default';
plan.summary = 'refresh_or_use_cache';
plan.interfaces = 'refresh_or_use_cache';
plan.connections = 'use_fresh_cache_or_skip';
plan.reason = ['Use cached model context as grounding. Refresh shallow summary/interfaces when stale or missing. ' ...
    'Use cached connections when fresh; otherwise refresh only for small/narrow scopes and skip broad live scans.'];
plan.confidence = 'high';
plan.allowBroadDeep = false;
plan.maxDefaultDepth = '0';
plan.scope = scopeText;
plan.scopeKind = 'target';
if isRoot, plan.scopeKind = 'root'; end
plan.scopeSize = struct('blocksAtDepth', summaryBlocks, 'largeScope', largeScope);
plan.cacheStates = freshness;

hasFreshConnections = false;
for i = 1:numel(freshness)
    if strcmp(freshness(i).detail, 'connections') && strcmp(freshness(i).state, 'fresh')
        hasFreshConnections = true;
        break;
    end
end
if hasFreshConnections
    plan.connections = 'use_cache';
elseif ~largeScope
    plan.connections = 'refresh_target_shallow';
else
    plan.connections = 'skip_live_refresh';
end

if strcmp(plan.connections, 'skip_live_refresh')
    plan.reason = [plan.reason ' The current scope is large and has no fresh connection cache, so live connection refresh is skipped until a narrower target is selected.'];
elseif strcmp(plan.connections, 'refresh_target_shallow')
    plan.reason = [plan.reason ' The current scope is small enough for a shallow connection refresh.'];
end

plan.avoid = struct('tool','model_read','args',struct('scope','root','depth','inf'), ...
    'reason','Broad deep reads are not a default action; use cached context and targeted shallow reads first.');
end
