function TestSaturation()
    % Test program to load an image and apply saturation change of +2

    % Load image
    [file, path] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg, *.png, *.bmp)'}, 'Select an image');
    if isequal(file, 0)
        disp('No image selected.');
        return;
    end
    img = imread(fullfile(path, file));

    % Apply saturation adjustment of +2
    adjusted = adjustSaturation(img, 2);

    % Display original and adjusted
    figure;
    subplot(1, 2, 1);
    imshow(img);
    title('Original');

    subplot(1, 2, 2);
    imshow(adjusted);
    title('Saturation +2');

    % Function to adjust saturation
    function adj = adjustSaturation(im, val)
        if size(im, 3) == 3
            hsv = rgb2hsv(im);
            hsv(:,:,2) = max(0, min(1, hsv(:,:,2) + val / 100));
            adj = hsv2rgb(hsv);
        else
            adj = im; % No change for grayscale
        end
    end
end