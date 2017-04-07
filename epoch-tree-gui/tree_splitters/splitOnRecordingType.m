function V = splitOnRecordingType(epoch)
if epoch.keywords.contains('CA')
    V = 'cell-attached';
else
    V = 'whole-cell';
end
    
