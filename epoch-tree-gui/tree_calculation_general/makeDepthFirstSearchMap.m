function M = makeDepthFirstSearchMap(node)
%this is meant to grab the keys, the values are overwritten, so should not
%be used

%make search map for this node
M = makeNodeSearchMap(node); 
if node.isLeaf %base case: node is leaf
    return;
else %recursive case, append seach map for each child
    for i=1:length(node.children)
        M = [M; makeDepthFirstSearchMap(node.children.valueByIndex(i))]; 
    end
end