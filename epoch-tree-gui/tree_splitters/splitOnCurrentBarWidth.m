function V = splitOnCurrentBarWidth( epoch )
%SPLITONCURRENTBARWIDTH return current barwidth used in grating stimulus
%   Detailed explanation goes here
     V=abs(epoch.protocolSettings.get('currentBarWidth'));
end

