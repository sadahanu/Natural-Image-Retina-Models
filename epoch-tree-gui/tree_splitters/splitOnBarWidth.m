function V = splitOnBarWidth(epoch)
V = epoch.protocolSettings.get('stimuli:Amp_1:BarWidth');
if V > epoch.protocolSettings.get('stimuli:Amp_1:spotRadius')*2 %larger than mask
    V = epoch.protocolSettings.get('stimuli:Amp_1:spotRadius')*2;
end
