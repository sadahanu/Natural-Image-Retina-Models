function [] = displayNodeSearchMap(M)

allKeys = M.keys;
for i=1:length(allKeys);
    disp(allKeys{i});
end
