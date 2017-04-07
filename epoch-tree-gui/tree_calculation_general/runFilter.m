function [] = runFilter(node,queryString,select)
if nargin==2, select = 1; end
M = makeNodeSearchMap(node);

%apply the filter to this node
try conditionSatisfied = eval(queryString);
    %disp(['conditionsSatisfied: ' num2str(conditionSatisfied)]);
    %all parameters in the query exist if we are here
    if conditionSatisfied
        node.custom.put('isSelected',select);
    else
        node.custom.put('isSelected', abs(select-1)); %invert selection
    end
catch
    %some key not found
    %disp('in catch');
end
%recursive case: run on all children
if ~node.isLeaf
    for i=1:node.children.length
        runFilter(node.children.valueByIndex(i),queryString,select);
    end
end

