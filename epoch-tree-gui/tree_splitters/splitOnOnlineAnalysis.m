function V = splitOnOnlineAnalysis( epoch )
% online analysis extracellular and none will be set as cell attach
%   Detailed explanation goes here
     V = epoch.protocolSettings.get('onlineAnalysis');
     if strcmp(V,'none')||strcmp(V,'extracellular')
         V = 'cell-attach';
     end

end

