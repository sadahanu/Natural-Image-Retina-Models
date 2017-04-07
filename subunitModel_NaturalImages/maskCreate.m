function mask = maskCreate( x,y )
% create a mask matrix to mimic mask function in protocols
%   Detailed explanation goes here
 mask = zeros(2*x+1,2*y+1);
 rad = min(x,y);
 for i = -x:x
     for j = -y:y
        if (i^2+j^2<=rad^2)
            mask(i+x+1,j+y+1)=1;
        end
     end
 end
end

