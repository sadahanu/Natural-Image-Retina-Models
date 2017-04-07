%% Pull van Hateren natural images...
clear all; close all; clc;
IMAGES_DIR            = '/Users/zhouyu/Documents/MATLAB/subunitModel_NaturalImages/VHsubsample_20160105/';
temp_names                  = GetFilenames(IMAGES_DIR,'.iml');
saveloc=strcat(IMAGES_DIR,'ranked_patches','.mat');% to store the list of patches associated with each.iml file
for file_num = 1:size(temp_names,1)
    temp                    = temp_names(file_num,:);
    temp                    = deblank(temp);
    img_filenames_list{file_num}  = temp;
end

img_filenames_list = sort(img_filenames_list);
% % look at images...
% figure(1); clf;
% for ii = 1:length(img_filenames_list)
%     f1=fopen([IMAGES_DIR, img_filenames_list{ii}],'rb','ieee-be');
%     w=1536;h=1024;
%     buf=fread(f1,[w,h],'uint16');
%     colormap(gray);
%     imagesc(buf'); axis image; axis off;
%     title(img_filenames_list{imInd})
%     pause;
%     clf;
% end


%% step 1: make RF components
imageScalingFactor = 6.6; %microns on retina per image pixel (3.3 um/arcmin visual angle)
%NumFixations = 10000;           % how many patches to sample
NumFixations = 10;   % test
% RF properties:
FilterSize_microns = 500;                % size of patch (um). Code run-time is very sensitive to this
SubunitRadius_microns = 12;              % radius of subunit (12 um -> 48 um subunit diameter)
CenterRadius_microns = 50;              % center radius (50 um -> 200 um RF center size)

%convert to pixels:
FilterSize = round(FilterSize_microns / imageScalingFactor);
SubunitRadius = round(SubunitRadius_microns / imageScalingFactor);
CenterRadius = round(CenterRadius_microns / imageScalingFactor);

disp(FilterSize)

% create RF component filters
% subunit locations - square grid
TempFilter = zeros(FilterSize, FilterSize);
SubunitLocations = find(rem([1:FilterSize], 2*SubunitRadius) == 0);
for x = 1:length(SubunitLocations)
    TempFilter(SubunitLocations(x), SubunitLocations) = 1;
end
SubunitIndices = find(TempFilter > 0);

% center, surround and subunit filters
for x = 1:FilterSize
    for y = 1:FilterSize
        SubunitFilter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (SubunitRadius^2)));
        RFCenter(x,y) = exp(-((x - FilterSize/2).^2 + (y - FilterSize/2).^2) / (2 * (CenterRadius^2)));
    end
end

% normalize each component
RFCenter = RFCenter / mean(RFCenter(:));
SubunitFilter = SubunitFilter / sum(SubunitFilter(:));
%get weighting of each subunit output
subunitWeightings = RFCenter(SubunitIndices);

% plot RF components
figure(1); clf;
subplot(1, 2, 1);
imagesc(RFCenter);colormap gray;axis image;  hold on
subplot(1, 2, 2);
imagesc(SubunitFilter);colormap gray;axis image; hold on

%% step 2: apply to random image patches to each image
%for ImageIndex = 1:file_num % 20 total in this folder
% Load  and plot the image to analyze
for ImageIndex = 1:1 % for testing only
f1=fopen([IMAGES_DIR, img_filenames_list{ImageIndex}],'rb','ieee-be');
w=1536;h=1024;
my_image=fread(f1,[w,h],'uint16');
figure(2); 
clf;  
imagesc(my_image.^0.3);colormap gray;axis image; axis off; hold on;
pause(1); % puase 1 s to view the image
[ImageX, ImageY] = size(my_image);

% scale image to [0 1] -- contrast, relative to mean over entire image...
%my_image_nomean = (my_image - mean(my_image(:))) ./ mean(my_image(:));

%new scale method
my_image_nomean = (my_image - min(my_image(:)))./(max(my_image(:))-min(my_image(:)));
clear RFCenterProj RFSubCenterProj StoredImagePatch

%set random seed
randSeed = 1;
%rng(randSeed);

% choose set of random patches and measure RF components and patch
patch_sta = zeros(NumFixations,5); % col1, col2, location x,y; col3,subunit model prediction;
%col4, LN model prediction; col5 difference between col3 and 4
for patch = 1:NumFixations
    
    % choose location
    x = round(FilterSize/2 + (ImageX - FilterSize)*rand);
    y = round(FilterSize/2 + (ImageY - FilterSize)*rand);
    % Location{patch} = [x y]; %using matrix instead of struct
    patch_sta(patch,1)=x;
    patch_sta(patch,2)=y;
    % store patch
    ImagePatch = my_image_nomean(x-FilterSize/2+1:x+FilterSize/2,y-FilterSize/2+1:y+FilterSize/2);
    %PixelDistribution(patch,:) = ImagePatch(:);
    StoredImagePatch(patch, :, :) = ImagePatch;

    % convolve patch with subunit filter
    ImagePatch = conv2(ImagePatch, SubunitFilter, 'same');  
    
    % activation of each subunit
    subunitActivations = ImagePatch(SubunitIndices);
    
    % Linear center:
    LinearResponse = sum(subunitActivations .* subunitWeightings);
    RFCenterProj(patch) = max(LinearResponse,0); %threshold summed input

    % Subunit center:
    subunitOutputs = subunitActivations;
    subunitOutputs(subunitOutputs<0) = 0; %threshold each subunit
    RFSubCenterProj(patch) = sum(subunitOutputs.* subunitWeightings);
    
    if (rem(patch, 500) == 0)
        fprintf(1, '%d ', patch);
    end
end
    patch_sta(:,3)=RFSubCenterProj';
    patch_sta(:,4)=RFCenterProj';
    patch_sta(:,5)=abs(RFSubCenterProj'-RFCenterProj');% absolute differences between the two model prediction
    patch_sta=sortrows(patch_sta,-5); % patch_sta was arranged in descending order of the differences
    image_name=strrep(img_filenames_list{ImageIndex},'.','_');
    eval(strcat(image_name,'=patch_sta;'));
    %save(saveloc,image_name,'-append');
    figure(3); clf
% subunit vs linear-nonlinear
plot(RFSubCenterProj, RFCenterProj, '.'); hold on; 
plot([min(RFCenterProj) max(RFCenterProj)], [min(RFCenterProj) max(RFCenterProj)], 'r');
ylabel('linear-nonlinear center');
xlabel('nonlinear subunit center');
pause(2); % pause 10s before loading next image
end

