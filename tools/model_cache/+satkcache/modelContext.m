function out = modelContext(req)
%MODELCONTEXT Cache-first model working context and read planner.
model = satkcache.resolveAutoModel(req.model);
ctx = satkcache.context(model, 'root', 'summary');
satkcache.ensureLoaded(ctx.modelFile);
index = satkcache.blockIndex(ctx, req.cachePolicy);
[candidates, resolvedScope] = satkcache.resolveScope(req, index, ctx);
if strcmp(resolvedScope,'auto') || isempty(resolvedScope)
    resolvedScope = 'root';
end
summaryReq = struct('model',ctx.modelFile,'scope',resolvedScope,'detail','summary','depth','1','compile',false,'cachePolicy',req.cachePolicy);
interfacesReq = summaryReq; interfacesReq.detail = 'interfaces';
connectionsReq = summaryReq; connectionsReq.detail = 'connections';

% Cache-first alibi: inspect freshness before any live refresh, then update only
% the compact shallow records needed for safe orientation.
freshnessBefore = satkcache.cacheFreshness({summaryReq, interfacesReq, connectionsReq});
summary = satkcache.analyze(summaryReq);
interfaces = satkcache.analyze(interfacesReq);
plan = satkcache.planContextRead(req, resolvedScope, summary, freshnessBefore);
connections = maybeConnections(connectionsReq, plan, freshnessBefore);
freshnessAfter = satkcache.cacheFreshness({summaryReq, interfacesReq, connectionsReq});

out = struct();
out.schemaVersion = 1;
out.tool = 'model_context';
out.source = 'cache-first planner';
out.task = req.task;
out.projectRoot = ctx.projectRoot;
out.project = satkcache.projectInfo(ctx.projectRoot);
out.model = ctx.modelFile;
out.modelName = ctx.modelName;
out.resolvedScope = resolvedScope;
out.budget = req.budget;
out.planner = plan.planner;
out.readPlan = plan;
out.candidateScopes = candidates;
out.context = satkcache.compactContext(summary, interfaces, connections);
out.targetedParams = satkcache.targetedParams(resolvedScope);
out.findings = satkcache.basicFindings(ctx);
out.ambiguity = struct('candidateCount',numel(candidates),'needsUserChoice',numel(candidates)>1);
out.cache = struct('root',ctx.cacheRoot,'policy',req.cachePolicy,'freshnessBefore',freshnessBefore,'freshnessAfter',freshnessAfter);
out.nextActions = satkcache.suggestNextActions(resolvedScope, plan);
end

function connections = maybeConnections(connectionsReq, plan, freshness)
connections = struct();
connections.detail = 'connections';
connections.connections = [];
if strcmp(plan.connections, 'use_cache')
    connectionsReq.cachePolicy = 'cache-only';
    cached = satkcache.analyze(connectionsReq);
    if ~isfield(cached,'error')
        connections = cached;
        return;
    end
end
if strcmp(plan.connections, 'refresh_target_shallow')
    connections = satkcache.analyze(connectionsReq);
    return;
end
% If live refresh was skipped but a stale/missing cache exists, report why in a
% JSON-friendly placeholder instead of spending tokens/time on broad scans.
connections.source = 'skipped';
connections.skipReason = plan.reason;
connections.cacheState = connectionState(freshness);
end

function state = connectionState(freshness)
state = 'unknown';
for i = 1:numel(freshness)
    if strcmp(freshness(i).detail, 'connections')
        state = freshness(i).state;
        return;
    end
end
end
