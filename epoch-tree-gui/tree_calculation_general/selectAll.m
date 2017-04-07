function selectAll(tree)
tree.custom.put('isSelected', 1);
if ~isempty(tree.children)
    for i=1:tree.children.length
        selectAll(tree.children.valueByIndex(i));         
    end
end