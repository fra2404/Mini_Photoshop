% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 16/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Provides static methods for adjusting image brightness, contrast, saturation, and applying custom tone curves.

classdef ImageAdjuster < handle
    
    methods (Static)
        
        function adjusted = adjustBrightness(img, value, useGPU)
            if nargin < 3
                useGPU = false;
            end
            if useGPU && canUseGPU()
                gpuImg = gpuArray(double(img));
                gpuAdjusted = gpuImg + value * 0.5;
                gpuAdjusted = max(0, min(255, gpuAdjusted));
                adjusted = uint8(gather(gpuAdjusted));
            else
                adjusted = double(img) + value * 0.5;
                adjusted = uint8(max(0, min(255, adjusted)));
            end
        end
        
        function adjusted = adjustContrast(img, value, useGPU)
            if nargin < 3
                useGPU = false;
            end
            factor = 1 + value / 200;
            if useGPU && canUseGPU()
                gpuImg = gpuArray(double(img));
                gpuAdjusted = (gpuImg - 128) * factor + 128;
                gpuAdjusted = max(0, min(255, gpuAdjusted));
                adjusted = uint8(gather(gpuAdjusted));
            else
                adjusted = (double(img) - 128) * factor + 128;
                adjusted = uint8(max(0, min(255, adjusted)));
            end
        end
        
        function adjusted = adjustSaturation(img, value, useGPU)
            if nargin < 3
                useGPU = false;
            end
            if size(img, 3) == 3
                if useGPU && canUseGPU()
                    gpuImg = gpuArray(img);
                    hsv = rgb2hsv(gpuImg);
                    hsv(:,:,2) = max(0, min(1, hsv(:,:,2) + value / 100));
                    adjusted = im2uint8(gather(hsv2rgb(hsv)));
                else
                    hsv = rgb2hsv(img);
                    hsv(:,:,2) = max(0, min(1, hsv(:,:,2) + value / 100));
                    adjusted = im2uint8(hsv2rgb(hsv));
                end
            else
                adjusted = img; % No saturation adjustment for grayscale
            end
        end
        
        function adjusted = applyCurves(img, pointsR, pointsG, pointsB, useGPU)
            if nargin < 5
                useGPU = false;
            end
            if size(img, 3) == 3
                adjusted = img;
                % Create LUT for R channel
                if size(pointsR, 2) >= 2
                    lutR = interp1(pointsR(1,:), pointsR(2,:), 0:255, 'pchip', 'extrap');
                    lutR = uint8(max(0, min(255, lutR)));
                else
                    lutR = uint8(0:255);  % Identity
                end
                
                % Create LUT for G channel
                if size(pointsG, 2) >= 2
                    lutG = interp1(pointsG(1,:), pointsG(2,:), 0:255, 'pchip', 'extrap');
                    lutG = uint8(max(0, min(255, lutG)));
                else
                    lutG = uint8(0:255);  % Identity
                end
                
                % Create LUT for B channel
                if size(pointsB, 2) >= 2
                    lutB = interp1(pointsB(1,:), pointsB(2,:), 0:255, 'pchip', 'extrap');
                    lutB = uint8(max(0, min(255, lutB)));
                else
                    lutB = uint8(0:255);  % Identity
                end
                
                if useGPU && canUseGPU()
                    gpuImg = gpuArray(img);
                    gpuLutR = gpuArray(lutR);
                    gpuLutG = gpuArray(lutG);
                    gpuLutB = gpuArray(lutB);
                    adjusted(:,:,1) = gather(gpuLutR(uint16(double(gpuImg(:,:,1)) + 1)));
                    adjusted(:,:,2) = gather(gpuLutG(uint16(double(gpuImg(:,:,2)) + 1)));
                    adjusted(:,:,3) = gather(gpuLutB(uint16(double(gpuImg(:,:,3)) + 1)));
                else
                    adjusted(:,:,1) = lutR(uint16(double(img(:,:,1)) + 1));
                    adjusted(:,:,2) = lutG(uint16(double(img(:,:,2)) + 1));
                    adjusted(:,:,3) = lutB(uint16(double(img(:,:,3)) + 1));
                end
            else
                % For grayscale, apply average curve
                avgPoints = (pointsR + pointsG + pointsB) / 3;
                if size(avgPoints, 2) >= 2
                    lutGray = interp1(avgPoints(1,:), avgPoints(2,:), 0:255, 'pchip', 'extrap');
                    lutGray = uint8(max(0, min(255, lutGray)));
                else
                    lutGray = uint8(0:255);  % Identity
                end
                
                if useGPU && canUseGPU()
                    gpuImg = gpuArray(img);
                    gpuLut = gpuArray(lutGray);
                    adjusted = gather(gpuLut(uint16(double(gpuImg) + 1)));
                else
                    adjusted = lutGray(uint16(double(img) + 1));
                end
            end
        end
        
        function adjusted = applyAllAdjustments(img, brightness, contrast, saturation, pointsR, pointsG, pointsB, useGPU)
            % Always start from original image
            % Apply in correct order: Brightness -> Contrast -> Curves -> Saturation
            if nargin < 8
                useGPU = false;
            end
            adjusted = ImageAdjuster.adjustBrightness(img, brightness, useGPU);
            adjusted = ImageAdjuster.adjustContrast(adjusted, contrast, useGPU);
            adjusted = ImageAdjuster.applyCurves(adjusted, pointsR, pointsG, pointsB, useGPU);
            adjusted = ImageAdjuster.adjustSaturation(adjusted, saturation, useGPU);
        end
        
    end
    
end