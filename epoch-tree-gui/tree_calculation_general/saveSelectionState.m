function state = saveSelectionState(tree)
state = tree.custom.put('isSelected', 1);
if ~isempty(tree.children)
    for i=1:tree.children.length
        state = [state saveSelectionState(tree.children.valueByIndex(i))];         
    end
end