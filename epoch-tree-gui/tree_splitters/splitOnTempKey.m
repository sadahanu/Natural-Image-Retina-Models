function V = splitOnTempKey(epoch)
keyInd1 = epoch.keywords.contains('washing');    
keyInd2 = epoch.keywords.contains('X_pathways');    
keyInd3 = epoch.keywords.contains('adapting');  
keyInd4 = epoch.keywords.contains('X_tex');  
keyInd5 = epoch.keywords.contains('weakResponse');  
keyInd6 = epoch.keywords.contains('X_udsteps');
%keyInd4 = epoch.keywords.contains('NBQX');   
if keyInd1 || keyInd2 || keyInd3 || keyInd4 || keyInd5 || keyInd6
    V = 'bad'; 
else
    V = 'ok';
end
    
