function  p = simulated_MeanPContrast(img, stim_sz, obj_sigmaC, obj_aperture, obj_noPatches, obj_linearIntegrationFunction)
         % stim_sz([x y]),sigmaC, aperture: um    
            img = double(img);
            img = (img./max(img(:))); %rescale s.t. brightest point is maximum monitor level
            obj_backgroundIntensity = mean(img(:));%set the mean to the mean over the image
            %display(obj_backgroundIntensity);
            contrastImage = (img - obj_backgroundIntensity) ./ obj_backgroundIntensity;% weber contrast
            img = img.*255; %rescale s.t. brightest point is maximum monitor level
            obj_wholeImageMatrix = uint8(img);
            stimSize_VHpix = stim_sz ./ (3.3); %um / (um/pixel) -> pixel
            radX = round(stimSize_VHpix(1) / 2); %boundaries for fixation draws depend on stimulus size
            radY = round(stimSize_VHpix(2) / 2);
            
            %get patch locations:
            obj_patchLocations(1,1:obj_noPatches) = randsample((radX + 1):(1536 - radX),obj_noPatches); %in VH pixels
            obj_patchLocations(2,1:obj_noPatches) = randsample((radY + 1):(1024 - radY),obj_noPatches);
            sigmaC = obj_sigmaC ./ 3.3; %microns -> VH pixels
            RF = fspecial('gaussian',2.*[radX radY] + 1,sigmaC);

            %   get the aperture to apply to the image...
            %   set to 1 = values to be included (i.e. image is shown there)
            [rr, cc] = meshgrid(1:(2*radX+1),1:(2*radY+1));
            if obj_aperture > 0
                apertureMatrix = sqrt((rr-radX).^2 + ...
                    (cc-radY).^2) < (obj_aperture/2) ./ 3.3;
                apertureMatrix = apertureMatrix';
            else
                apertureMatrix = ones(2.*[radX radY] + 1);
            end
            weightingFxn = ones(2.*[radX radY] + 1);
            if strcmp(obj_linearIntegrationFunction,'gaussian center')
                weightingFxn = apertureMatrix .* RF; %set to zero mean gray pixels
            elseif strcmp(obj_linearIntegrationFunction,'uniform')
                weightingFxn = apertureMatrix;
            end
            weightingFxn = weightingFxn ./ sum(weightingFxn(:)); %sum to one
            obj_allEquivalentIntensityValues = zeros(obj_noPatches,1);
            obj_imagePatchMatrix = zeros(obj_noPatches,2*radX+1, 2* radY+1);
            obj_contrastPatch = zeros(obj_noPatches, 2*radX+1, 2*radY+1);
            for ff = 1:obj_noPatches
                tempPatch = contrastImage(round(obj_patchLocations(1,ff)-radX):round(obj_patchLocations(1,ff)+radX),...
                    round(obj_patchLocations(2,ff)-radY):round(obj_patchLocations(2,ff)+radY));
                equivalentContrast = sum(sum(weightingFxn .* tempPatch));
                obj_allEquivalentIntensityValues(ff) = obj_backgroundIntensity + ...
                    equivalentContrast * obj_backgroundIntensity;
                
                obj_imagePatchMatrix(ff,:,:) = obj_wholeImageMatrix(round(obj_patchLocations(1, ff)-radX):round(obj_patchLocations(1,ff)+radX),...
                round(obj_patchLocations(2,ff)-radY):round(obj_patchLocations(2,ff)+radY));
                %imshow (obj_imagePatchMatrix(ff,:,:));
                obj_equivalentIntensity = obj_allEquivalentIntensityValues(ff);
                equ_rectangle = ones(radX*2+1, radY*2+1).*obj_equivalentIntensity;
                %imshow (equ_rectangle);
                tempDiff = (obj_equivalentIntensity*255 - ...
                    obj_backgroundIntensity*255);
                %obj_contrastPatch (ff,:,:) = uint8(double(obj_imagePatchMatrix(ff,:,:)) - tempDiff);
                obj_contrastPatch (ff,:,:) = double(obj_imagePatchMatrix(ff,:,:)) - tempDiff;
                %imshow (contrastPatch);
            end
            %percentage of negative pixels in contrast patch
            p = size(find(obj_contrastPatch<0),1)/(obj_noPatches*(2*radX+1)*(2*radY+1));
end