function sid = safeSID(block)
try
    sid = Simulink.ID.getSID(block);
catch
    sid = '';
end
end
