function portSavedParams()

global ANALYSIS_FILTER_VIEW_FOLDER;

curDir = pwd;

cd([ANALYSIS_FILTER_VIEW_FOLDER '/analysis/saved_params/']);
D = dir(pwd);
portCurrentFolder(D);

cd([ANALYSIS_FILTER_VIEW_FOLDER '/view/saved_params/']);
D = dir(pwd);
portCurrentFolder(D);

cd(curDir);
end

function [] = portCurrentFolder(D)

for i=1:length(D)
    if ~strcmp(D(i).name(1),'.') && strcmp(D(i).name(end-3:end),'.mat')
        V = whos('-file', D(i).name);
        for v = 1:length(V)
            if strcmp(V(v).name,'calc')
                curName = D(i).name;
                disp(['porting ' curName]);
                load(D(i).name, 'calc');
                oldCalc = calc;
                calc = struct;
                calc.func = oldCalc.func;
                calc.params = struct;
                params = getFunctionParamNames(func2str(calc.func));
                
                for p=1:length(params)
                    if isfield(oldCalc.params,params{p})
                        calc.params.(params{p}) = oldCalc.params.(params{p});
                    else
                        calc.params.(params{p}) = [];
                    end
                end
                save(D(i).name, 'calc');
            end
        end
    end
end
end
