function c = compactContext(summary, interfaces, connections)
c = struct();
c.summary = struct('totalBlocksAtDepth',summary.summary.totalBlocksAtDepth,'blockTypes',summary.summary.blockTypes);
maxChildren = min(numel(summary.children), 25);
c.children = summary.children(1:maxChildren);
if isfield(interfaces,'interfaces')
    c.interfaces = interfaces.interfaces(1:min(numel(interfaces.interfaces),25));
else
    c.interfaces = [];
end
if isfield(connections,'connections')
    c.connections = connections.connections(1:min(numel(connections.connections),40));
else
    c.connections = [];
end
c.truncated = struct('children',numel(summary.children)>maxChildren,'interfaces',isfield(interfaces,'interfaces') && numel(interfaces.interfaces)>25,'connections',isfield(connections,'connections') && numel(connections.connections)>40);
end
