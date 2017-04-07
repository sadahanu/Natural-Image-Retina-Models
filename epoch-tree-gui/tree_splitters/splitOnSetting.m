function V = splitOnSetting(epoch,setting)
alternateName = strrep(setting,'Amp._1','Amp_1'); %for exp mapped w 2 amps
if epoch.protocolSettings.containsKey(setting)
    V = epoch.protocolSettings.get(setting);
else
    V = epoch.protocolSettings.get(alternateName);
end

%V
%pause;