function V = splitOnSet(epoch)
keyInd = strmatch('set',epoch.keywords.elements);    
if length(keyInd)==1
    [null, level] = strtok(epoch.keywords.elements{keyInd});
    V = str2double(level); 
else
    V = 'null';
end
    
