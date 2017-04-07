function V = splitOnContrast(epoch)
V = epoch.protocolSettings.get('notes:Amp')/epoch.protocolSettings.get('notes:Mean');
    
