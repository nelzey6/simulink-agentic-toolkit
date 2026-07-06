function info = projectInfo(projectRoot)
info = struct('projectRoot',projectRoot,'startupScript','','mainModel','','dataDictionaries',{{}},'notes',{{}});
if isfile(fullfile(projectRoot,'matlab','startup.m')), info.startupScript = fullfile(projectRoot,'matlab','startup.m'); end
slx = dir(fullfile(projectRoot,'**','*.slx'));
if ~isempty(slx), info.mainModel = fullfile(slx(1).folder, slx(1).name); end
dd = dir(fullfile(projectRoot,'**','*.sldd'));
info.dataDictionaries = arrayfun(@(d) fullfile(d.folder,d.name), dd, 'UniformOutput', false);
for f = {fullfile(projectRoot,'MATLAB.md'), fullfile(projectRoot,'mcp.md')}
    if isfile(f{1})
        txt = fileread(f{1});
        m = regexp(txt, 'mainModel"?\s*[:=]\s*"?([^"\n,]+)', 'tokens', 'once');
        if ~isempty(m), info.mainModel = strtrim(m{1}); end
        if contains(txt,'startup.m'), info.notes{end+1} = ['Project notes mention startup.m in ' f{1}]; end %#ok<AGROW>
    end
end
end
