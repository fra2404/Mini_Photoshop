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
        
        function adjusted = adjustBrightness(img, value)
            adjusted = double(img) + value * 0.5;
            adjusted = uint8(max(0, min(255, adjusted)));
        end
        
        function adjusted = adjustContrast(img, value)
            factor = 1 + value / 200;
            adjusted = (double(img) - 128) * factor + 128;
            adjusted = uint8(max(0, min(255, adjusted)));
        end
        
        function adjusted = adjustSaturation(img, value)
            if size(img, 3) == 3
                hsv = rgb2hsv(img);
                hsv(:,:,2) = max(0, min(1, hsv(:,:,2) + value / 100));
                adjusted = im2uint8(hsv2rgb(hsv));
            else
                adjusted = img; % No saturation adjustment for grayscale
            end
        end
        
        function adjusted = applyCurves(img, pointsR, pointsG, pointsB)
            if size(img, 3) == 3
                adjusted = img;
                % Create LUT for R channel
                if size(pointsR, 2) >= 2
                    lutR = interp1(pointsR(1,:), pointsR(2,:), 0:255, 'pchip', 'extrap');
                    lutR = uint8(max(0, min(255, lutR)));
                else
                    lutR = uint8(0:255);  % Identity
                end
                adjusted(:,:,1) = lutR(uint16(double(img(:,:,1)) + 1));
                
                % Create LUT for G channel
                if size(pointsG, 2) >= 2
                    lutG = interp1(pointsG(1,:), pointsG(2,:), 0:255, 'pchip', 'extrap');
                    lutG = uint8(max(0, min(255, lutG)));
                else
                    lutG = uint8(0:255);  % Identity
                end
                adjusted(:,:,2) = lutG(uint16(double(img(:,:,2)) + 1));
                
                % Create LUT for B channel
                if size(pointsB, 2) >= 2
                    lutB = interp1(pointsB(1,:), pointsB(2,:), 0:255, 'pchip', 'extrap');
                    lutB = uint8(max(0, min(255, lutB)));
                else
                    lutB = uint8(0:255);  % Identity
                end
                adjusted(:,:,3) = lutB(uint16(double(img(:,:,3)) + 1));
            else
                % For grayscale, apply average curve
                avgPoints = (pointsR + pointsG + pointsB) / 3;
                if size(avgPoints, 2) >= 2
                    lutGray = interp1(avgPoints(1,:), avgPoints(2,:), 0:255, 'pchip', 'extrap');
                    lutGray = uint8(max(0, min(255, lutGray)));
                else
                    lutGray = uint8(0:255);  % Identity
                end
                adjusted = lutGray(uint16(double(img) + 1));
            end
        end
        
        function adjusted = applyAllAdjustments(img, brightness, contrast, saturation, pointsR, pointsG, pointsB)
            % Always start from original image
            % Apply in order: Brightness -> Contrast -> Curves -> Saturation
            adjusted = ImageAdjuster.adjustBrightness(img, brightness);
            adjusted = ImageAdjuster.adjustContrast(adjusted, contrast);
            adjusted = ImageAdjuster.applyCurves(adjusted, pointsR, pointsG, pointsB);
            adjusted = ImageAdjuster.adjustSaturation(adjusted, saturation);
        end
        
    end
    
end