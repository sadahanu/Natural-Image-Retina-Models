function nodes = getTreeLevel(node,levelSplit,filt)
%node is the root node / tree
%levelSplit is 1) the stringified version of the level you want to return
%it should match what is in the "splitValues" field
%alternatively, levelSplit can be an integer N: in this case it will return
%the level N down from the current level, i.e. node.splitKeyPaths(N)
%filt is an optional TreeSearchQuery applied to the result

nodes = [];
doFilt = 0;

if isnumeric(levelSplit) && isscalar(levelSplit)
   if levelSplit>length(node.splitKeyPaths)
       error(['Asked for level ' num2str(levelSplit) ' but tree has ' num2str(length(node.splitKeyPaths)) ' levels']);
   elseif levelSplit == 0
       %return root
       nodes = node;
       return
   end
   levelSplit = char(node.splitKeyPaths(levelSplit));
elseif strcmp(levelSplit, 'leaf') %if 'leaf', get leaves
    levelSplit = char(node.splitKeyPaths(length(node.splitKeyPaths)));
end    

if exist('filt','var')
    if ~strcmp(class(filt),'TreeSearchQuery')
        error('Filter must be a TreeSearchQuery object');
    else %run filter
        %disp('running filter')
        %save current selection state
        state = saveSelectionState(node);
        %run filter
        runFilter(node,filt.makeQueryString,1);
        doFilt = 1;
    end
end

if ~node.splitValues.containsKey(levelSplit) %above correct level
    if ~isempty(node.children)
        for i=1:node.children.length %call on all children
            nodes = [nodes, getTreeLevel(node.children.valueByIndex(i),levelSplit)];
        end
    end
else %has split key
    if node.custom.get('isSelected') %did match and selected
        nodes = [nodes, node];
    end
end

if doFilt
    %set old selection state
    setSelectionState(node,state);
end