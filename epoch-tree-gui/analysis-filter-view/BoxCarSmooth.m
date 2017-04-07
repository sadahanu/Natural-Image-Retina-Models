function SmoothedVector = BoxCarSmooth(OrigVector, SmoothPts)

pts = length(OrigVector);

for pt = 1:pts
    Start = max([1 pt-round(SmoothPts/2)]);
    End = min([pts pt+round(SmoothPts/2)]);
    SmoothedVector(pt) = mean(OrigVector(Start:End));
end