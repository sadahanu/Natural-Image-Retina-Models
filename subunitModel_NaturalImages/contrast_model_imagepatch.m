%%simulate the responses from LN model and subunit model using fitted
%%contrast response function
%load the image patches
load('~/Documents/MATLAB/subunitModel_NaturalImages/results/ImagePatchSet/01151.mat');
%load contrast function
load('~/Documents/MATLAB/subunitModel_NaturalImages/results/Contrast Function/C12_o2.mat');
% load measured responses
load('~/Documents/MATLAB/subunitModel_NaturalImages/results/Exc_01151_062116.mat');
% to generate contrast image sets
for i = 1:30
    imagePatches{i} = imagePatches{i} - ResStructArray{1}.equIntensity(i)+ResStructArray{1}.backgroundIntensity(i);
end
natImagesStimID.stimImages = imagePatches;
natImagesStimID.imageMean =0.1823;
contrastPolarity = 1;
CRF.contrast = ContraResp(:,1);
CRF.response= ContraResp(:,3);
cSize = 220;
cellNo = 4;

for i = 1:cellNo
%CRF.response= ContraResp(:,1+i);
ResStructArray{i}.model=getRFmodelPatchResponses(natImagesStimID,contrastPolarity,CRF,cSize);
end

%% examine fitted contrast function vs. emperical function
figure(3);clf;
for i = 1:cellNo
xContr1 = (ResStructArray{i}.equIntensity-ResStructArray{i}.backgroundIntensity(1))./ResStructArray{i}.backgroundIntensity(1);
xContr = -1:0.01:max(xContr1);
subplot(1,2,i);
h = ResStructArray{i}.model.paras;
yResp = CRFcumGauss(xContr,h.alphaScale,h.betaSens,h.gammaXoff,h.epsilonYoff);
plot(xContr1,ResStructArray{i}.RespOn(:,2),'o');
hold on;
plot(xContr,yResp,'-');
xlabel('Contrast');
ylabel('Response-Spot vs.Disc');
hold off
end

%% compare LN; subunit model fitting vs. measured  image responses
%normalize response to [0 1];
mfig = figure(4);set(mfig,'Position', [0, 0, 400, 800]);clf; 
clear h tempLNResp tempSubResp tempResp;
cellNo = 4;
for i = 1:cellNo
    h = ResStructArray{i}.model;
    tempLnResp = norm01(-h.patchResp_ln,80); %normalize to the 80% percentile max value
    tempSubResp = norm01(-h.patchResp_subunit,80);
    %ii = cellNo+1-i;
    tempResp = norm01(-ResStructArray{i}.RespOn(:,1),80);
    xmax = max([max(tempLnResp),max(tempSubResp),max(tempResp)]);
    subplot(cellNo,2,(i-1)*2+1);
    plot(tempResp,tempLnResp,'o');
    xlabel(strcat('measured-cell',num2str(i)));
    ylabel('LN');
    ylim([0 xmax]);
    xlim([0 xmax])
    subplot(cellNo,2,(i-1)*2+2);
    plot(tempResp,tempSubResp,'o');
    xlabel(strcat('measured-cell',num2str(i)));
    ylabel('Subunit');
    ylim([0 xmax]);
    xlim([0 xmax])
end
%% compare subunit model and LN model
figure(5);clf;
clear tempRes;
cellNo = 1;
for i = 1:cellNo
    subplot(1,cellNo,i);
    tempRes = ResStructArray{i}.model;
    plot(tempRes.patchResp_subunit,tempRes.patchResp_ln,'o');hold on;
    xmin = min(min(tempRes.patchResp_subunit),min(tempRes.patchResp_ln));
    xmax = max(max(tempRes.patchResp_subunit),max(tempRes.patchResp_ln));
    xlim([xmin xmax]);
    ylim([xmin xmax]);
    plot([xmin xmax],[xmin xmax]);
    xlabel(strcat('subunit-Cell',num2str(i)));
    ylabel('LN');
end

%% model grating responses
clc;
numNode = 2; % number of nodes in barStructArray
contrastPolarity = 1;
CRF.contrast = ContraResp(:,1);
cSize = 220;
% only 1 cell here
% combine two sets and generate stimlus
clear gratingset gratingwMeanset gratingMean barNo RespOn Resp_model tempgratings basrSizes;
for i = 1:numNode
    barNo(i) = length(barStructArray{i}.barWidth);
end
    totalBars = sum(barNo);
    gratingset = cell(1,totalBars);
    gratingwMeanset = cell(1,totalBars);
    gratingMean = cell(1,totalBars);
    RespOn = zeros(totalBars,3);
    barSizes = zeros(totalBars,1);

 for i = 1:2
    clear bars;
    bars = barStructArray{i};
    tempgratings = getMeanPlusGrating(bars.meanIntensity(1), bars.backgroundIntensity(1),bars.barWidth, round(bars.aperture/3.3));
    if i>1
      j = sum(barNo(1:(i-1)))+1;
    else j =1;
    end
    RespOn(j:j+barNo(i)-1,:)=bars.RespOn;
    barSizes(j:j+barNo(i)-1,:) = bars.barWidth;
    for k = j:j+barNo(i)-1 
     gratingset{k} = tempgratings{k-j+1}.grating;
     gratingwMeanset{k} = tempgratings{k-j+1}.gratingwithmean;
     gratingMean{k} = tempgratings{k-j+1}.meandisc;
    end
 end

 % plot comparison, col1: grating only; col2: grating with mean col3: mean;
 %row2:measure vs. subunit; row3: measrue vs. LN; row1: subunit vs.LN
 CRF.response= ContraResp(:,2);
 stimgratingset.stimImages = gratingset;
 stimgratingset.imageMean = 0.2;
 stimgratingMean.stimImages = gratingMean;
 stimgratingMean.imageMean = 0.2;
 stimgratingwMeanset.stimImages = gratingwMeanset;
 stimgratingwMeanset.imageMean = 0.2;
 RespModel{1} = getRFmodelPatchResponses(stimgratingset,contrastPolarity,CRF,cSize);
 RespModel{2} = getRFmodelPatchResponses(stimgratingwMeanset,contrastPolarity,CRF,cSize);
 RespModel{3} = getRFmodelPatchResponses(stimgratingMean,contrastPolarity,CRF,cSize);
 

 figure(6);clf;
 cond = {'Grating','wMean','Mean'};
 for k =1:3
     subplot(3,3,k)
      plot(RespModel{k}.patchResp_subunit,RespModel{k}.patchResp_ln,'o');
      xlabel('subunit');
      ylabel(strcat('LN',cond{k}));
     subplot(3,3,k+3)
      plot(norm01(-RespOn(:,k),100),norm01(-RespModel{k}.patchResp_subunit,100),'o');
      xlabel(strcat('meas ',cond{k}));
      ylabel('subunit');
     subplot(3,3,k+6)  
      plot(norm01(-RespOn(:,k),100),norm01(-RespModel{k}.patchResp_ln,100),'o');
      xlabel(strcat('meas ',cond{k}));
      ylabel('LN');
 end
 %% relation to bar width
 clear cond;
 cond = {'Grating','withMean'};
 subplot(1,3,1)
 figure(7);clf;
 for k =1:2
     subplot(2,3,(k-1)*3+1)
      plot(barSizes,RespModel{k}.patchResp_ln,'o');
      xlabel('bar size');
      ylabel(strcat('LN',cond{k}));
     subplot(2,3,(k-1)*3+2)
      plot(barSizes,RespModel{k}.patchResp_subunit,'o');
      xlabel('bar size');
      ylabel(strcat('Unit',cond{k}));
     subplot(2,3,(k-1)*3+3)  
      plot(barSizes,RespOn(:,k),'o');
       xlabel('bar size');
       ylabel(strcat('Meas',cond{k}));
 end
 %% compare image, mean and contrast
 figure(7)
 plot(RespModel{2}.patchResp_subunit,RespModel{1}.patchResp_subunit+RespModel{3}.patchResp_subunit,'o');hold on;
 cmin = min(min(xlim),min(ylim));
 cmax = max(max(xlim),max(ylim));
 xlim([cmin cmax]);
 ylim([cmin cmax]);
 plot([cmin cmax],[cmin cmax]);
 xlabel('Image');
 ylabel('Contrast+Mean');
 %% check the stimlus images
 figure(8);clf;
 for i = 1:length(gratingset)
      imshow(imresize(uint8(gratingset{i}.*255),4));
      pause(1);
 end
 