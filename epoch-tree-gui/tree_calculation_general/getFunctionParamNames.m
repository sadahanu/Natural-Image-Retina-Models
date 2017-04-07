function params = getFunctionParamNames(func_name)

filePath = which(func_name);
fid = fopen(filePath,'r');
params = {};

p = 1; %param counter
while 1
    tline = fgetl(fid);
    if ~ischar(tline),   break,   end
    Ind = strfind(tline,'params.');
    if ~isempty(Ind)
        Ind = Ind(1);
        
        [null, paramName] = strtok(tline(Ind:end),'.');
        paramName = strtok(paramName); %remove trailing whitespace
        paramName = strtok(paramName,';-+)('); %remove trailing characters
        params{p} = paramName(2:end); %remove leading .
        p=p+1;
    end
end
fclose(fid);


