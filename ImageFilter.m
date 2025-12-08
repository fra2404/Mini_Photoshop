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
                        filtered = uint8(double(img) .* repmat(edges, [1 1 3]));
                    else
                        edges = edge(img, 'sobel');
                        filtered = uint8(double(img) .* edges);
                    end
                case 'Edge Detection (Canny)'
                    if size(img, 3) == 3
                        gray = rgb2gray(img);
                        edges = edge(gray, 'canny');
                        filtered = uint8(double(img) .* repmat(edges, [1 1 3]));
                    else
                        edges = edge(img, 'canny');
                        filtered = uint8(double(img) .* edges);
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