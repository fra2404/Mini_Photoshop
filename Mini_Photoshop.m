% Project: Mini Photoshop
% Author: Francesco
% Description: A small image editor with graphical interface in MATLAB App Designer.

classdef Mini_Photoshop < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure matlab.ui.Figure
        UIAxes matlab.ui.control.UIAxes
        HistogramAxes matlab.ui.control.UIAxes
        PlaceholderLabel matlab.ui.control.Label
        OpenButton matlab.ui.control.Button
        SaveButton matlab.ui.control.Button
        ResetButton matlab.ui.control.Button
        UndoButton matlab.ui.control.Button
        RedoButton matlab.ui.control.Button
        ShowOriginalButton matlab.ui.control.Button
        TabGroup matlab.ui.container.TabGroup
        AdjustmentsTab matlab.ui.container.Tab
        BrightnessLabel matlab.ui.control.Label
        BrightnessSlider matlab.ui.control.Slider
        BrightnessField matlab.ui.control.NumericEditField
        ContrastLabel matlab.ui.control.Label
        ContrastSlider matlab.ui.control.Slider
        ContrastField matlab.ui.control.NumericEditField
        SaturationLabel matlab.ui.control.Label
        SaturationSlider matlab.ui.control.Slider
        SaturationField matlab.ui.control.NumericEditField
        FiltersTab matlab.ui.container.Tab
        InfoTab matlab.ui.container.Tab
        ImageInfoText matlab.ui.control.TextArea
        Rotate90Button matlab.ui.control.Button
        Rotate180Button matlab.ui.control.Button
        Rotate270Button matlab.ui.control.Button
        FlipHorizontalButton matlab.ui.control.Button
        FlipVerticalButton matlab.ui.control.Button
        CropButton matlab.ui.control.Button
        ResizeLabel matlab.ui.control.Label
        ResizeEdit matlab.ui.control.NumericEditField
        ResizeButton matlab.ui.control.Button
        HistoryTab matlab.ui.container.Tab
        HistoryText matlab.ui.control.TextArea
        ExportLogButton matlab.ui.control.Button
        % CurveTab matlab.ui.container.Tab
        % CurveAxes matlab.ui.control.UIAxes
        % CurveChannelLabel matlab.ui.control.Label
        % CurveChannelDropDown matlab.ui.control.DropDown
        % AddPointButton matlab.ui.control.Button
        % RemovePointButton matlab.ui.control.Button
        % ResetCurveButton matlab.ui.control.Button
        FilterGaussianBlur matlab.ui.control.CheckBox
        FilterSharpen matlab.ui.control.CheckBox
        FilterSobel matlab.ui.control.CheckBox
        FilterCanny matlab.ui.control.CheckBox
        FilterEmboss matlab.ui.control.CheckBox
        FilterHistEq matlab.ui.control.CheckBox
        FilterAdaptHist matlab.ui.control.CheckBox
        FilterNoiseReduction matlab.ui.control.CheckBox
        ApplyFiltersButton matlab.ui.control.Button
    end

    properties (Access = private)
        OriginalImage
        CurrentImage
        HistoryManager
        CurrentBrightness
        CurrentContrast
        CurrentSaturation
        % CurvePointsR  % [x;y] points for R curve
        % CurvePointsG  % [x;y] points for G curve
        % CurvePointsB  % [x;y] points for B curve
        % CurrentChannel  % 'R', 'G', 'B', 'RGB'
        % SelectedPointIndex  % index of selected point for dragging
        HasUnsavedChanges
        ShowingOriginal
        % AddMode  % flag for adding points
        % RemoveMode  % flag for removing points
        AdjustmentTimer  % timer for debouncing adjustments
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.HistoryManager = HistoryManager();
            app.OriginalImage = [];
            app.CurrentImage = [];
            app.CurrentBrightness = 0;
            app.CurrentContrast = 0;
            app.CurrentSaturation = 0;
            % % Initialize curve points as diagonal lines
            % app.CurvePointsR = [0 255; 0 255];
            % app.CurvePointsG = [0 255; 0 255];
            % app.CurvePointsB = [0 255; 0 255];
            % app.CurrentChannel = 'RGB';
            % app.SelectedPointIndex = 0;
            app.HasUnsavedChanges = false;
            app.ShowingOriginal = false;
            % app.AddMode = false;
            % app.RemoveMode = false;
            app.AdjustmentTimer = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.2, 'TimerFcn', @app.applyAdjustments);
            app.UIAxes.Visible = 'off';
            app.HistogramAxes.Visible = 'off';
            app.PlaceholderLabel.Visible = 'on';
            % app.CurveAxes.ButtonDownFcn = @app.CurveAxesButtonDown;
            % UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
        end

        function updateHistoryText(app)
            app.HistoryText.Value = strjoin(app.HistoryManager.HistoryLog, newline);
        end

        function applyAdjustments(app, ~, ~)
            if isempty(app.CurrentImage)
                return;
            end
            % Check if all adjustments are at default (no changes)
            isDefault = (app.CurrentBrightness == 0) && (app.CurrentContrast == 0) && (app.CurrentSaturation == 0);
            if isDefault
                % Directly set to original
                adjusted = app.OriginalImage;
            else
                % Apply all adjustments from the original
                adjusted = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            end
            cla(app.UIAxes);
            imshow(adjusted, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(adjusted, app.HistogramAxes);
            app.CurrentImage = adjusted;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            app.HasUnsavedChanges = true;
            app.HistoryManager.addToHistoryLog(sprintf('Adjustments: B=%.1f, C=%.1f, S=%.1f', app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation));
            app.updateHistoryText();
        end

        % Button pushed function: OpenButton
        function OpenButtonPushed(app, ~, ~)
            if app.HasUnsavedChanges
                selection = uiconfirm(app.UIFigure, 'You have unsaved changes. Are you sure you want to open a new image?', 'Confirm open', ...
                    'Options', {'Yes', 'No'}, 'DefaultOption', 2, 'CancelOption', 2);
                if strcmp(selection, 'No')
                    return;
                end
            end
            [file, path] = uigetfile({'*.jpg;*.png', 'Image Files (*.jpg, *.png)'});
            if isequal(file, 0)
                return;
            end
            fullpath = fullfile(path, file);
            app.OriginalImage = imread(fullpath);
            info = imfinfo(fullpath);
            text = sprintf('Format: %s\nSize: %dx%d pixels', info.Format, info.Width, info.Height);
            if isfield(info, 'ColorType')
                text = [text sprintf('\nColor type: %s', info.ColorType)];
            end
            if isfield(info, 'BitDepth')
                text = [text sprintf('\nBit depth: %d', info.BitDepth)];
            end
            if isfield(info, 'FileSize')
                text = [text sprintf('\nFile size: %.2f MB', info.FileSize / 1e6)];
            end
            % Add EXIF info
            exifText = MetadataExtractor.extractExifInfo(info);
            text = [text '\n\nExtracted EXIF info:' exifText];
            app.ImageInfoText.Value = splitlines(text);
            
            app.CurrentImage = app.OriginalImage;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.UIAxes.Visible = 'on';
            app.HistogramAxes.Visible = 'on';
            app.PlaceholderLabel.Visible = 'off';
            app.HasUnsavedChanges = false;
            app.ShowingOriginal = false;
            app.ShowOriginalButton.Text = 'Show Original';
            app.HistoryManager.addToHistoryLog('Image opened');
            app.updateHistoryText();
            app.updateHistoryText();
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            [file, path] = uiputfile({'*.jpg', 'JPEG'; '*.png', 'PNG'}, 'Save image');
            if isequal(file, 0)
                return;
            end
            fullpath = fullfile(path, file);
            imwrite(app.CurrentImage, fullpath);
            uialert(app.UIFigure, 'Image saved successfully', 'Confirm', 'Icon', 'success');
            app.HasUnsavedChanges = false;
            app.HistoryManager.addToHistoryLog('Image saved');
            app.updateHistoryText();
            app.updateHistoryText();
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, ~, ~)
            if isempty(app.OriginalImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            selection = uiconfirm(app.UIFigure, 'Are you sure you want to reset the image? Note that you can always use Undo to go back.', 'Confirm reset', ...
                'Options', {'Yes', 'No'}, 'DefaultOption', 2, 'CancelOption', 2);
            if strcmp(selection, 'No')
                return;
            end
            % Reset all adjustments
            app.CurrentBrightness = 0;
            app.CurrentContrast = 0;
            app.CurrentSaturation = 0;
            app.CurvePointsR = [0 255; 0 255];
            app.CurvePointsG = [0 255; 0 255];
            app.CurvePointsB = [0 255; 0 255];
            app.BrightnessSlider.Value = 0;
            app.ContrastSlider.Value = 0;
            app.SaturationSlider.Value = 0;
            UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
            % Show original image
            cla(app.UIAxes);
            imshow(app.OriginalImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.OriginalImage, app.HistogramAxes);
            app.CurrentImage = app.OriginalImage;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            app.HasUnsavedChanges = false;
            app.ShowingOriginal = false;
            app.ShowOriginalButton.Text = 'Show Original';
            app.HistoryManager.addToHistoryLog('Reset image');
            app.updateHistoryText();
        end

        function UndoButtonPushed(app, ~, ~)
            entry = app.HistoryManager.undo();
            if ~isempty(entry)
                app.CurrentImage = entry.image;
                app.CurrentBrightness = entry.brightness;
                app.CurrentContrast = entry.contrast;
                app.CurrentSaturation = entry.saturation;
                % app.CurvePointsR = entry.pointsR;
                % app.CurvePointsG = entry.pointsG;
                % app.CurvePointsB = entry.pointsB;
                app.BrightnessSlider.Value = app.CurrentBrightness;
                app.ContrastSlider.Value = app.CurrentContrast;
                app.SaturationSlider.Value = app.CurrentSaturation;
                app.BrightnessField.Value = app.CurrentBrightness;
                app.ContrastField.Value = app.CurrentContrast;
                app.SaturationField.Value = app.CurrentSaturation;
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
                % UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
                app.HistoryManager.addToHistoryLog('Undo');
                app.updateHistoryText();
            end
        end

        % Button pushed function: RedoButton
        function RedoButtonPushed(app, ~, ~)
            entry = app.HistoryManager.redo();
            if ~isempty(entry)
                app.CurrentImage = entry.image;
                app.CurrentBrightness = entry.brightness;
                app.CurrentContrast = entry.contrast;
                app.CurrentSaturation = entry.saturation;
                % app.CurvePointsR = entry.pointsR;
                % app.CurvePointsG = entry.pointsG;
                % app.CurvePointsB = entry.pointsB;
                app.BrightnessSlider.Value = app.CurrentBrightness;
                app.ContrastSlider.Value = app.CurrentContrast;
                app.SaturationSlider.Value = app.CurrentSaturation;
                app.BrightnessField.Value = app.CurrentBrightness;
                app.ContrastField.Value = app.CurrentContrast;
                app.SaturationField.Value = app.CurrentSaturation;
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
                % UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
                app.HistoryManager.addToHistoryLog('Redo');
                app.updateHistoryText();
            end
        end

        % Button pushed function: ShowOriginalButton
        function ShowOriginalButtonPushed(app, ~, ~)
            if isempty(app.OriginalImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                % Back to current image
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                app.ShowOriginalButton.Text = 'Show Original';
                app.ShowingOriginal = false;
                UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            else
                % Show the original image
                imshow(app.OriginalImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                app.ShowOriginalButton.Text = 'Show Modified';
                app.ShowingOriginal = true;
                UIManager.updateHistogram(app.OriginalImage, app.HistogramAxes);
            end
        end

        % Value changed function: BrightnessSlider
        function BrightnessSliderValueChanged(app, ~, ~)
            if isempty(app.CurrentImage)
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            value = app.BrightnessSlider.Value;
            app.CurrentBrightness = value;
            app.BrightnessField.Value = value;  % Sync field
            % Check if all are at default
            isDefault = (app.CurrentBrightness == 0) && (app.CurrentContrast == 0) && (app.CurrentSaturation == 0) && ...
                        isequal(app.CurvePointsR, [0 255; 0 255]) && isequal(app.CurvePointsG, [0 255; 0 255]) && isequal(app.CurvePointsB, [0 255; 0 255]);
            if isDefault
                % Apply immediately
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
            else
                % Debounce the application
                stop(app.AdjustmentTimer);
                start(app.AdjustmentTimer);
            end
        end

        % Value changed function: ContrastSlider
        function ContrastSliderValueChanged(app, ~, ~)
            if isempty(app.CurrentImage)
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            value = app.ContrastSlider.Value;
            app.CurrentContrast = value;
            app.ContrastField.Value = value;  % Sync field
            % Check if all are at default
            isDefault = (app.CurrentBrightness == 0) && (app.CurrentContrast == 0) && (app.CurrentSaturation == 0) && ...
                        isequal(app.CurvePointsR, [0 255; 0 255]) && isequal(app.CurvePointsG, [0 255; 0 255]) && isequal(app.CurvePointsB, [0 255; 0 255]);
            if isDefault
                % Apply immediately
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
            else
                % Debounce the application
                stop(app.AdjustmentTimer);
                start(app.AdjustmentTimer);
            end
        end

        % Value changed function: SaturationSlider
        function SaturationSliderValueChanged(app, ~, ~)
            if isempty(app.CurrentImage)
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            value = app.SaturationSlider.Value;
            app.CurrentSaturation = value;
            app.SaturationField.Value = value;  % Sync field
            % Check if all are at default
            isDefault = (app.CurrentBrightness == 0) && (app.CurrentContrast == 0) && (app.CurrentSaturation == 0) && ...
                        isequal(app.CurvePointsR, [0 255; 0 255]) && isequal(app.CurvePointsG, [0 255; 0 255]) && isequal(app.CurvePointsB, [0 255; 0 255]);
            if isDefault
                % Apply immediately
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
            else
                % Debounce the application
                stop(app.AdjustmentTimer);
                start(app.AdjustmentTimer);
            end
        end

        % Value changed function: BrightnessField
        function BrightnessFieldValueChanged(app, ~, ~)
            value = app.BrightnessField.Value;
            app.BrightnessSlider.Value = value;
            app.BrightnessSliderValueChanged();
        end

        % Value changed function: ContrastField
        function ContrastFieldValueChanged(app, ~, ~)
            value = app.ContrastField.Value;
            app.ContrastSlider.Value = value;
            app.ContrastSliderValueChanged();
        end

        % Value changed function: SaturationField
        function SaturationFieldValueChanged(app, ~, ~)
            value = app.SaturationField.Value;
            app.SaturationSlider.Value = value;
            app.SaturationSliderValueChanged();
        end

        % Button pushed function: ApplyFiltersButton
        function ApplyFiltersButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            filtered = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation);
            filtersApplied = {};
            if app.FilterGaussianBlur.Value
                filtered = ImageFilter.applyFilter(filtered, 'Gaussian Blur');
                filtersApplied{end+1} = 'Gaussian Blur';
            end
            if app.FilterSharpen.Value
                filtered = ImageFilter.applyFilter(filtered, 'Sharpen');
                filtersApplied{end+1} = 'Sharpen';
            end
            if app.FilterSobel.Value
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Sobel)');
                filtersApplied{end+1} = 'Edge Detection (Sobel)';
            end
            if app.FilterCanny.Value
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Canny)');
                filtersApplied{end+1} = 'Edge Detection (Canny)';
            end
            if app.FilterEmboss.Value
                filtered = ImageFilter.applyFilter(filtered, 'Emboss');
                filtersApplied{end+1} = 'Emboss';
            end
            if app.FilterHistEq.Value
                filtered = ImageFilter.applyFilter(filtered, 'Automatic correction (histeq)');
                filtersApplied{end+1} = 'Automatic correction (histeq)';
            end
            if app.FilterAdaptHist.Value
                filtered = ImageFilter.applyFilter(filtered, 'Adaptive correction (adapthisteq)');
                filtersApplied{end+1} = 'Adaptive correction (adapthisteq)';
            end
            if app.FilterNoiseReduction.Value
                filtered = ImageFilter.applyFilter(filtered, 'Noise reduction');
                filtersApplied{end+1} = 'Noise reduction';
            end
            if isempty(filtersApplied)
                % Reset to original image with current adjustments
                if app.CurrentBrightness == 0 && app.CurrentContrast == 0 && app.CurrentSaturation == 0
                    app.CurrentImage = app.OriginalImage;
                else
                    app.CurrentImage = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation);
                end
                app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
                app.HasUnsavedChanges = true;
                app.HistoryManager.addToHistoryLog('Filters reset');
                app.updateHistoryText();
                return;
            end
            app.CurrentImage = filtered;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.HasUnsavedChanges = true;
            logMsg = ['Filters applied: ' strjoin(filtersApplied, ', ')];
            app.HistoryManager.addToHistoryLog(logMsg);
            app.updateHistoryText();
        end

        % Button pushed function: Rotate90Button
        function Rotate90ButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            rotated = imrotate(app.CurrentImage, -90);
            app.CurrentImage = rotated;
            app.OriginalImage = rotated;  % Update the original for persistence
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.HasUnsavedChanges = true;
            app.HistoryManager.addToHistoryLog('Rotation 90°');
            app.updateHistoryText();
        end

        % Button pushed function: Rotate180Button
        function Rotate180ButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            rotated = imrotate(app.CurrentImage, 180);
            app.CurrentImage = rotated;
            app.OriginalImage = rotated;  % Update the original for persistence
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.HasUnsavedChanges = true;
            app.HistoryManager.addToHistoryLog('Rotation 180°');
            app.updateHistoryText();
        end

        % Button pushed function: Rotate270Button
        function Rotate270ButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            rotated = imrotate(app.CurrentImage, 90);
            app.CurrentImage = rotated;
            app.OriginalImage = rotated;  % Update the original for persistence
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.HasUnsavedChanges = true;
            app.HistoryManager.addToHistoryLog('Rotation 270°');
            app.updateHistoryText();
        end

        % Button pushed function: FlipHorizontalButton
        function FlipHorizontalButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            flipped = flip(app.CurrentImage, 2);
            app.CurrentImage = flipped;
            app.OriginalImage = flipped;  % Update the original for persistence
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.HasUnsavedChanges = true;
            app.HistoryManager.addToHistoryLog('Horizontal flip');
            app.updateHistoryText();
        end

        % Button pushed function: FlipVerticalButton
        function FlipVerticalButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            flipped = flip(app.CurrentImage, 1);
            app.CurrentImage = flipped;
            app.OriginalImage = flipped;  % Update the original for persistence
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.HasUnsavedChanges = true;
            app.HistoryManager.addToHistoryLog('Vertical flip');
            app.updateHistoryText();
        end

        % Button pushed function: CropButton
        function CropButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            % Interactive crop
            cropped = imcrop(app.CurrentImage);
            if ~isempty(cropped)
                [height, width, ~] = size(cropped);
                app.CurrentImage = cropped;
                app.OriginalImage = cropped;  % Update the original for persistence
                app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
                app.HasUnsavedChanges = true;
                app.HistoryManager.addToHistoryLog(sprintf('Crop applied: %dx%d', width, height));
                app.updateHistoryText();
            end
        end

        % Button pushed function: ResizeButton
        function ResizeButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            if app.ShowingOriginal
                app.ShowingOriginal = false;
                app.ShowOriginalButton.Text = 'Show Original';
            end
            scale = app.ResizeEdit.Value;
            resized = imresize(app.CurrentImage, scale);
            app.CurrentImage = resized;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            UIManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.HasUnsavedChanges = true;
            app.HistoryManager.addToHistoryLog(['Resize: ' num2str(scale)]);
            app.updateHistoryText();
        end

    end

    % Helper functions
    methods (Access = private)

        function exifText = extractExifInfo(~, info)
            exifText = '';
            % Device Make
            make = [];
            if isfield(info, 'Make')
                make = info.Make;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Make')
                make = info.DigitalCamera.Make;
            end
            if ~isempty(make)
                exifText = [exifText sprintf('\nDevice Make: %s', make)];
            end
            % Device Model
            model = [];
            if isfield(info, 'Model')
                model = info.Model;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Model')
                model = info.DigitalCamera.Model;
            end
            if ~isempty(model)
                exifText = [exifText sprintf('\nDevice Model: %s', model)];
            end
            % ISO
            iso = [];
            if isfield(info, 'ISOSpeedRatings')
                iso = info.ISOSpeedRatings;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ISOSpeedRatings')
                iso = info.DigitalCamera.ISOSpeedRatings;
            end
            if ~isempty(iso)
                exifText = [exifText sprintf('\nISO: %d', iso)];
            end
            % F-stop
            fnumber = [];
            if isfield(info, 'FNumber')
                fnumber = info.FNumber;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FNumber')
                fnumber = info.DigitalCamera.FNumber;
            end
            if ~isempty(fnumber)
                exifText = [exifText sprintf('\nF-stop: f/%.1f', fnumber)];
            end
            % Focal Length
            focallength = [];
            if isfield(info, 'FocalLength')
                focallength = info.FocalLength;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FocalLength')
                focallength = info.DigitalCamera.FocalLength;
            end
            if ~isempty(focallength)
                exifText = [exifText sprintf('\nFocal Length: %.1f mm', focallength)];
            end
            % Exposure Time
            exposuretime = [];
            if isfield(info, 'ExposureTime')
                exposuretime = info.ExposureTime;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ExposureTime')
                exposuretime = info.DigitalCamera.ExposureTime;
            end
            if ~isempty(exposuretime)
                exifText = [exifText sprintf('\nExposure Time: 1/%.0f s', 1/exposuretime)];
            end
            % Exposure Program
            exposureprogram = [];
            if isfield(info, 'ExposureProgram')
                exposureprogram = info.ExposureProgram;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ExposureProgram')
                exposureprogram = info.DigitalCamera.ExposureProgram;
            end
            if ~isempty(exposureprogram)
                exifText = [exifText sprintf('\nExposure Program: %s', exposureprogram)];
            end
            % Metering Mode
            meteringmode = [];
            if isfield(info, 'MeteringMode')
                meteringmode = info.MeteringMode;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'MeteringMode')
                meteringmode = info.DigitalCamera.MeteringMode;
            end
            if ~isempty(meteringmode)
                exifText = [exifText sprintf('\nMetering Mode: %s', meteringmode)];
            end
            % Lens info from XMP if available
            lens = [];
            if isfield(info, 'XMPData') && isfield(info.XMPData, 'aux') && isfield(info.XMPData.aux, 'Lens')
                lens = info.XMPData.aux.Lens;
            elseif isfield(info, 'XMPData') && isfield(info.XMPData, 'exifEX') && isfield(info.XMPData.exifEX, 'LensModel')
                lens = info.XMPData.exifEX.LensModel;
            end
            if ~isempty(lens)
                exifText = [exifText sprintf('\nLens: %s', lens)];
            end
            % Copyright
            copyright = [];
            if isfield(info, 'Copyright')
                copyright = info.Copyright;
            end
            if ~isempty(copyright)
                exifText = [exifText sprintf('\nCopyright: %s', copyright)];
            end
            % Artist
            artist = [];
            if isfield(info, 'Artist')
                artist = info.Artist;
            end
            if ~isempty(artist)
                exifText = [exifText sprintf('\nArtist: %s', artist)];
            end
            % Software
            software = [];
            if isfield(info, 'Software')
                software = info.Software;
            end
            if ~isempty(software)
                exifText = [exifText sprintf('\nSoftware: %s', software)];
            end
            % Date Taken
            datetimeoriginal = [];
            if isfield(info, 'DateTimeOriginal')
                datetimeoriginal = info.DateTimeOriginal;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'DateTimeOriginal')
                datetimeoriginal = info.DigitalCamera.DateTimeOriginal;
            end
            if ~isempty(datetimeoriginal)
                exifText = [exifText sprintf('\nDate Taken: %s', datetimeoriginal)];
            end
            % Image Description
            imagedescription = [];
            if isfield(info, 'ImageDescription')
                imagedescription = info.ImageDescription;
            end
            if ~isempty(imagedescription)
                exifText = [exifText sprintf('\nImage Description: %s', imagedescription)];
            end
            % White Balance
            whitebalance = [];
            if isfield(info, 'WhiteBalance')
                whitebalance = info.WhiteBalance;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'WhiteBalance')
                whitebalance = info.DigitalCamera.WhiteBalance;
            end
            if ~isempty(whitebalance)
                exifText = [exifText sprintf('\nWhite Balance: %s', whitebalance)];
            end
            % Flash
            flash = [];
            if isfield(info, 'Flash')
                flash = info.Flash;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Flash')
                flash = info.DigitalCamera.Flash;
            end
            if ~isempty(flash)
                exifText = [exifText sprintf('\nFlash: %s', flash)];
            end
        end

        function adjusted = adjustBrightness(~, img, value)
            adjusted = double(img) + value;
            adjusted = uint8(max(0, min(255, adjusted)));
        end

        function adjusted = adjustContrast(~, img, value)
            factor = 1 + value / 100;
            adjusted = (double(img) - 128) * factor + 128;
            adjusted = uint8(max(0, min(255, adjusted)));
        end

        function adjusted = adjustSaturation(~, img, value)
            if size(img, 3) == 3
                hsv = rgb2hsv(img);
                hsv(:,:,2) = hsv(:,:,2) * (1 + value / 100);
                hsv(:,:,2) = min(max(hsv(:,:,2), 0), 1);
                adjusted = hsv2rgb(hsv);
            else
                adjusted = img; % No saturation adjustment for grayscale
            end
        end

        function adjusted = applyAllAdjustments(app, img)
            adjusted = app.adjustBrightness(img, app.CurrentBrightness);
            adjusted = app.adjustContrast(adjusted, app.CurrentContrast);
            adjusted = app.adjustSaturation(adjusted, app.CurrentSaturation);
            % adjusted = app.applyCurves(adjusted, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB);
        end

        % function adjusted = applyCurves(~, img, pointsR, pointsG, pointsB)
        %     if size(img, 3) == 3
        %         adjusted = img;
        %         % Create LUT for R channel
        %         lutR = interp1(pointsR(1,:), pointsR(2,:), 0:255, 'linear', 'extrap');
        %         lutR = uint8(max(0, min(255, lutR)));
        %         adjusted(:,:,1) = lutR(img(:,:,1) + 1);
        %         
        %         % Create LUT for G channel
        %         lutG = interp1(pointsG(1,:), pointsG(2,:), 0:255, 'linear', 'extrap');
        %         lutG = uint8(max(0, min(255, lutG)));
        %         adjusted(:,:,2) = lutG(img(:,:,2) + 1);
        %         
        %         % Create LUT for B channel
        %         lutB = interp1(pointsB(1,:), pointsB(2,:), 0:255, 'linear', 'extrap');
        %         lutB = uint8(max(0, min(255, lutB)));
        %         adjusted(:,:,3) = lutB(img(:,:,3) + 1);
        %     else
        %         % For grayscale, apply average curve
        %         avgPoints = (pointsR + pointsG + pointsB) / 3;
        %         lutGray = interp1(avgPoints(1,:), avgPoints(2,:), 0:255, 'linear', 'extrap');
        %         lutGray = uint8(max(0, min(255, lutGray)));
        %         adjusted = lutGray(img + 1);
        %     end
        % end

        % function filtered = applyFilter(~, img, filter)
        %     switch filter
        %         case 'Gaussian Blur'
        %             filtered = imgaussfilt(img, 10);
        %         case 'Sharpen'
        %             filtered = imsharpen(img);
        %         case 'Edge Detection (Sobel)'
        %             if size(img, 3) == 3
        %                 gray = rgb2gray(img);
        %             else
        %                 gray = img;
        %             end
        %             edges = edge(gray, 'sobel');
        %             filtered = uint8(double(img) .* edges);
        %         case 'Edge Detection (Canny)'
        %             if size(img, 3) == 3
        %                 gray = rgb2gray(img);
        %             else
        %                 gray = img;
        %             end
        %             edges = edge(gray, 'canny');
        %             filtered = uint8(double(img) .* edges);
        %         case 'Emboss'
        %             kernel = [-2 -1 0; -1 1 1; 0 1 2];
        %             if size(img, 3) == 3
        %                 embossed = imfilter(rgb2gray(img), kernel);
        %                 filtered = uint8(double(img) + embossed);
        %             else
        %                 filtered = imfilter(img, kernel);
        %             end
        %         case 'Correzione automatica (histeq)'
        %             if size(img, 3) == 3
        %                 hsv = rgb2hsv(img);
        %                 hsv(:,:,3) = histeq(hsv(:,:,3));
        %                 filtered = hsv2rgb(hsv);
        %             else
        %                 filtered = histeq(img);
        %             end
        %         case 'Correzione adattiva (adapthisteq)'
        %             if size(img, 3) == 3
        %                 hsv = rgb2hsv(img);
        %                 hsv(:,:,3) = adapthisteq(hsv(:,:,3));
        %                 filtered = hsv2rgb(hsv);
        %             else
        %                 filtered = adapthisteq(img);
        %             end
        %     end
        % end

        function updateHistogram(app)
            if isempty(app.CurrentImage)
                return;
            end
            cla(app.HistogramAxes);
            if size(app.CurrentImage, 3) == 3
                % For color images, show histogram of intensity
                gray = rgb2gray(app.CurrentImage);
                histogram(app.HistogramAxes, gray(:), 'BinWidth', 1, 'FaceColor', 'k');
            else
                histogram(app.HistogramAxes, app.CurrentImage(:), 'BinWidth', 1, 'FaceColor', 'k');
            end
            title(app.HistogramAxes, 'Istogramma');
            xlim(app.HistogramAxes, [0 255]);
        end

        % function updateCurvePlots(app)
        %     x = 0:255;
        %     gammaR = app.CurveRSlider.Value;
        %     gammaG = app.CurveGSlider.Value;
        %     gammaB = app.CurveBSlider.Value;
        %     yR = uint8(255 * (double(x)/255).^gammaR);
        %     yG = uint8(255 * (double(x)/255).^gammaG);
        %     yB = uint8(255 * (double(x)/255).^gammaB);
        %     cla(app.CurveAxes);
        %     hold(app.CurveAxes, 'on');
        %     plot(app.CurveAxes, x, yR, 'r', 'LineWidth', 2);
        %     plot(app.CurveAxes, x, yG, 'g', 'LineWidth', 2);
        %     plot(app.CurveAxes, x, yB, 'b', 'LineWidth', 2);
        %     hold(app.CurveAxes, 'off');
        %     title(app.CurveAxes, 'Curve RGB');
        %     xlim(app.CurveAxes, [0 255]);
        %     ylim(app.CurveAxes, [0 255]);
        %     legend(app.CurveAxes, 'R', 'G', 'B');
        % end

        function pushToHistory(app, img)
            app.HistoryIndex = app.HistoryIndex + 1;
            if app.HistoryIndex > length(app.History)
                app.History{app.HistoryIndex} = struct('image', img, 'brightness', app.CurrentBrightness, 'contrast', app.CurrentContrast, 'saturation', app.CurrentSaturation, 'gammaR', app.CurrentGammaR, 'gammaG', app.CurrentGammaG, 'gammaB', app.CurrentGammaB);
            else
                app.History{app.HistoryIndex} = struct('image', img, 'brightness', app.CurrentBrightness, 'contrast', app.CurrentContrast, 'saturation', app.CurrentSaturation, 'gammaR', app.CurrentGammaR, 'gammaG', app.CurrentGammaG, 'gammaB', app.CurrentGammaB);
                app.History(app.HistoryIndex+1:end) = [];
            end
        end

        function ExportLogButtonPushed(app, ~, ~)
            if isempty(app.HistoryManager.HistoryLog)
                uialert(app.UIFigure, 'No log available', 'Error');
                return;
            end
            [file, path] = uiputfile('*.txt', 'Export operations log');
            if isequal(file, 0)
                return;
            end
            fullpath = fullfile(path, file);
            fid = fopen(fullpath, 'w');
            for i = 1:length(app.HistoryManager.HistoryLog)
                fprintf(fid, '%s\n', app.HistoryManager.HistoryLog{i});
            end
            fclose(fid);
            uialert(app.UIFigure, 'Log exported successfully', 'Confirm', 'Icon', 'success');
        end


        % % Value changed function: CurveGSlider
        % function CurveGSliderValueChanged(app, ~, ~)
        %     if isempty(app.CurrentImage)
        %         return;
        %     end
        %     if app.ShowingOriginal
        %         app.ShowingOriginal = false;
        %         app.ShowOriginalButton.Text = 'Show Original';
        %     end
        %     value = app.CurveGSlider.Value;
        %     app.CurrentGammaG = value;
        %     % Apply all adjustments from the original
        %     adjusted = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB);
        %     cla(app.UIAxes);
        %     imshow(adjusted, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
        %     UIManager.updateHistogram(adjusted, app.HistogramAxes);
        %     UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB);
        %     app.CurrentImage = adjusted;
        %     app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
        %     app.HasUnsavedChanges = true;
        %     app.HistoryManager.addToHistoryLog(sprintf('Curve G: %.2f', value));
        %     app.updateHistoryText();
        % end

        % % Value changed function: CurveBSlider
        % function CurveBSliderValueChanged(app, ~, ~)
        %     if isempty(app.CurrentImage)
        %         return;
        %     end
        %     if app.ShowingOriginal
        %         app.ShowingOriginal = false;
        %         app.ShowOriginalButton.Text = 'Show Original';
        %     end
        %     value = app.CurveBSlider.Value;
        %     app.CurrentGammaB = value;
        %     % Apply all adjustments from the original
        %     adjusted = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB);
        %     cla(app.UIAxes);
        %     imshow(adjusted, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
        %     UIManager.updateHistogram(adjusted, app.HistogramAxes);
        %     UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB);
        %     app.CurrentImage = adjusted;
        %     app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
        %     app.HasUnsavedChanges = true;
        %     app.HistoryManager.addToHistoryLog(sprintf('Curve B: %.2f', value));
        %     app.updateHistoryText();
        % end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, ~, ~)
            if app.HasUnsavedChanges
                selection = uiconfirm(app.UIFigure, 'You have unsaved changes. Do you want to save before closing?', 'Confirm close', ...
                    'Options', {'Save', 'Do not save', 'Cancel'}, 'DefaultOption', 3, 'CancelOption', 3);
                if strcmp(selection, 'Save')
                    % Simula salvataggio
                    if isempty(app.CurrentImage)
                        uialert(app.UIFigure, 'No image loaded', 'Error');
                        return;
                    end
                    [file, path] = uiputfile({'*.jpg', 'JPEG'; '*.png', 'PNG'}, 'Save image');
                    if ~isequal(file, 0)
                        fullpath = fullfile(path, file);
                        imwrite(app.CurrentImage, fullpath);
                        app.HasUnsavedChanges = false;
                    else
                        return;
                    end
                elseif strcmp(selection, 'Cancel')
                    return;
                end
            end
            delete(app.UIFigure);
        end


        % Button pushed function: ResetGButton
        function ResetGButtonPushed(app, ~, ~)
            app.CurveGSlider.Value = 1;
            app.CurveGSliderValueChanged();
        end

        % Button pushed function: ResetBButton
        function ResetBButtonPushed(app, ~, ~)
            app.CurveBSlider.Value = 1;
            app.CurveBSliderValueChanged();
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure('Name', 'Mini Photoshop', 'Position', [100 100 1200 700], 'Resize', 'off', 'Color', [0.95 0.95 0.95], 'CloseRequestFcn', @app.UIFigureCloseRequest);

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [50 10 700 480];
            app.UIAxes.Visible = 'off';
            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'off';
            app.UIAxes.Box = 'off';
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];

            % Create HistogramAxes
            app.HistogramAxes = uiaxes(app.UIFigure);
            app.HistogramAxes.Position = [100 500 600 120];
            app.HistogramAxes.Visible = 'off';

            % Create PlaceholderLabel
            app.PlaceholderLabel = uilabel(app.UIFigure, 'Text', 'Load an image to start', 'Position', [150 300 400 80], 'HorizontalAlignment', 'center', 'FontSize', 18, 'FontWeight', 'bold');

            % Toolbar buttons
            app.OpenButton = uibutton(app.UIFigure, 'push', 'Text', 'Open Image', 'Position', [10 650 100 30], 'BackgroundColor', [0.8 1 0.8], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.OpenButtonPushed);
            app.SaveButton = uibutton(app.UIFigure, 'push', 'Text', 'Save Image', 'Position', [120 650 100 30], 'BackgroundColor', [0.8 0.9 1], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.SaveButtonPushed);
            app.ResetButton = uibutton(app.UIFigure, 'push', 'Text', 'Reset', 'Position', [230 650 100 30], 'BackgroundColor', [1 0.8 0.8], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.ResetButtonPushed);
            app.UndoButton = uibutton(app.UIFigure, 'push', 'Text', 'Undo', 'Position', [340 650 100 30], 'BackgroundColor', [0.9 0.9 0.9], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.UndoButtonPushed);
            app.RedoButton = uibutton(app.UIFigure, 'push', 'Text', 'Redo', 'Position', [450 650 100 30], 'BackgroundColor', [0.9 0.9 0.9], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.RedoButtonPushed);
            app.ShowOriginalButton = uibutton(app.UIFigure, 'push', 'Text', 'Show Original', 'Position', [560 650 120 30], 'BackgroundColor', [1 1 0.8], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.ShowOriginalButtonPushed);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure, 'Position', [750 60 350 580]);

            % Adjustments Tab
            app.AdjustmentsTab = uitab(app.TabGroup, 'Title', 'Adjustments');
            % Adjustments
            app.BrightnessLabel = uilabel(app.AdjustmentsTab, 'Text', 'Brightness', 'Position', [30 300 80 20], 'FontWeight', 'bold');
            app.BrightnessSlider = uislider(app.AdjustmentsTab, 'Limits', [-100 100], 'Value', 0, 'Position', [120 305 150 3], 'ValueChangedFcn', @app.BrightnessSliderValueChanged);
            app.BrightnessField = uieditfield(app.AdjustmentsTab, 'numeric', 'Limits', [-100 100], 'Value', 0, 'Position', [280 300 50 20], 'ValueChangedFcn', @app.BrightnessFieldValueChanged);
            app.ContrastLabel = uilabel(app.AdjustmentsTab, 'Text', 'Contrast', 'Position', [30 250 80 20], 'FontWeight', 'bold');
            app.ContrastSlider = uislider(app.AdjustmentsTab, 'Limits', [-100 100], 'Value', 0, 'Position', [120 255 150 3], 'ValueChangedFcn', @app.ContrastSliderValueChanged);
            app.ContrastField = uieditfield(app.AdjustmentsTab, 'numeric', 'Limits', [-100 100], 'Value', 0, 'Position', [280 250 50 20], 'ValueChangedFcn', @app.ContrastFieldValueChanged);
            app.SaturationLabel = uilabel(app.AdjustmentsTab, 'Text', 'Saturation', 'Position', [30 200 80 20], 'FontWeight', 'bold');
            app.SaturationSlider = uislider(app.AdjustmentsTab, 'Limits', [-100 100], 'Value', 0, 'Position', [120 205 150 3], 'ValueChangedFcn', @app.SaturationSliderValueChanged);
            app.SaturationField = uieditfield(app.AdjustmentsTab, 'numeric', 'Limits', [-100 100], 'Value', 0, 'Position', [280 200 50 20], 'ValueChangedFcn', @app.SaturationFieldValueChanged);

            % Transformations
            app.Rotate90Button = uibutton(app.AdjustmentsTab, 'push', 'Text', 'Rotate 90°', 'Position', [40 90 90 30], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.Rotate90ButtonPushed);
            app.Rotate180Button = uibutton(app.AdjustmentsTab, 'push', 'Text', 'Rotate 180°', 'Position', [140 90 90 30], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.Rotate180ButtonPushed);
            app.Rotate270Button = uibutton(app.AdjustmentsTab, 'push', 'Text', 'Rotate 270°', 'Position', [240 90 90 30], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.Rotate270ButtonPushed);
            app.FlipHorizontalButton = uibutton(app.AdjustmentsTab, 'push', 'Text', 'Flip H.', 'Position', [40 50 90 30], 'BackgroundColor', [1 0.95 0.9], 'ButtonPushedFcn', @app.FlipHorizontalButtonPushed);
            app.FlipVerticalButton = uibutton(app.AdjustmentsTab, 'push', 'Text', 'Flip V.', 'Position', [140 50 90 30], 'BackgroundColor', [1 0.95 0.9], 'ButtonPushedFcn', @app.FlipVerticalButtonPushed);

            % Filters Tab
            app.FiltersTab = uitab(app.TabGroup, 'Title', 'Filters');
            app.FilterGaussianBlur = uicheckbox(app.FiltersTab, 'Text', 'Gaussian Blur', 'Position', [10 350 120 20]);
            app.FilterSharpen = uicheckbox(app.FiltersTab, 'Text', 'Sharpen', 'Position', [10 320 120 20]);
            app.FilterSobel = uicheckbox(app.FiltersTab, 'Text', 'Edge Detection (Sobel)', 'Position', [10 290 150 20]);
            app.FilterCanny = uicheckbox(app.FiltersTab, 'Text', 'Edge Detection (Canny)', 'Position', [10 260 150 20]);
            app.FilterEmboss = uicheckbox(app.FiltersTab, 'Text', 'Emboss', 'Position', [10 230 120 20]);
            app.FilterHistEq = uicheckbox(app.FiltersTab, 'Text', 'Auto Correction (histeq)', 'Position', [10 200 180 20]);
            app.FilterAdaptHist = uicheckbox(app.FiltersTab, 'Text', 'Adaptive Correction (adapthisteq)', 'Position', [10 170 200 20]);
            app.FilterNoiseReduction = uicheckbox(app.FiltersTab, 'Text', 'Noise Reduction', 'Position', [10 140 120 20]);
            app.ApplyFiltersButton = uibutton(app.FiltersTab, 'push', 'Text', 'Apply Selected Filters', 'Position', [10 20 150 30], 'BackgroundColor', [0.8 0.9 1], 'ButtonPushedFcn', @app.ApplyFiltersButtonPushed);

            % History Tab
            app.HistoryTab = uitab(app.TabGroup, 'Title', 'History');
            app.HistoryText = uitextarea(app.HistoryTab, 'Value', "", 'Position', [10 40 330 500], 'Editable', 'off');
            app.ExportLogButton = uibutton(app.HistoryTab, 'push', 'Text', 'Export Log', 'Position', [10 10 100 25], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.ExportLogButtonPushed);

            % % Curve RGB Tab
            % app.CurveTab = uitab(app.TabGroup, 'Title', 'Curve');
            % app.CurveAxes = uiaxes(app.CurveTab);
            % app.CurveAxes.Position = [40 180 270 350];
            % app.CurveAxes.ButtonDownFcn = @app.CurveAxesButtonDown;
            % app.CurveChannelLabel = uilabel(app.CurveTab, 'Text', 'Channel:', 'Position', [10 140 60 20]);
            % app.CurveChannelDropDown = uidropdown(app.CurveTab, 'Items', {'R', 'G', 'B', 'RGB'}, 'Value', 'RGB', 'Position', [70 140 80 20], 'ValueChangedFcn', @app.CurveChannelDropDownValueChanged);
            % app.AddPointButton = uibutton(app.CurveTab, 'push', 'Text', 'Add Point', 'Position', [160 140 80 25], 'BackgroundColor', [0.8 0.9 1], 'ButtonPushedFcn', @app.AddPointButtonPushed);
            % app.RemovePointButton = uibutton(app.CurveTab, 'push', 'Text', 'Remove Point', 'Position', [250 140 90 25], 'BackgroundColor', [1 0.8 0.8], 'ButtonPushedFcn', @app.RemovePointButtonPushed);
            % app.ResetCurveButton = uibutton(app.CurveTab, 'push', 'Text', 'Reset Curve', 'Position', [10 100 100 25], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.ResetCurveButtonPushed);

            % Info Tab
            app.InfoTab = uitab(app.TabGroup, 'Title', 'Info');
            app.ImageInfoText = uitextarea(app.InfoTab, 'Value', "", 'Position', [10 10 330 520], 'Editable', 'off');

        end

    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Mini_Photoshop()

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Stop the timer
            if isvalid(app.AdjustmentTimer)
                stop(app.AdjustmentTimer);
                delete(app.AdjustmentTimer);
            end

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end

        % % Value changed function: CurveChannelDropDown
        % function CurveChannelDropDownValueChanged(app, ~, ~)
        %     app.CurrentChannel = app.CurveChannelDropDown.Value;
        %     UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
        % end

        % % Button pushed function: AddPointButton
        % function AddPointButtonPushed(app, ~, ~)
        %     app.AddMode = true;
        %     app.RemoveMode = false;
        %     % Change button color to indicate mode
        %     app.AddPointButton.BackgroundColor = [0.5 0.9 0.5];
        %     app.RemovePointButton.BackgroundColor = [1 0.8 0.8];
        % end

        % % Button pushed function: RemovePointButton
        % function RemovePointButtonPushed(app, ~, ~)
        %     app.RemoveMode = true;
        %     app.AddMode = false;
        %     % Change button color to indicate mode
        %     app.RemovePointButton.BackgroundColor = [1 0.5 0.5];
        %     app.AddPointButton.BackgroundColor = [0.8 0.9 1];
        % end

        % % Button pushed function: ResetCurveButton
        % function ResetCurveButtonPushed(app, ~, ~)
        %     % Reset to diagonal
        %     app.CurvePointsR = [0 255; 0 255];
        %     app.CurvePointsG = [0 255; 0 255];
        %     app.CurvePointsB = [0 255; 0 255];
        %     UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
        %     % Apply changes immediately
        %     stop(app.AdjustmentTimer);
        %     app.applyAdjustments();
        % end

        % function CurveAxesButtonDown(app, ~, ~)
        %     if isempty(app.OriginalImage)
        %         return;
        %     end
        %     if app.AddMode
        %         % Get click position
        %         cp = app.CurveAxes.CurrentPoint;
        %         x = round(cp(1,1));
        %         y = round(cp(1,2));
        %         x = max(0, min(255, x));
        %         y = max(0, min(255, y));
        %         
        %         % Add point to current channel
        %         if strcmp(app.CurrentChannel, 'R') || strcmp(app.CurrentChannel, 'RGB')
        %             app.CurvePointsR = [app.CurvePointsR, [x; y]];
        %             [~, idx] = sort(app.CurvePointsR(1,:));
        %             app.CurvePointsR = app.CurvePointsR(:, idx);
        %         end
        %         if strcmp(app.CurrentChannel, 'G') || strcmp(app.CurrentChannel, 'RGB')
        %             app.CurvePointsG = [app.CurvePointsG, [x; y]];
        %             [~, idx] = sort(app.CurvePointsG(1,:));
        %             app.CurvePointsG = app.CurvePointsG(:, idx);
        %         end
        %         if strcmp(app.CurrentChannel, 'B') || strcmp(app.CurrentChannel, 'RGB')
        %             app.CurvePointsB = [app.CurvePointsB, [x; y]];
        %             [~, idx] = sort(app.CurvePointsB(1,:));
        %             app.CurvePointsB = app.CurvePointsB(:, idx);
        %         end
        %         UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
        %         % Apply changes
        %         stop(app.AdjustmentTimer);
        %         app.applyAdjustments();
        %         app.AddMode = false;
        %         app.AddPointButton.BackgroundColor = [0.8 0.9 1];
        %     elseif app.RemoveMode
        %         % Get click position
        %         cp = app.CurveAxes.CurrentPoint;
        %         x = round(cp(1,1));
        %         y = round(cp(1,2));
        %         
        %         % Find closest point in current channel and remove it
        %         minDist = inf;
        %         removeIdx = 0;
        %         if strcmp(app.CurrentChannel, 'R') || strcmp(app.CurrentChannel, 'RGB')
        %         for i = 1:size(app.CurvePointsR, 2)
        %             dist = sqrt((app.CurvePointsR(1,i) - x)^2 + (app.CurvePointsR(2,i) - y)^2);
        %             if dist < minDist && dist < 50  % Tolerance of 50 pixels
        %                 minDist = dist;
        %                 removeIdx = i;
        %             end
        %         end
        %         if removeIdx > 0 && size(app.CurvePointsR, 2) > 2  % Keep at least 2 points
        %             app.CurvePointsR(:, removeIdx) = [];
        %         end
        %     end
        %     if strcmp(app.CurrentChannel, 'G') || strcmp(app.CurrentChannel, 'RGB')
        %         minDist = inf;
        %         removeIdx = 0;
        %         for i = 1:size(app.CurvePointsG, 2)
        %             dist = sqrt((app.CurvePointsG(1,i) - x)^2 + (app.CurvePointsG(2,i) - y)^2);
        %             if dist < minDist && dist < 50
        %                 minDist = dist;
        %                 removeIdx = i;
        %             end
        %         end
        %         if removeIdx > 0 && size(app.CurvePointsG, 2) > 2
        %             app.CurvePointsG(:, removeIdx) = [];
        %         end
        %     end
        %     if strcmp(app.CurrentChannel, 'B') || strcmp(app.CurrentChannel, 'RGB')
        %         minDist = inf;
        %         removeIdx = 0;
        %         for i = 1:size(app.CurvePointsB, 2)
        %             dist = sqrt((app.CurvePointsB(1,i) - x)^2 + (app.CurvePointsB(2,i) - y)^2);
        %             if dist < minDist && dist < 50
        %                 minDist = dist;
        %                 removeIdx = i;
        %             end
        %         end
        %         if removeIdx > 0 && size(app.CurvePointsB, 2) > 2
        %             app.CurvePointsB(:, removeIdx) = [];
        %         end
        %     end
        %     UIManager.updateCurvePlots(app.CurveAxes, app.CurvePointsR, app.CurvePointsG, app.CurvePointsB, app.CurrentChannel);
        %     % Apply changes
        %     stop(app.AdjustmentTimer);
        %     app.applyAdjustments();
        %     app.RemoveMode = false;
        %     app.RemovePointButton.BackgroundColor = [1 0.8 0.8];
        % end
        % end

    end

end