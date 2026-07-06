function actions = suggestNextActions(scope)
actions = struct('tool',{},'reason',{},'cost',{});
actions(1) = struct('tool','model_query_params','reason',['Query selected parameters for ' char(scope)],'cost','cheap-live-targeted');
actions(2) = struct('tool','model_read','reason',['Use only if algorithmic expressions are needed for ' char(scope)],'cost','medium');
actions(3) = struct('tool','model_check','reason','Run scoped structural checks after edits','cost','medium');
end
