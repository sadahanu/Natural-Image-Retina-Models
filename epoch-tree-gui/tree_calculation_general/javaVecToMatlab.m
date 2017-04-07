function resultVec = javaVecToMatlab(V)
if strfind(class(V),'java.lang.Object[]')
    L = V.length;
else
    L = V.size;
end
resultVec = zeros(1,L);

%keyboard;

%unpack if it is a vector of size 1 of a vector
if max(V.size) == 1 && strcmp(class(V.elementAt(0)),'java.lang.Object[]') && V.elementAt(0).length > 1
    V = V.elementAt(0);
    L = V.length;
end

allScalar = 1;
for i=1:L
    if strfind(class(V),'java.lang.Object[]')
        curElement = V(i);
    else
        curElement = V.elementAt(i-1);
    end
    if isscalar(curElement) && isnumeric(curElement)
        resultVec(i) = curElement;
    else
        allScalar = 0;
    end
end

if ~allScalar
    resultVec = cell(1,L);
    for i=1:L
        if strfind(class(V),'java.lang.Object[]')
            curElement = V(i);
        else
            curElement = V.elementAt(i-1);
        end
        resultVec{i} = curElement;
    end
end

if iscell(resultVec) && length(resultVec) == 1 %unpack a cell array of size 1
    resultVec = resultVec{1};
end

%keyboard;
