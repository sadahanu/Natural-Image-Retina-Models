function V = splitOnGain(epoch)
keyInd = strmatch('gain',epoch.keywords.toArray);    
if length(keyInd)==1    
    keywordArray = epoch.keywords.toArray;
    [null, level] = strtok(keywordArray(keyInd),' ');
    V = str2double(level(2:end)); 
else
    V = 'none';
end
    