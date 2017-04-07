function res = getRFmodelPatchResponses(natImagesStimID,contrastPolarity,CRF,cSize)
if isstr(natImagesStimID)
    Stimdirectory = '~/Documents/MATLAB/Analysis_symphony/NatImages/NatImagesStimuli/';
    load([Stimdirectory, natImagesStimID,'.mat']);
else
    stimData = natImagesStimID;
end


try
stimImages = stimData.stimImages;
imageMean = stimData.imageMean;
catch

end

if (nargin > 2) && ~isempty(CRF)
%CRF is nlinearity to use as subunit output
params0 = [200,contrastPolarity.*3,0,-0.4];
fitResult = fitCRF_cumGauss(CRF.contrast,CRF.response,params0);
fitContrast = -1:0.01:1;
fitResponse = CRFcumGauss(fitContrast,fitResult.alphaScale,fitResult.betaSens,fitResult.gammaXoff,fitResult.epsilonYoff);
res.fitContrast = fitContrast;
res.fitResponse = fitResponse;
res.paras = fitResult;
else 
    %use rect linear subunit nlinearity
end

% RF properties
FilterSize = 50; %50 change to 51 for picking up the center
%stdevs... 
if nargin==4
    CenterRadius = cSize/(4*4.8);
    SubunitRadius = round(CenterRadius/6);
else
    SubunitRadius = 2; %3
    CenterRadius = 12;
end


                       
% subunit locations - square grid
TempFilter = zeros(FilterSize, FilterSize);
SubunitLocations = find(rem([1:FilterSize], 2*SubunitRadius) == 0);


for x = 1:length(SubunitLocations)
    TempFilter(SubunitLocations(x), SubunitLocations) = 1;
end
SubunitIndices = find(TempFilter > 0);
%display(SubunitIndices);

% center & subunit filters
for x = 1:FilterSize
    for y = 1:FilterSize
        SubunitFilter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (SubunitRadius^2)));
        RFCenter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (CenterRadius^2)));
    end
end

subunitWeightings = RFCenter(SubunitIndices);

% normalize each component
subunitWeightings = subunitWeightings / sum(subunitWeightings);
SubunitFilter = SubunitFilter / sum(SubunitFilter(:));


%get RF activation from each saved patch
RFoutput_ln = [];
RFoutput_subunit = [];
allSubunitInputs = zeros(length(stimImages),length(SubunitIndices));
allSubunitOutputs = zeros(length(stimImages),length(SubunitIndices));
HighContrastMarker = zeros(length(stimImages),1);
cuSize = FilterSize; % image patch size
for patch = 1:length(stimImages)
    %contrast flip so OFF channels can get treated as ON
    CurrentPatch = contrastPolarity.*(stimImages{patch} - imageMean)./imageMean;
    
    % convolve patch with subunit filter
    ImagePatch = conv2(CurrentPatch, SubunitFilter, 'same');
    % activation of each subunit
    % align the center 
    tempSize = size(CurrentPatch,1);
    if (cuSize~= tempSize)
       indexoff = round((tempSize-cuSize)/2); 
       %display(indexoff);
       SubunitIndices = (floor(SubunitIndices./cuSize)+indexoff).*tempSize+mod(SubunitIndices,cuSize)+indexoff;
       cuSize = tempSize;
    end
    
    subunitActivations = ImagePatch(SubunitIndices);
    %display(mean(subunitActivations(:)));

    if (nargin > 2) && ~isempty(CRF) %nonlinear subunits - CRF as subunit nlinearity
        if any(subunitActivations>1) %not sampled CRF for these high contrasts
           HighContrastMarker(patch) = 1; 
        end
        
        subunitOutputs = CRFcumGauss(contrastPolarity.*subunitActivations,fitResult.alphaScale,fitResult.betaSens,fitResult.gammaXoff,fitResult.epsilonYoff);
        allSubunitInputs(patch,:) = contrastPolarity.*subunitActivations;
        allSubunitOutputs(patch,:) = subunitOutputs;
        
    else %nonlinear subunits - rect linear as subunit nlinearity
        subunitOutputs = subunitActivations;
        subunitOutputs(subunitOutputs<0) = 0;
        allSubunitInputs(patch,:) = subunitActivations;
        allSubunitOutputs(patch,:) = subunitOutputs;
    end
    % Linear center
    RFoutput_ln(patch) = sum(subunitActivations .* subunitWeightings);
    %subunit...
    RFoutput_subunit(patch) = sum(subunitOutputs.* subunitWeightings);
    
    

end

res.RFoutput_ln = RFoutput_ln; %pre-output nonlinearity, sort of linear RF activation of each patch
res.allSubunitInputs = allSubunitInputs;
res.allSubunitOutputs = allSubunitOutputs;


if (nargin > 2) && ~isempty(CRF)
    %CRF for LN output......
    res.patchResp_ln = CRFcumGauss(contrastPolarity.*RFoutput_ln,fitResult.alphaScale,fitResult.betaSens,fitResult.gammaXoff,fitResult.epsilonYoff);
else %no CRF given, just use threshold linear
    %rectify LN output...
    res.patchResp_ln = RFoutput_ln;
    res.patchResp_ln(res.patchResp_ln < 0) = 0;
end

res.patchResp_subunit = RFoutput_subunit;

res.HighContrastMarker = HighContrastMarker;

end