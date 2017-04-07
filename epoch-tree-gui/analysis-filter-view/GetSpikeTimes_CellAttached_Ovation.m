function [SpikeTimeIndex]=GetSpikeTimes_CellAttached_Ovation(node,leaf, amp, threshold, Polarity,Normalize)
%
% Obtain time for all events with an ampltidue >= a set threshold,
% excluding those that occur before and after stimulus; when events
% occur within 1000/samplinginterval points(e.g., 10 points, or 1ms,
% if sampling interval=100 us), only the first point above threshold 
% is retained. * this last point is changed in revision (see below) *
%
% GJM 11/04
%    refined with help of GF and FR 12/04
%       
% GJM 1/05
%   * added second criteria for spike determination - there must be a positive deflection >threshold 1-3 points
%   after negative deflection (that is itself more negative than negative threshold) 
%
%   * made into function that can be called form command line
%
%   * corrected two major errors:
%               1) routine throwing out spikes in which more than one point in the spike waveform was above threshold
%               2) routine not throwing out putative spikes that were separated by < refractory period    
%       *as a result, all spike distance measures computed before 1/25/05 must be calculated again*
%
% GJM 12/05
%   * spikes now timed at their peak, rather than at the first point they cross the negative threshold 
%           (should help avoid differences in timing due to differences in spike height)
%                   all data prior to 120105 needs to be reanalyzed
%
% FMR 12/06
%   * generalized to deal with both on cell and cc data
% FMR 4/10 
%   * Ovation

clear TempData TempSpikeTime SpikeTimeIndex  pre firststimpt post laststimpt tempnumberspikes f samplinginterval epochs totalepochpoints

if (leaf > 0)
    elist = node.leafNodes.elements(leaf).epochList;
else
    elist = node.epochList;
end
SampleEpoch = elist.elements(1);
StimulusString = strcat('stimuli:', char(elist.stimuliStreamNames));
if (isfield(SampleEpoch.protocolSettings, (strcat(StimulusString,':prepts')))) 
    PrePts = SampleEpoch.protocolSettings.get(strcat(StimulusString,':prepts'));
else
    PrePts = SampleEpoch.protocolSettings.get('acquirino:dataPoints');
end
PrePts = SampleEpoch.protocolSettings.get('preTime') * SampleEpoch.protocolSettings.get('sampleRate') / 1e3;
%PrePts = 10; % deactivate by zy

GoodEpochData = getSelectedData(elist, amp);
GoodEpochData = BaselineCorrectOvation(GoodEpochData, 1, PrePts);

[epochs,totalepochpoints]=size(GoodEpochData);
    

% now identify negative deflections < -threshold that are followed by quickly by a
% positive deflection > threshold/2
                                                                 
for o = 1:epochs                                                     % for # of identical stimulus repeats....
    if (Normalize)
        TempData(o, :) = Polarity * GoodEpochData(o,:)/max(abs(GoodEpochData(o, :)));          % move only those points collected during stimulus into new matrix
    else
        TempData(o, :) = Polarity * GoodEpochData(o,:)/max(abs(GoodEpochData(:)));          % move only those points collected during stimulus into new matrix
    end
    TempSpikeTime = find(TempData(o,:)<-1*threshold)';                          % find points collected during stimulus (in a single epoch) where value is < -1*threshold
    [tempnumberspikes,f]=size(TempSpikeTime);                                   % find number of suprathreshold points during this epoch (ie, i=1, i=2, etc.)
    count=1;  
    TempSpikeTimeIndex1{o} = [];
    for t=1:tempnumberspikes                                          % for each point (except the last) that passes threshold in this epoch ....
        if (TempSpikeTime(t) > 2 & TempData(o, TempSpikeTime(t)-1) > -1*threshold)
            if (TempSpikeTime(t)<totalepochpoints-5) & (TempData(o,1+TempSpikeTime(t))>threshold/2) ;                    % ...if the next point is above the positive threshold....
               TempSpikeTimeIndex1{o}(count)=TempSpikeTime(t);        % ...keep the point - index it according to how many points have already been retained
               count=count+1;                                               % update counter 
            elseif (TempSpikeTime(t)<totalepochpoints-5) & (TempData(o,2+TempSpikeTime(t))>threshold/2) ;                     %...if the point after the next point is above the positive threshold....
               TempSpikeTimeIndex1{o}(count)=TempSpikeTime(t);        % ...keep the point - index it according to how many points have already been retained
               count=count+1; 
            elseif (TempSpikeTime(t)<totalepochpoints-5) & (TempData(o,3+TempSpikeTime(t))>threshold/2) ; 
               TempSpikeTimeIndex1{o}(count)=TempSpikeTime(t);        
               count=count+1; 
            elseif (TempSpikeTime(t)<totalepochpoints-5) & (TempData(o,4+TempSpikeTime(t))>threshold/2) ; 
               TempSpikeTimeIndex1{o}(count)=TempSpikeTime(t);        
               count=count+1;    
            elseif (TempSpikeTime(t)<totalepochpoints-5) & (TempData(o,5+TempSpikeTime(t))>threshold/2) ; 
               TempSpikeTimeIndex1{o}(count)=TempSpikeTime(t);        
               count=count+1;    
            elseif (TempSpikeTime(t)<totalepochpoints-6) & (TempData(o,6+TempSpikeTime(t))>threshold/2) ; 
               TempSpikeTimeIndex1{o}(count)=TempSpikeTime(t);        
               count=count+1;    
            elseif (TempSpikeTime(t)<totalepochpoints-7) & (TempData(o,7+TempSpikeTime(t))>threshold/2) ; 
               TempSpikeTimeIndex1{o}(count)=TempSpikeTime(t);        
               count=count+1;    
            end
        end
    end
    clear TempSpikeTime
end
  

%
% now save only a single spike timer per spike event; don't want to save two
% time points that simply represent the same spike (at two points which are
% both below threshold).
% 

% for b=1:length(TempSpikeTimeIndex1)                      % for each epoch 
%     count=1;
%     Diff_Times=diff(TempSpikeTimeIndex1{b});            % calculate the difference in time between points below the negative threshold
%     for stepper=1:length(Diff_Times);                    % for each of those points
%          if Diff_Times(stepper)>1.5;                      % if the difference between one point and the next is more than .15ms
%              transition(count)=stepper;                     % consider it the last negative point of a putative - make a list of these transition times
%              count=count+1;
%          end
%     end
%     if (exist('transition'))
%         for spike=1                                                                                         % for the first putative spike
%             [temp1(spike),temp2(spike)]=min(TempData(b,TempSpikeTimeIndex1{b}(1:transition(spike))));     % determine the time at which the spike reaches its negative peak
%             TempSpikeTimeIndex2{b}(spike)=TempSpikeTimeIndex1{b}(temp2(spike))/10;                               % put the time, converted back to ms, in the index  
%         end
%         for spike=2:length(transition)                                                                       % for each putative spike except the last
%             [temp1(spike),temp2(spike)]=min(TempData(b,TempSpikeTimeIndex1{b}(transition(spike-1)+1:transition(spike))));
%             TempSpikeTimeIndex2{b}(spike)=TempSpikeTimeIndex1{b}(transition(spike-1)+temp2(spike))/10;
%         end
%         for spike=length(transition)+1
%             [temp1(spike),temp2(spike)]=min(TempData(b,TempSpikeTimeIndex1{b}(transition(spike-1)+1:end)));
%             TempSpikeTimeIndex2{b}(spike)=TempSpikeTimeIndex1{b}(transition(spike-1)+temp2(spike))/10;
%         end
%     end
%     clear transition stepper Diff_Times
% end

TempSpikeTimeIndex2 = TempSpikeTimeIndex1;

% now check that spikes are seperated by more than 10 bins

[f,g]=size(TempSpikeTimeIndex2);
for y=1:g;
    SpikeTimeIndex{y} = [];
    [h]=length(TempSpikeTimeIndex2{y});
    count=1;
    for z=count:h
        if z==1; 
            SpikeTimeIndex{y}(count)=TempSpikeTimeIndex2{y}(z);
            count=count+1;
        else z~=1 & z<=h;
            if TempSpikeTimeIndex2{y}(z)-TempSpikeTimeIndex2{y}(z-1)>=10;
                SpikeTimeIndex{y}(count)=TempSpikeTimeIndex2{y}(z);
                count=count+1;
            end
        end
    end
end

clear params;
%params(1) = SpikeTimeIndex;
%node.custom.results.params = params;
    















