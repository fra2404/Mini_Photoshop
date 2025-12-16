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
        
        function filtered = applyFilter(img, filter, useGPU)
            if nargin < 3
                useGPU = false;
            end
            
            switch filter
                case 'Gaussian Blur'
                    if useGPU && canUseGPU()
                        gpuImg = gpuArray(img);
                        filtered = gather(imgaussfilt(gpuImg, 10));
                    else
                        filtered = imgaussfilt(img, 10);
                    end
                case 'Sharpen'
                    if useGPU && canUseGPU()
                        gpuImg = gpuArray(img);
                        filtered = gather(imsharpen(gpuImg));
                    else
                        filtered = imsharpen(img);
                    end
                case 'Edge Detection (Sobel)'
                    if size(img, 3) == 3
                        if useGPU && canUseGPU()
                            gpuImg = gpuArray(img);
                            gray = rgb2gray(gpuImg);
                            edges = edge(gather(gray), 'sobel');
                            filtered = uint8(repmat(edges, [1 1 3]) * 255);
                        else
                            gray = rgb2gray(img);
                            edges = edge(gray, 'sobel');
                            filtered = uint8(repmat(edges, [1 1 3]) * 255);
                        end
                    else
                        edges = edge(img, 'sobel');
                        filtered = uint8(edges * 255);
                    end
                case 'Edge Detection (Canny)'
                    if size(img, 3) == 3
                        if useGPU && canUseGPU()
                            gpuImg = gpuArray(img);
                            gray = rgb2gray(gpuImg);
                            edges = edge(gather(gray), 'canny');
                            filtered = uint8(repmat(edges, [1 1 3]) * 255);
                        else
                            gray = rgb2gray(img);
                            edges = edge(gray, 'canny');
                            filtered = uint8(repmat(edges, [1 1 3]) * 255);
                        end
                    else
                        edges = edge(img, 'canny');
                        filtered = uint8(edges * 255);
                    end
                case 'Emboss'
                    kernel = [-2 -1 0; -1 1 1; 0 1 2];
                    if useGPU && canUseGPU()
                        gpuImg = gpuArray(img);
                        gpuKernel = gpuArray(kernel);
                        filtered = gather(imfilter(gpuImg, gpuKernel));
                    else
                        filtered = imfilter(img, kernel);
                    end
                case 'Automatic correction (histeq)'
                    filtered = histeq(img);
                case 'Adaptive correction (adapthisteq)'
                    if size(img, 3) == 3
                        filtered = img;
                        if useGPU && canUseGPU()
                            gpuImg = gpuArray(img);
                            for k = 1:3
                                filtered(:,:,k) = gather(adapthisteq(gpuImg(:,:,k)));
                            end
                        else
                            for k = 1:3
                                filtered(:,:,k) = adapthisteq(img(:,:,k));
                            end
                        end
                    else
                        if useGPU && canUseGPU()
                            gpuImg = gpuArray(img);
                            filtered = gather(adapthisteq(gpuImg));
                        else
                            filtered = adapthisteq(img);
                        end
                    end
                case 'Noise reduction'
                    filtered = img;
                    if useGPU && canUseGPU()
                        gpuImg = gpuArray(img);
                        for k = 1:size(img, 3)
                            filtered(:,:,k) = gather(medfilt2(gpuImg(:,:,k), [5 5]));
                        end
                    else
                        for k = 1:size(img, 3)
                            filtered(:,:,k) = medfilt2(img(:,:,k), [5 5]);
                        end
                    end
                otherwise
                    filtered = img; % No filter applied
            end
        end
        
    end
    
end