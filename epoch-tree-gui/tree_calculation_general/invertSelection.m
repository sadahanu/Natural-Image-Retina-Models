function invertSelection(tree)
if isfield(tree.custom,'isSelected')
    tree.custom.isSelected = abs(tree.custom.isSelected-1);
end
for i=1:length(tree.children)
   invertSelection(tree.children{i}); 
end

