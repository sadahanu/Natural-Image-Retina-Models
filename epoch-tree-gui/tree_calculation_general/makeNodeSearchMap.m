function M = makeNodeSearchMap(node)

M = containers.Map;
if node.isLeaf
    SampleEpoch = node.epochList.firstValue;
    
    %map in protocol settings
    fnames = SampleEpoch.protocolSettings.keySet.toArray;
    for f=1:length(fnames)
        M(['protocolSettings.' fnames(f)]) = SampleEpoch.protocolSettings.get(fnames(f));
    end
    
    
    %getNepochs
    M('nEpochs') = node.epochList.length;
end

%other parameters:
M('splitValue') = node.splitValue;
%M('splitValues') = node.splitValues;
M('splitKey') = node.splitKey;

%split keys
Msplits = node.splitValues;
keyArray = Msplits.keySet.toArray;
for i=1:length(keyArray)
   key_str = keyArray(i);
   M(key_str) = Msplits.get(key_str);
end

customProps = node.custom; 

%remove this stuff for now
%if isfield(customProps,'keywordMap')
%    M = [M; customProps.keywordMap'];
%end

resultsMap = customProps.get('results');
if ~isempty(resultsMap)
    %map in calculations
    fnames = resultsMap.keySet.toArray;
    for f=1:length(fnames)
        M(['results.' fnames(f)]) = resultsMap.get(fnames(f));
    end
end