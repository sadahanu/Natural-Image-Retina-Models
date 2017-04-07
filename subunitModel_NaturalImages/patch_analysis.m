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
run_num = 10; % run 100 times
p_negative = zeros(file_num, run_num); %percentage of negative pixels in contrast images
%for ImageIndex = 1:file_num % 20 total in this folder
% Load  and plot the image to analyze
for ImageIndex = 1:file_num % for testing only
f1=fopen([IMAGES_DIR, img_filenames_list{ImageIndex}],'rb','ieee-be');
w=1536;h=1024;
my_image=fread(f1,[w,h],'uint16');axis image; axis off; hold on;
Stim_sz= [500 500];
Obj_sigmaC = 50;
Obj_aperture = 200;
Obj_noPatches = 30;
Obj_linearIntegrationFunction = 'gaussian';
for i = 1:run_num 
p_negative(ImageIndex,i) = simulated_MeanPContrast(my_image, Stim_sz, Obj_sigmaC, Obj_aperture, Obj_noPatches, Obj_linearIntegrationFunction);
end
end


