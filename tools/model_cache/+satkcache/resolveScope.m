function [candidates, scope] = resolveScope(req, index, ctx)
candidates = struct('path',{},'sid',{},'name',{},'blockType',{},'reason',{});
scope = char(req.scope);
if ~strcmp(scope,'auto') && ~isempty(scope)
    if strcmp(scope,'root'), return; end
    if startsWith(scope,'blk_')
        p = satkcache.resolveBlkAlias(scope, ctx.modelName);
        if ~isempty(p), scope = p; end
    end
    candidates(1) = struct('path',scope,'sid',satkcache.safeSID(scope),'name',satkcache.safeGetParam(scope,'Name'),'blockType',satkcache.safeGetParam(scope,'BlockType'),'reason','explicit scope');
    return;
end
try
    sel = gcb;
    if ~isempty(sel) && startsWith(sel, ctx.modelName)
        candidates(1)=struct('path',sel,'sid',satkcache.safeSID(sel),'name',satkcache.safeGetParam(sel,'Name'),'blockType',satkcache.safeGetParam(sel,'BlockType'),'reason','current Simulink selection');
        scope = sel; return;
    end
catch
end
text = lower([char(req.task) ' ' char(req.scope)]);
words = regexp(text, '[a-zA-Z0-9_]+', 'match');
stopWords = {'the','and','or','not','with','from','into','this','that','model','simulink','logic','change','edit','context','only','want','need','use','using','get','initial','report','tool','used','first','scope','resolved','anything','feature','block'};
words = setdiff(words, stopWords);
for pass=1:2
    for i=1:numel(index.blocks)
        b = index.blocks(i); nm = lower(strtrim(char(b.name))); p = lower(char(b.path));
        hit = false; reason = '';
        if pass==1 && strlength(nm)>=3 && any(strcmp(words,nm))
            hit = true; reason = 'exact block-name token mentioned in task';
        elseif pass==2
            for w = words
                if strlength(w{1})>=4 && (contains(nm,w{1}) || contains(p,w{1}))
                    hit = true; reason = ['partial match: ' w{1}]; break;
                end
            end
        end
        if hit
            candidates(end+1)=struct('path',b.path,'sid',b.sid,'name',b.name,'blockType',b.blockType,'reason',reason); %#ok<AGROW>
        end
        if numel(candidates)>=10, break; end
    end
    if ~isempty(candidates), break; end
end
if ~isempty(candidates), scope = candidates(1).path; else, scope = 'root'; end
if isempty(candidates)
    candidates(1)=struct('path',ctx.modelName,'sid','','name',ctx.modelName,'blockType','block_diagram','reason','fallback to root');
end
end
