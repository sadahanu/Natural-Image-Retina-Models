function V = splitOnDrugCondition(epoch)
NBQXTrial = epoch.keywords.contains('NBQX');
dopamineTrial = epoch.keywords.contains('dopamine');
SCHTrial = epoch.keywords.contains('SCH');
SKFTrial = epoch.keywords.contains('SKF');
HDXTrial = epoch.keywords.contains('HDX');
TTXTrial = epoch.keywords.contains('TTX');
washTrial = epoch.keywords.contains('wash');
if NBQXTrial
    V = 'NBQX'; 
elseif dopamineTrial
    V = 'dopamine'; 
elseif SKFTrial
    V = 'SKF'; 
elseif SCHTrial
    V = 'SCH'; 
elseif HDXTrial
    V = 'HDX'; 
elseif TTXTrial
    V = 'TTX'; 
elseif washTrial
    V = 'wash';
else
    V = 'ames';
end
    
