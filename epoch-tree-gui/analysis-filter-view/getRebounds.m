function r = getRebounds(peaks_ind,trace,searchInterval)
%get rebound as fraction of peak amplitude

%trace = abs(trace);
peaks = trace(peaks_ind);
r.left = zeros(size(peaks));
r.right = zeros(size(peaks));
for i=1:length(peaks)
   endPoint = min(peaks_ind(i)+searchInterval,length(trace));
   startPoint = max(peaks_ind(i)-searchInterval,1);
   nextMin = getPeaks(trace(peaks_ind(i):endPoint),-1);
  
   if isempty(nextMin), nextMin = peaks(i); 
   else nextMin = nextMin(1); end
   nextMax = getPeaks(trace(peaks_ind(i):endPoint),1);
   if isempty(nextMax), nextMax = 0; 
   else nextMax = nextMax(1); end
   
   if nextMin<peaks(i) %not the real spike min
       r.Right(i) = 0;
   else
       r.Right(i) = nextMax; 
   end
   
   preMin = getPeaks(trace(startPoint:peaks_ind(i)),-1);
  % for the left one
   if isempty(preMin), preMin = peaks(i); 
   else preMin = preMin(1); end
   preMax = getPeaks(trace(startPoint:peaks_ind(i)),1);
   if isempty(preMax), preMax = 0; 
   else preMax = preMax(1); end
   
   if preMin<peaks(i) %not the real spike min
       r.Left(i) = 0;
   else
       r.Left(i) = preMax; 
   end
end
