function V = splitOnRodConeLevel(epoch)
keyInd = epoch.keywords.contains('rod light level');
if keyInd
    V = 'rod'; 
else
    V = 'cone';
end
    
