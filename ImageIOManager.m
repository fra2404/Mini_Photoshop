% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 20/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Provides static methods for image input/output operations (loading, saving, retrieving info) using MATLAB’s image processing functions.

classdef ImageIOManager

    methods(Static)
        function [img, fullpath] = loadImageDialog(~)
            [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.bmp;*.gif', ...
                'Image Files (*.jpg, *.jpeg, *.png, *.tif, *.tiff, *.bmp, *.gif)'}, 'Open image', '', 'MultiSelect', 'off');
            if isequal(file, 0)
                img = [];
                fullpath = '';
                return;
            end
            fullpath = fullfile(path, file);
            img = imread(fullpath);
        end

        function info = getImageInfo(fullpath)
            info = imfinfo(fullpath);
        end

        function success = saveImageDialog(parentUI, img)
            success = false;
            [file, path, idx] = uiputfile({...
                '*.jpg;*.jpeg', 'JPEG Image (*.jpg, *.jpeg)'; ...
                '*.png', 'PNG Image (*.png)'; ...
                '*.tif;*.tiff', 'TIFF Image (*.tif, *.tiff)'; ...
                '*.bmp', 'Bitmap Image (*.bmp)'; ...
                '*.gif', 'GIF Image (*.gif)'; ...
                '*.*', 'All Files (*.*)'}, 'Save image');
            if isequal(file, 0)
                return;
            end
            fullpath = fullfile(path, file);
            [~, ~, ext] = fileparts(fullpath);
            ext = lower(ext);
            switch ext
                case {'.jpg', '.jpeg'}
                    fmt = 'jpg';
                case '.png'
                    fmt = 'png';
                case {'.tif', '.tiff'}
                    fmt = 'tiff';
                case '.bmp'
                    fmt = 'bmp';
                case '.gif'
                    fmt = 'gif';
                otherwise
                    switch idx
                        case 1
                            fmt = 'jpg';
                        case 2
                            fmt = 'png';
                        case 3
                            fmt = 'tiff';
                        case 4
                            fmt = 'bmp';
                        case 5
                            fmt = 'gif';
                        otherwise
                            fmt = 'png';
                    end
            end
            try
                imwrite(img, fullpath, fmt);
                success = true;
            catch ME
                if nargin > 0 && ~isempty(parentUI)
                    uialert(parentUI, ['Error saving image: ', ME.message], 'Save Error', 'Icon', 'error');
                end
            end
        end
    end
end
