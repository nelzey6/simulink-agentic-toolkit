function out = modelContext(req)
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
summary = satkcache.analyze(summaryReq);
interfaces = satkcache.analyze(interfacesReq);
connections = satkcache.analyze(connectionsReq);
out = struct();
out.schemaVersion = 1;
out.tool = 'model_context';
out.source = 'cache-first';
out.task = req.task;
out.projectRoot = ctx.projectRoot;
out.project = satkcache.projectInfo(ctx.projectRoot);
out.model = ctx.modelFile;
out.modelName = ctx.modelName;
out.resolvedScope = resolvedScope;
out.budget = req.budget;
out.candidateScopes = candidates;
out.context = satkcache.compactContext(summary, interfaces, connections);
out.targetedParams = satkcache.targetedParams(resolvedScope);
out.findings = satkcache.basicFindings(ctx);
out.ambiguity = struct('candidateCount',numel(candidates),'needsUserChoice',numel(candidates)>1);
out.cache = struct('root',ctx.cacheRoot,'policy',req.cachePolicy);
out.nextActions = satkcache.suggestNextActions(resolvedScope);
end
