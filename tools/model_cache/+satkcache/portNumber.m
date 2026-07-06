function n = portNumber(h)
try
    n = str2double(get_param(h,'PortNumber'));
catch
    n = NaN;
end
end
