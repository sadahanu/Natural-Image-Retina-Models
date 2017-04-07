function [] = runTreeCalculation(nodes,C)
%nodes is an array of nodes returned by getTreeLevel
%C is a TreeCalculation structure:
%it must have a func field with the function handle and a params field with
%the params

params = C.params;
%check if there are any downTreeParams
Dset = [];
DparamNames = {};
if isempty(params)
    f= [];
else
    f = fieldnames(params);
end
for i=1:length(f)
    if strcmp(class(params.(f{i})), 'DownTreeParam');
        DparamNames = [DparamNames f{i}];
        Dset = [Dset params.(f{i})];     
    elseif ~isempty(params.(f{i})) && strcmp(params.(f{i})(1), '@') %@ specifies downTree param
        DparamNames = [DparamNames f{i}];
        Dset = [Dset DownTreeParam(params.(f{i})(2:end))];
    end
end

L = length(nodes);
for i=1:L %for each node
    disp(['Node ' num2str(i) ' of ' num2str(L)]); 
    curNode = nodes(i);
    %set downTree params
    if ~isempty(Dset)
        for d=1:length(Dset)
            params.(DparamNames{d}) = setDownTreeParam(curNode,Dset(d));
        end
    end
    
    %run calculation
    resultStruct = C.func(curNode,params);
    
    if ~isempty(resultStruct)
        %affix results to nods
        resultMap = riekesuite.util.toJavaMap(resultStruct);
        
        if isempty(curNode.custom.get('results')); %make new results field if needed
            curNode.custom.put('results',resultMap);
        else %concatenate to old results
            results = curNode.custom.get('results');
            allKeys = resultMap.keySet;
            iter = allKeys.iterator;
            while iter.hasNext
                curKey = iter.next;
                results.put(curKey,resultMap.get(curKey));
                %note, could ask about overwite here, now just overwrites by
                %default
%                keyboard;
            end
            curNode.custom.put('results',results);
        end
    end
end



