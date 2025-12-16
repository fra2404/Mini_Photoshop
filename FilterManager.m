% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 16/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Handles the selection, toggling, and application of image filters. Manages filter states and applies active filters to images.

classdef FilterManager < handle
    
    properties
        FilterStates  % struct with filter names and their states
    end
    
    methods
        
        function obj = FilterManager()
            obj.FilterStates = struct(...
                'GaussianBlur', false, ...
                'Sharpen', false, ...
                'Sobel', false, ...
                'Canny', false, ...
                'Emboss', false, ...
                'HistEq', false, ...
                'AdaptHist', false, ...
                'NoiseReduction', false);
        end
        
        function filtered = applySelectedFilters(obj, img, useGPU)
            if nargin < 3
                useGPU = false;
            end
            filtered = img;
            if obj.FilterStates.GaussianBlur
                filtered = ImageFilter.applyFilter(filtered, 'Gaussian Blur', useGPU);
            end
            if obj.FilterStates.Sharpen
                filtered = ImageFilter.applyFilter(filtered, 'Sharpen', useGPU);
            end
            if obj.FilterStates.Sobel
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Sobel)', useGPU);
            end
            if obj.FilterStates.Canny
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Canny)', useGPU);
            end
            if obj.FilterStates.Emboss
                filtered = ImageFilter.applyFilter(filtered, 'Emboss', useGPU);
            end
            if obj.FilterStates.HistEq
                filtered = ImageFilter.applyFilter(filtered, 'Automatic correction (histeq)', useGPU);
            end
            if obj.FilterStates.AdaptHist
                filtered = ImageFilter.applyFilter(filtered, 'Adaptive correction (adapthisteq)', useGPU);
            end
            if obj.FilterStates.NoiseReduction
                filtered = ImageFilter.applyFilter(filtered, 'Noise reduction', useGPU);
            end
        end
        
        function names = getActiveFilterNames(obj)
            names = {};
            if obj.FilterStates.GaussianBlur
                names{end+1} = 'Gaussian Blur';
            end
            if obj.FilterStates.Sharpen
                names{end+1} = 'Sharpen';
            end
            if obj.FilterStates.Sobel
                names{end+1} = 'Edge Detection (Sobel)';
            end
            if obj.FilterStates.Canny
                names{end+1} = 'Edge Detection (Canny)';
            end
            if obj.FilterStates.Emboss
                names{end+1} = 'Emboss';
            end
            if obj.FilterStates.HistEq
                names{end+1} = 'Automatic correction (histeq)';
            end
            if obj.FilterStates.AdaptHist
                names{end+1} = 'Adaptive correction (adapthisteq)';
            end
            if obj.FilterStates.NoiseReduction
                names{end+1} = 'Noise reduction';
            end
        end
        
        function hasActiveFilters = anyActive(obj)
            hasActiveFilters = obj.FilterStates.GaussianBlur || ...
                             obj.FilterStates.Sharpen || ...
                             obj.FilterStates.Sobel || ...
                             obj.FilterStates.Canny || ...
                             obj.FilterStates.Emboss || ...
                             obj.FilterStates.HistEq || ...
                             obj.FilterStates.AdaptHist || ...
                             obj.FilterStates.NoiseReduction;
        end
        
        function updateFromButtons(obj, buttons)
            obj.FilterStates.GaussianBlur = buttons.GaussianBlur.Value;
            obj.FilterStates.Sharpen = buttons.Sharpen.Value;
            obj.FilterStates.Sobel = buttons.Sobel.Value;
            obj.FilterStates.Canny = buttons.Canny.Value;
            obj.FilterStates.Emboss = buttons.Emboss.Value;
            obj.FilterStates.HistEq = buttons.HistEq.Value;
            obj.FilterStates.AdaptHist = buttons.AdaptHist.Value;
            obj.FilterStates.NoiseReduction = buttons.NoiseReduction.Value;
        end
        
    end
    
end
