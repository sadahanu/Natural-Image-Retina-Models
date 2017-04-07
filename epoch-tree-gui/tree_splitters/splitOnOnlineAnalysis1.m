function V = splitOnOnlineAnalysis1( epoch )
%SPLITONONLINEANALYSIS1 Summary of this function goes here
%   online analysis none is exc
     V = epoch.protocolSettings.get('onlineAnalysis');
     if strcmp(V,'none')
         V = 'exc';
     end
   

end

