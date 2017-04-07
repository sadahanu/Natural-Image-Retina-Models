function gratings = getMeanPlusGrating(offset,background, barwidth,sz)
%GETMEANPLUSGRATING Summary of this function goes here
%   Detailed explanation goes here
   numBars = size(barwidth, 2);
   gratings = cell(1,numBars);
   center = floor(sz/2)+1; % center of grating is 
   barwidth = barwidth/3.3;
   if (offset < background)
            height = min(offset, (1-background));
    else height = min (background, (1-offset));
   end
  for i = 1:numBars
      width = barwidth (i);
      wave = sin((linspace(1,sz,sz)-center)*pi/(width));
      wave(wave>=0)=1;
      wave(wave<0)=-1;
      gratings{i}.grating = ones(sz,1)*wave.*height+background;
      gratings{i}.gratingwithmean = ones(sz,1)*wave.*height+offset;
      gratings{i}.meandisc = ones(sz,sz).*offset;
  end      

end

