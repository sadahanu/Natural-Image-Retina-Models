function epochData = getSelectedData(epochList, streamName)

%tempData = epochList.responsesByStreamName(streamName);
tempData = riekesuite.getResponseMatrix(epochList, streamName);
for epoch = 1:epochList.length
    isSelected(epoch) = epochList.valueByIndex(epoch).isSelected;
end

selectedEpochs = find(isSelected == 0);
display(selectedEpochs);
epochData = tempData(selectedEpochs, :);

end