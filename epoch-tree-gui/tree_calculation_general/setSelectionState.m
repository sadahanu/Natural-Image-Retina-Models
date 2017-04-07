function state = setSelectionState(tree,state)
if ~exist('ind','var')
    ind = 1;
end
tree.custom.put('isSelected', state(1));
state = state(2:end);
if ~isempty(tree.children)
    for i=1:tree.children.length
        state = setSelectionState(tree.children.valueByIndex(i),state);         
    end
end