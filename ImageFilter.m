% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 16/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Provides static methods to apply various image filters (e.g., blur, sharpen, edge detection) using MATLAB’s image processing functions.

classdef ImageFilter < handle
    
    methods (Static)
        
        function filtered = applyFilter(img, filter)
            switch filter
                case 'Gaussian Blur'
                    filtered = imgaussfilt(img, 10);
                case 'Sharpen'
                    filtered = imsharpen(img);
                case 'Edge Detection (Sobel)'
                    if size(img, 3) == 3
                        gray = rgb2gray(img);
                        edges = edge(gray, 'sobel');
                        filtered = uint8(repmat(edges, [1 1 3]) * 255);
                    else
                        edges = edge(img, 'sobel');
                        filtered = uint8(edges * 255);
                    end
                case 'Edge Detection (Canny)'
                    if size(img, 3) == 3
                        gray = rgb2gray(img);
                        edges = edge(gray, 'canny');
                        filtered = uint8(repmat(edges, [1 1 3]) * 255);
                    else
                        edges = edge(img, 'canny');
                        filtered = uint8(edges * 255);
                    end
                case 'Emboss'
                    kernel = [-2 -1 0; -1 1 1; 0 1 2];
                    filtered = imfilter(img, kernel);
                case 'Automatic correction (histeq)'
                    filtered = histeq(img);
                case 'Adaptive correction (adapthisteq)'
                    if size(img, 3) == 3
                        filtered = img;
                        for k = 1:3
                            filtered(:,:,k) = adapthisteq(img(:,:,k));
                        end
                    else
                        filtered = adapthisteq(img);
                    end
                case 'Noise reduction'
                    filtered = img;
                    for k = 1:size(img, 3)
                        filtered(:,:,k) = medfilt2(img(:,:,k), [5 5]);
                    end
                otherwise
                    filtered = img; % No filter applied
            end
        end
        
    end
    
end