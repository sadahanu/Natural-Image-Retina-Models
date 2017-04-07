function V = setDownTreeParam(node,D)
%node is the start node/tree
%D is a a DownTreeParam object

V = java.util.Vector;

levelDefined = 0;
if ~isempty(D.treeLevel)
    levelDefined = 1;
    if ~isempty(D.filt)
        disp('using filter');
        nodesToSearch = getTreeLevel(node,D.treeLevel,D.filt);
    else
        nodesToSearch = getTreeLevel(node,D.treeLevel);
    end
else %treeLevel is blank, so start with level 1 (children)
    nLevels = length(node.splitKeyPaths);
    searchLevel = 1;
    nodesToSearch = getTreeLevel(node,searchLevel);
end

%length(nodesToSearch)
%pause;

%if treeLevel is blank, find the correct level
paramFound = 0;

L = length(nodesToSearch);
for i=1:L
    M = makeNodeSearchMap(nodesToSearch(i));
    if M.isKey(D.paramName)
        V.addElement(M(D.paramName))
        paramFound = 1;
    end
end

if ~paramFound && ~levelDefined %search deeper
    while ~paramFound && searchLevel<nLevels
        searchLevel = searchLevel+1;
        nodesToSearch = getTreeLevel(node,searchLevel);
        L = length(nodesToSearch);
        for i=1:L
            M = makeNodeSearchMap(nodesToSearch(i));
            if M.isKey(D.paramName)
                V.addElement(M(D.paramName))
                paramFound = 1;
            end
        end
    end
end

if ~paramFound
    error(['Parameter ' D.paramName ' not found']);
end

V = javaVecToMatlab(V);


