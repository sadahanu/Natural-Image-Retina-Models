function el = getUniqueEpochsFromNodes(nodes)
%Use tree ancestry to pick unique Epochs from multiple EpochTree nodes
%
%   el = getUniqueEpochsFromNodes(nodes)
%
%   el is a new auimodel.EpochList containing all the unique Epochs under
%   EpochTree nodes in nodes.
%
%   nodes is a cell array of EpochTree nodes.  They may be overlapping or
%   disjoint subtrees.
%
%%%SU
%	tree = getFixtureTree;
%	leaves = tree.leafNodes.toCell;
% 
%	% leaves (disjoint)
%	disjointNodes = {leaves{1}, leaves{2}};
%	disjointExpected = leaves{1}.epochList.length + leaves{2}.epochList.length;
%	disjointUnique = getUniqueEpochsFromNodes(disjointNodes);
%	disjointLength = disjointUnique.length;
% 
%   % parent, child leaf, and disjoint leaf
%   mixedNodes = {leaves{2}.parent, leaves{1}, leaves{2}};
%   parentList = getTreeEpochs(leaves{2}.parent);
%   mixedExpected = parentList.length + leaves{1}.epochList.length;
%   mixedUnique = getUniqueEpochsFromNodes(mixedNodes);
%   mixedLength = mixedUnique.length;
% 
%   % trunk
%   trunkList = getTreeEpochs(tree);
%   trunkExpected = trunkList.length;
%   trunkUnique = getUniqueEpochsFromNodes({tree});
%   trunkLength = trunkUnique.length;
% 
%   % trunk, child, redundant leaf, and disjoint leaf
%   mixedWithTrunk = {tree, leaves{2}.parent, leaves{1}, leaves{2}};
%   mixedWithTrunkExpected = trunkExpected;
%   mixedWithTrunkUnique = getUniqueEpochsFromNodes(mixedWithTrunk);
%   mixedWithTrunkLength = mixedWithTrunkUnique.length;
%
%   clear('tree', 'leaves');
%   clear('disjointNodes', 'mixedNodes', 'trunkUnique', 'mixedWithTrunkUnique');
%   clear('disjointUnique', 'mixedUnique', 'mixedWithTrunk');
%%%TS disjointExpected==disjointLength
%%%TS mixedExpected==mixedLength
%%%TS trunkExpected==trunkLength
%%%TS mixedWithTrunkExpected==mixedWithTrunkLength

listFactory = edu.washington.rieke.Analysis.getEpochListFactory();
el = listFactory.create();
nodeArray = [nodes{:}];
for ii = 1:length(nodeArray)
    if nodeArrayContainsNodeAncestor(nodeArray, nodeArray(ii))
        continue
    else
        %testList = getTreeEpochs(nodeArray(ii));
        el.append(getTreeEpochs(nodeArray(ii)), true);
        %keyboard;
    end
end

function isContained = nodeArrayContainsNodeAncestor(nodeArray, node)
isContained = false;
ancestor = node.parent;
while isobject(ancestor)
    if any(ancestor == nodeArray)
        isContained = true;
        return
    end
    ancestor = ancestor.parent;
end

