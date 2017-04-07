function minPixel = minImagePatchPixel(patchLocations,imageName,varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    ip = inputParser;
    ip.addRequired('patchLocations',@ismatrix);
    ip.addRequired('imageName',@ismatrix);
    addParameter(ip,'imageSize',[200, 200],@ismatrix); %microns
    addParameter(ip,'stimSet','/VHsubsample_20160105',@ischar);

    ip.parse(patchLocations,imageName,varargin{:});
    
    patchLocations = ip.Results.patchLocations;
    imageName = ip.Results.imageName;
    imageSize = ip.Results.imageSize;
    stimSet = ip.Results.stimSet;    
    %load appropriate image...
    resourcesDir = '~/Documents/MATLAB/subunitModel_NaturalImages';
    fileId=fopen([resourcesDir, stimSet, '/imk', imageName,'.iml'],'rb','ieee-be');
    img = fread(fileId, [1536,1024], 'uint16');
    %rescale image
    img = double(img);
    img = (img./max(img(:))).*255;
    img = uint8(img);
    imageSize_VHpix = imageSize ./ (3.3); %um / (um/pixel) -> pixel
    radX = round(imageSize_VHpix(1) / 2); %boundaries for fixation draws depend on stimulus size
    radY = round(imageSize_VHpix(2) / 2);
    images = zeros(radX*2+1,radY*2+1);
    minPixel=zeros(size(patchLocations,1),1);
    % for a circular aperture
    mask = uint8(maskCreate(radX,radY));
    for ff = 1:size(patchLocations,1);
        images = img(round(patchLocations(ff,1)-radX):round(patchLocations(ff,1)+radX),...
        round(patchLocations(ff,2)-radY):round(patchLocations(ff,2)+radY)).*mask;
        minPixel(ff)=min(images(images>0));
    end
end

