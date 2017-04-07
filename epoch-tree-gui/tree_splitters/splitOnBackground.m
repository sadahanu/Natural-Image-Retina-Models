function V = splitOnBackground(epoch)
keyInd = strmatch('bg',epoch.keywords.elements);    
if length(keyInd)==1
    [null, level] = strtok(epoch.keywords.elements{keyInd},'=');
    V = str2double(level(2:end)); 
else
    V = 'null';
end
    
