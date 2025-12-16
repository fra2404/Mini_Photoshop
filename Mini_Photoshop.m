% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 16/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Main application class for the Mini Photoshop GUI. Handles user interface, event logic, and coordinates all image processing and history management.

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
        CurveAxes matlab.ui.control.UIAxes
        CurveChannelLabel matlab.ui.control.Label
        CurveChannelDropDown matlab.ui.control.DropDown
        AddPointButton matlab.ui.control.Button
        RemovePointButton matlab.ui.control.Button
        ResetCurveButton matlab.ui.control.Button
        FilterGaussianBlurImg matlab.ui.control.Image
        FilterGaussianBlurBtn matlab.ui.control.StateButton
        FilterSharpenImg matlab.ui.control.Image
        FilterSharpenBtn matlab.ui.control.StateButton
        FilterSobelImg matlab.ui.control.Image
        FilterSobelBtn matlab.ui.control.StateButton
        FilterCannyImg matlab.ui.control.Image
        FilterCannyBtn matlab.ui.control.StateButton
        FilterEmbossImg matlab.ui.control.Image
        FilterEmbossBtn matlab.ui.control.StateButton
        FilterHistEqImg matlab.ui.control.Image
        FilterHistEqBtn matlab.ui.control.StateButton
        FilterAdaptHistImg matlab.ui.control.Image
        FilterAdaptHistBtn matlab.ui.control.StateButton
        FilterNoiseReductionImg matlab.ui.control.Image
        FilterNoiseReductionBtn matlab.ui.control.StateButton
        ApplyFiltersButton matlab.ui.control.Button
    end

    properties (Access = private)
        OriginalImage
        CurrentImage
        HistoryManager
        CurveManager
        FilterManager
        CurrentBrightness
        CurrentContrast
        CurrentSaturation
        HasUnsavedChanges
        ShowingOriginal
        AdjustmentTimer  % timer for debouncing adjustments
        UseGPU  % flag to enable GPU acceleration
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.HistoryManager = HistoryManager();
            app.CurveManager = CurveManager();
            app.FilterManager = FilterManager();
            app.OriginalImage = [];
            app.CurrentImage = [];
            app.CurrentBrightness = 0;
            app.CurrentContrast = 0;
            app.CurrentSaturation = 0;
            app.HasUnsavedChanges = false;
            app.ShowingOriginal = false;
            app.UseGPU = canUseGPU();
            if app.UseGPU
                fprintf('GPU acceleration enabled\n');
            else
                fprintf('GPU not available, using CPU\n');
            end
            app.AdjustmentTimer = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.2, 'TimerFcn', @app.applyAdjustmentsWithLog);
            app.UIAxes.Visible = 'off';
            app.HistogramAxes.Visible = 'off';
            app.PlaceholderLabel.Visible = 'on';
            app.CurveAxes.ButtonDownFcn = @app.CurveAxesButtonDown;
            PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
        end

        function updateHistoryText(app)
            app.HistoryText.Value = strjoin(app.HistoryManager.HistoryLog, newline);
        end

        function applyAdjustments(app, ~, ~)
            if isempty(app.CurrentImage)
                return;
            end
            % Always apply from original image
            adjusted = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.UseGPU);
            
            % Apply selected filters on top of adjustments
            app.FilterManager.updateFromButtons(struct(...
                'GaussianBlur', app.FilterGaussianBlurBtn, ...
                'Sharpen', app.FilterSharpenBtn, ...
                'Sobel', app.FilterSobelBtn, ...
                'Canny', app.FilterCannyBtn, ...
                'Emboss', app.FilterEmbossBtn, ...
                'HistEq', app.FilterHistEqBtn, ...
                'AdaptHist', app.FilterAdaptHistBtn, ...
                'NoiseReduction', app.FilterNoiseReductionBtn));
            adjusted = app.FilterManager.applySelectedFilters(adjusted, app.UseGPU);
            
            cla(app.UIAxes);
            imshow(adjusted, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(adjusted, app.HistogramAxes);
            app.CurrentImage = adjusted;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB);
            app.HasUnsavedChanges = true;
            % Don't add to log here - will be added by specific action functions
        end

        function applyAdjustmentsWithLog(app, ~, ~)
            app.applyAdjustments();
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
            [img, fullpath] = ImageIOManager.loadImageDialog(app.UIFigure);
            if isempty(img)
                return;
            end
            app.OriginalImage = img;
            info = ImageIOManager.getImageInfo(fullpath);
            textLines = {};
            textLines{end+1} = sprintf('Format: %s', info.Format);
            textLines{end+1} = sprintf('Size: %dx%d pixels', info.Width, info.Height);
            if isfield(info, 'ColorType')
                textLines{end+1} = sprintf('Color type: %s', info.ColorType);
            end
            if isfield(info, 'BitDepth')
                textLines{end+1} = sprintf('Bit depth: %d', info.BitDepth);
            end
            if isfield(info, 'FileSize')
                textLines{end+1} = sprintf('File size: %.2f MB', info.FileSize / 1e6);
            end
            % Add EXIF info
            exifText = MetadataExtractor.extractExifInfo(info);
            if ~isempty(exifText)
                textLines{end+1} = 'Extracted EXIF info:';
                exifLines = splitlines(exifText);
                for i = 1:length(exifLines)
                    if ~isempty(strtrim(exifLines{i}))
                        textLines{end+1} = exifLines{i};
                    end
                end
            end
            app.ImageInfoText.Value = textLines;
            
            app.CurrentImage = app.OriginalImage;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.UIAxes.Visible = 'on';
            app.HistogramAxes.Visible = 'on';
            app.PlaceholderLabel.Visible = 'off';
            app.HasUnsavedChanges = false;
            app.ShowingOriginal = false;
            app.ShowOriginalButton.Text = 'Show Original';
            app.HistoryManager.addToHistoryLog('Image opened');
            app.updateHistoryText();
            app.updateFilterPreviews();
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded', 'Error');
                return;
            end
            success = ImageIOManager.saveImageDialog(app.UIFigure, app.CurrentImage);
            if success
                uialert(app.UIFigure, 'Image saved successfully', 'Confirm', 'Icon', 'success');
                app.HasUnsavedChanges = false;
                app.HistoryManager.addToHistoryLog('Image saved');
                app.updateHistoryText();
            end
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
            app.CurveManager.reset();
            app.BrightnessSlider.Value = 0;
            app.ContrastSlider.Value = 0;
            app.SaturationSlider.Value = 0;
            PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
            % Show original image
            cla(app.UIAxes);
            imshow(app.OriginalImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.OriginalImage, app.HistogramAxes);
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
                app.BrightnessSlider.Value = app.CurrentBrightness;
                app.ContrastSlider.Value = app.CurrentContrast;
                app.SaturationSlider.Value = app.CurrentSaturation;
                app.BrightnessField.Value = app.CurrentBrightness;
                app.ContrastField.Value = app.CurrentContrast;
                app.SaturationField.Value = app.CurrentSaturation;
                % Restore curve points
                if isfield(entry, 'pointsR')
                    app.CurveManager.CurvePointsR = entry.pointsR;
                    app.CurveManager.CurvePointsG = entry.pointsG;
                    app.CurveManager.CurvePointsB = entry.pointsB;
                    % Ensure correct orientation (2xN instead of Nx2)
                    if size(app.CurveManager.CurvePointsR, 1) > 2
                        app.CurveManager.CurvePointsR = app.CurveManager.CurvePointsR';
                    end
                    if size(app.CurveManager.CurvePointsG, 1) > 2
                        app.CurveManager.CurvePointsG = app.CurveManager.CurvePointsG';
                    end
                    if size(app.CurveManager.CurvePointsB, 1) > 2
                        app.CurveManager.CurvePointsB = app.CurveManager.CurvePointsB';
                    end
                    % Update curve plot if visible
                    if ~isempty(app.CurveAxes) && isvalid(app.CurveAxes)
                        PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
                    end
                end
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
                app.BrightnessSlider.Value = app.CurrentBrightness;
                app.ContrastSlider.Value = app.CurrentContrast;
                app.SaturationSlider.Value = app.CurrentSaturation;
                app.BrightnessField.Value = app.CurrentBrightness;
                app.ContrastField.Value = app.CurrentContrast;
                app.SaturationField.Value = app.CurrentSaturation;
                % Restore curve points
                if isfield(entry, 'pointsR')
                    app.CurveManager.CurvePointsR = entry.pointsR;
                    app.CurveManager.CurvePointsG = entry.pointsG;
                    app.CurveManager.CurvePointsB = entry.pointsB;
                    % Ensure correct orientation (2xN instead of Nx2)
                    if size(app.CurveManager.CurvePointsR, 1) > 2
                        app.CurveManager.CurvePointsR = app.CurveManager.CurvePointsR';
                    end
                    if size(app.CurveManager.CurvePointsG, 1) > 2
                        app.CurveManager.CurvePointsG = app.CurveManager.CurvePointsG';
                    end
                    if size(app.CurveManager.CurvePointsB, 1) > 2
                        app.CurveManager.CurvePointsB = app.CurveManager.CurvePointsB';
                    end
                    % Update curve plot if visible
                    if ~isempty(app.CurveAxes) && isvalid(app.CurveAxes)
                        PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
                    end
                end
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
                PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            else
                % Show the original image
                imshow(app.OriginalImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                app.ShowOriginalButton.Text = 'Show Modified';
                app.ShowingOriginal = true;
                PlotManager.updateHistogram(app.OriginalImage, app.HistogramAxes);
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
            isDefault = (app.CurrentBrightness == 0) && (app.CurrentContrast == 0) && (app.CurrentSaturation == 0) && app.CurveManager.isAtDefault();
            if isDefault
                % Apply immediately with log
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
                app.HistoryManager.addToHistoryLog('Reset to default adjustments');
                app.updateHistoryText();
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
            isDefault = (app.CurrentBrightness == 0) && (app.CurrentContrast == 0) && (app.CurrentSaturation == 0) && app.CurveManager.isAtDefault();
            if isDefault
                % Apply immediately with log
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
                app.HistoryManager.addToHistoryLog('Reset to default adjustments');
                app.updateHistoryText();
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
            isDefault = (app.CurrentBrightness == 0) && (app.CurrentContrast == 0) && (app.CurrentSaturation == 0) && app.CurveManager.isAtDefault();
            if isDefault
                % Apply immediately with log
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
                app.HistoryManager.addToHistoryLog('Reset to default adjustments');
                app.updateHistoryText();
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
            filtered = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.UseGPU);
            filtersApplied = {};
            if app.FilterGaussianBlurBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Gaussian Blur', app.UseGPU);
                filtersApplied{end+1} = 'Gaussian Blur';
            end
            if app.FilterSharpenBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Sharpen', app.UseGPU);
                filtersApplied{end+1} = 'Sharpen';
            end
            if app.FilterSobelBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Sobel)', app.UseGPU);
                filtersApplied{end+1} = 'Edge Detection (Sobel)';
            end
            if app.FilterCannyBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Canny)', app.UseGPU);
                filtersApplied{end+1} = 'Edge Detection (Canny)';
            end
            if app.FilterEmbossBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Emboss', app.UseGPU);
                filtersApplied{end+1} = 'Emboss';
            end
            if app.FilterHistEqBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Automatic correction (histeq)', app.UseGPU);
                filtersApplied{end+1} = 'Automatic correction (histeq)';
            end
            if app.FilterAdaptHistBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Adaptive correction (adapthisteq)', app.UseGPU);
                filtersApplied{end+1} = 'Adaptive correction (adapthisteq)';
            end
            if app.FilterNoiseReductionBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Noise reduction', app.UseGPU);
                filtersApplied{end+1} = 'Noise reduction';
            end
            if isempty(filtersApplied)
                % Reset to original image with current adjustments applied
                app.CurrentImage = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.UseGPU);
                app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB);
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
                app.HasUnsavedChanges = true;
                app.HistoryManager.addToHistoryLog('Filters reset');
                app.updateHistoryText();
                return;
            end
            app.CurrentImage = filtered;
            app.updateFilterPreviews();  % Update filter previews with new base image
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
            app.updateFilterPreviews();  % Update filter previews with new base image
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
            app.updateFilterPreviews();  % Update filter previews with new base image
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
            app.updateFilterPreviews();  % Update filter previews with new base image
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
            app.updateFilterPreviews();  % Update filter previews with new base image
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
            app.updateFilterPreviews();  % Update filter previews with new base image
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
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
                app.updateFilterPreviews();  % Update filter previews with new base image
                app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
                app.HasUnsavedChanges = true;
                app.HistoryManager.addToHistoryLog(sprintf('Crop applied: %dx%d', width, height));
                app.updateHistoryText();
            end
        end

    end

    % Helper functions
    methods (Access = private)

        function updateFilterPreviews(app)
            if isempty(app.OriginalImage)
                return;
            end
            % Generate thumbnails for each filter
            img = imresize(app.OriginalImage, [50 50]);
            if size(img, 3) == 1
                img = repmat(img, [1 1 3]);
            end
            
            % Gaussian Blur
            filtered = ImageFilter.applyFilter(img, 'Gaussian Blur', false);
            app.FilterGaussianBlurImg.ImageSource = filtered;
            
            % Sharpen
            filtered = ImageFilter.applyFilter(img, 'Sharpen', false);
            app.FilterSharpenImg.ImageSource = filtered;
            
            % Sobel
            if size(img, 3) == 3
                gray = rgb2gray(img);
            else
                gray = img;
            end
            edges = edge(gray, 'sobel');
            filtered = uint8(repmat(edges * 255, [1 1 3]));
            app.FilterSobelImg.ImageSource = filtered;
            
            % Canny
            edges = edge(gray, 'canny');
            filtered = uint8(repmat(edges * 255, [1 1 3]));
            app.FilterCannyImg.ImageSource = filtered;
            
            % Emboss
            filtered = ImageFilter.applyFilter(img, 'Emboss', false);
            app.FilterEmbossImg.ImageSource = filtered;
            
            % Hist Eq
            filtered = ImageFilter.applyFilter(img, 'Automatic correction (histeq)', false);
            app.FilterHistEqImg.ImageSource = filtered;
            
            % Adapt Hist
            filtered = ImageFilter.applyFilter(img, 'Adaptive correction (adapthisteq)', false);
            app.FilterAdaptHistImg.ImageSource = filtered;
            
            % Noise Reduction
            filtered = ImageFilter.applyFilter(img, 'Noise reduction', false);
            app.FilterNoiseReductionImg.ImageSource = filtered;
        end

        function updateButtonColor(~, btn)
            if btn.Value
                btn.BackgroundColor = [0.5 0.9 0.5]; % Green when selected
            else
                btn.BackgroundColor = [0.8 0.8 0.8]; % Gray when not
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
            axis(app.UIAxes, 'tight');
            app.UIAxes.XColor = 'none';
            app.UIAxes.YColor = 'none';

            % Create HistogramAxes
            app.HistogramAxes = uiaxes(app.UIFigure);
            app.HistogramAxes.Position = [100 500 600 120];
            app.HistogramAxes.Visible = 'off';

            % Create PlaceholderLabel
            app.PlaceholderLabel = uilabel(app.UIFigure, 'Text', 'Load an image to start', 'Position', [150 300 400 80], 'HorizontalAlignment', 'center', 'FontSize', 18, 'FontWeight', 'bold');



            % Menu bar (enhanced)
            % File Menu
            fileMenu = uimenu(app.UIFigure, 'Text', 'File');
            uimenu(fileMenu, 'Text', 'Open Image...', 'Accelerator', 'O', 'MenuSelectedFcn', @(src, event) app.OpenButtonPushed());
            uimenu(fileMenu, 'Text', 'Save Image...', 'Accelerator', 'S', 'MenuSelectedFcn', @(src, event) app.SaveButtonPushed());
            uimenu(fileMenu, 'Separator', 'on', 'Text', 'Exit', 'Accelerator', 'Q', 'MenuSelectedFcn', @(src, event) close(app.UIFigure));

            % Edit Menu
            editMenu = uimenu(app.UIFigure, 'Text', 'Edit');
            uimenu(editMenu, 'Text', 'Reset', 'Accelerator', 'R', 'MenuSelectedFcn', @(src, event) app.ResetButtonPushed());
            uimenu(editMenu, 'Text', 'Undo', 'Accelerator', 'Z', 'MenuSelectedFcn', @(src, event) app.UndoButtonPushed());
            uimenu(editMenu, 'Text', 'Redo', 'Accelerator', 'Y', 'MenuSelectedFcn', @(src, event) app.RedoButtonPushed());

            % Toolbar buttons 
            app.ResetButton = uibutton(app.UIFigure, 'push', 'Text', 'Reset', 'Position', [10 650 100 30], 'BackgroundColor', [1 0.8 0.8], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.ResetButtonPushed);
            app.UndoButton = uibutton(app.UIFigure, 'push', 'Text', 'Undo', 'Position', [120 650 100 30], 'BackgroundColor', [0.9 0.9 0.9], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.UndoButtonPushed);
            app.RedoButton = uibutton(app.UIFigure, 'push', 'Text', 'Redo', 'Position', [230 650 100 30], 'BackgroundColor', [0.9 0.9 0.9], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.RedoButtonPushed);
            app.ShowOriginalButton = uibutton(app.UIFigure, 'push', 'Text', 'Show Original', 'Position', [340 650 120 30], 'BackgroundColor', [1 1 0.8], 'FontWeight', 'bold', 'ButtonPushedFcn', @app.ShowOriginalButtonPushed);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure, 'Position', [750 60 350 580]);

            % Adjustments Tab with scrollable panel
            app.AdjustmentsTab = uitab(app.TabGroup, 'Title', 'Adjustments');
            
            % Create scrollable panel
            scrollPanel = uipanel(app.AdjustmentsTab, 'Position', [0 0 350 580], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            
            % Start yPos higher than panel height to ensure scroll is enabled
            marginTop = 100;
            yPos = marginTop;
            
            % === SECTION 1: BASIC ADJUSTMENTS ===
            yOffset = 1000;
            topMargin = -60;
            uilabel(scrollPanel, 'Text', 'BASIC ADJUSTMENTS', 'Position', [20 yOffset-yPos-50 310 25], 'FontWeight', 'bold', 'FontSize', 12, 'HorizontalAlignment', 'center', 'BackgroundColor', [0.95 0.95 0.95]);
            uilabel(scrollPanel, 'Text', 'BASIC ADJUSTMENTS', 'Position', [20 yOffset-yPos 310 25], 'FontWeight', 'bold', 'FontSize', 12, 'HorizontalAlignment', 'center', 'BackgroundColor', [0.95 0.95 0.95]);
            yPos = yPos + 50;
            
            % Brightness
            app.BrightnessLabel = uilabel(scrollPanel, 'Text', 'Brightness', 'Position', [30 yOffset-yPos-30 80 20], 'FontWeight', 'bold');
            app.BrightnessSlider = uislider(scrollPanel, 'Limits', [-100 100], 'Value', 0, 'Position', [120 yOffset-yPos-25 150 3], 'ValueChangedFcn', @app.BrightnessSliderValueChanged);
            app.BrightnessField = uieditfield(scrollPanel, 'numeric', 'Limits', [-100 100], 'Value', 0, 'Position', [280 yOffset-yPos-30 50 20], 'ValueChangedFcn', @app.BrightnessFieldValueChanged);
            yPos = yPos + 50;
            
            % Contrast
            app.ContrastLabel = uilabel(scrollPanel, 'Text', 'Contrast', 'Position', [30 yOffset-yPos-30 80 20], 'FontWeight', 'bold');
            app.ContrastSlider = uislider(scrollPanel, 'Limits', [-100 100], 'Value', 0, 'Position', [120 yOffset-yPos-25 150 3], 'ValueChangedFcn', @app.ContrastSliderValueChanged);
            app.ContrastField = uieditfield(scrollPanel, 'numeric', 'Limits', [-100 100], 'Value', 0, 'Position', [280 yOffset-yPos-30 50 20], 'ValueChangedFcn', @app.ContrastFieldValueChanged);
            yPos = yPos + 50;
            
            % Saturation
            app.SaturationLabel = uilabel(scrollPanel, 'Text', 'Saturation', 'Position', [30 yOffset-yPos-30 80 20], 'FontWeight', 'bold');
            app.SaturationSlider = uislider(scrollPanel, 'Limits', [-100 100], 'Value', 0, 'Position', [120 yOffset-yPos-25 150 3], 'ValueChangedFcn', @app.SaturationSliderValueChanged);
            app.SaturationField = uieditfield(scrollPanel, 'numeric', 'Limits', [-100 100], 'Value', 0, 'Position', [280 yOffset-yPos-30 50 20], 'ValueChangedFcn', @app.SaturationFieldValueChanged);
            yPos = yPos + 50;
            
            % Separator line
            uilabel(scrollPanel, 'Text', '', 'Position', [20 yOffset-yPos-10 310 2], 'BackgroundColor', [0.7 0.7 0.7]);
            yPos = yPos + 30;
            
            % === SECTION 2: RGB CURVES ===
            uilabel(scrollPanel, 'Text', 'RGB CURVES', 'Position', [20 yOffset-yPos-30 310 25], 'FontWeight', 'bold', 'FontSize', 12, 'HorizontalAlignment', 'center', 'BackgroundColor', [0.95 0.95 0.95]);
            yPos = yPos + 40;
            
            % Curve axes
            app.CurveAxes = uiaxes(scrollPanel);
            app.CurveAxes.Position = [40 yOffset-yPos-350 270 350];
            app.CurveAxes.ButtonDownFcn = @app.CurveAxesButtonDown;
            yPos = yPos + 360;
            
            % Curve controls
            app.CurveChannelLabel = uilabel(scrollPanel, 'Text', 'Channel:', 'Position', [10 yOffset-yPos-25 60 20]);
            app.CurveChannelDropDown = uidropdown(scrollPanel, 'Items', {'R', 'G', 'B', 'RGB'}, 'Value', 'RGB', 'Position', [70 yOffset-yPos-25 80 20], 'ValueChangedFcn', @app.CurveChannelDropDownValueChanged);
            app.AddPointButton = uibutton(scrollPanel, 'push', 'Text', 'Add Point', 'Position', [160 yOffset-yPos-25 80 25], 'BackgroundColor', [0.8 0.9 1], 'ButtonPushedFcn', @app.AddPointButtonPushed);
            app.RemovePointButton = uibutton(scrollPanel, 'push', 'Text', 'Remove Point', 'Position', [250 yOffset-yPos-25 90 25], 'BackgroundColor', [1 0.8 0.8], 'ButtonPushedFcn', @app.RemovePointButtonPushed);
            yPos = yPos + 35;
            
            app.ResetCurveButton = uibutton(scrollPanel, 'push', 'Text', 'Reset Curves', 'Position', [10 yOffset-yPos-25 100 25], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.ResetCurveButtonPushed);
            yPos = yPos + 40;
            
            % Separator line
            uilabel(scrollPanel, 'Text', '', 'Position', [20 yOffset-yPos-10 310 2], 'BackgroundColor', [0.7 0.7 0.7]);
            yPos = yPos + 30;
            
            % === SECTION 3: TRANSFORMATIONS ===
            uilabel(scrollPanel, 'Text', 'TRANSFORMATIONS', 'Position', [20 yOffset-yPos-30 310 25], 'FontWeight', 'bold', 'FontSize', 12, 'HorizontalAlignment', 'center', 'BackgroundColor', [0.95 0.95 0.95]);
            yPos = yPos + 40;
            
            % Rotation buttons
            app.Rotate90Button = uibutton(scrollPanel, 'push', 'Text', 'Rotate 90°', 'Position', [40 yOffset-yPos-35 90 30], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.Rotate90ButtonPushed);
            app.Rotate180Button = uibutton(scrollPanel, 'push', 'Text', 'Rotate 180°', 'Position', [140 yOffset-yPos-35 90 30], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.Rotate180ButtonPushed);
            app.Rotate270Button = uibutton(scrollPanel, 'push', 'Text', 'Rotate 270°', 'Position', [240 yOffset-yPos-35 90 30], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.Rotate270ButtonPushed);
            yPos = yPos + 45;
            
            % Flip buttons
            app.FlipHorizontalButton = uibutton(scrollPanel, 'push', 'Text', 'Flip H.', 'Position', [40 yOffset-yPos-35 90 30], 'BackgroundColor', [1 0.95 0.9], 'ButtonPushedFcn', @app.FlipHorizontalButtonPushed);
            app.FlipVerticalButton = uibutton(scrollPanel, 'push', 'Text', 'Flip V.', 'Position', [140 yOffset-yPos-35 90 30], 'BackgroundColor', [1 0.95 0.9], 'ButtonPushedFcn', @app.FlipVerticalButtonPushed);
            yPos = yPos + 60;

            % Add invisible spacer to control scroll height
            uilabel(scrollPanel, 'Text', '', 'Position', [0 yOffset-yPos-40 1 1], 'Visible', 'off');

            % Filters Tab
            app.FiltersTab = uitab(app.TabGroup, 'Title', 'Filters');
            
            % 4x2 
            tabW = 350; tabH = 580;
            nRows = 4; nCols = 2;
            imgW = 80; imgH = 60; labelH = 16; btnH = 18;
            gridW = nCols*imgW;
            gridH = nRows*(imgH+btnH+labelH);
            padX = (tabW-gridW)/(nCols+1);
            padY = ((tabH-60)-gridH)/(nRows+1);
            padY = padY + 4; 
            startX = padX;
            startY = tabH - padY - imgH;
            yStep = imgH + btnH + labelH + padY;
            xStep = imgW + padX;

            % Row 1
            app.FilterGaussianBlurImg = uiimage(app.FiltersTab, 'Position', [startX startY imgW imgH]);
            app.FilterSharpenImg = uiimage(app.FiltersTab, 'Position', [startX+xStep startY imgW imgH]);
            app.FilterGaussianBlurBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX startY-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            app.FilterSharpenBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX+xStep startY-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            uilabel(app.FiltersTab, 'Text', 'Blur', 'Position', [startX startY-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);
            uilabel(app.FiltersTab, 'Text', 'Sharpen', 'Position', [startX+xStep startY-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);

            % Row 2
            app.FilterSobelImg = uiimage(app.FiltersTab, 'Position', [startX startY-yStep imgW imgH]);
            app.FilterCannyImg = uiimage(app.FiltersTab, 'Position', [startX+xStep startY-yStep imgW imgH]);
            app.FilterSobelBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX startY-yStep-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            app.FilterCannyBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX+xStep startY-yStep-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            uilabel(app.FiltersTab, 'Text', 'Edges', 'Position', [startX startY-yStep-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);
            uilabel(app.FiltersTab, 'Text', 'Canny', 'Position', [startX+xStep startY-yStep-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);

            % Row 3
            app.FilterEmbossImg = uiimage(app.FiltersTab, 'Position', [startX startY-2*yStep imgW imgH]);
            app.FilterHistEqImg = uiimage(app.FiltersTab, 'Position', [startX+xStep startY-2*yStep imgW imgH]);
            app.FilterEmbossBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX startY-2*yStep-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            app.FilterHistEqBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX+xStep startY-2*yStep-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            uilabel(app.FiltersTab, 'Text', 'Emboss', 'Position', [startX startY-2*yStep-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);
            uilabel(app.FiltersTab, 'Text', 'Hist Eq', 'Position', [startX+xStep startY-2*yStep-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);

            % Row 4
            app.FilterAdaptHistImg = uiimage(app.FiltersTab, 'Position', [startX startY-3*yStep imgW imgH]);
            app.FilterNoiseReductionImg = uiimage(app.FiltersTab, 'Position', [startX+xStep startY-3*yStep imgW imgH]);
            app.FilterAdaptHistBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX startY-3*yStep-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            app.FilterNoiseReductionBtn = uibutton(app.FiltersTab, 'state', 'Text', '', 'Position', [startX+xStep startY-3*yStep-btnH-5 imgW btnH], 'BackgroundColor', [0.8 0.8 0.8], 'ValueChangedFcn', @(btn, event) app.updateButtonColor(btn));
            uilabel(app.FiltersTab, 'Text', 'Adapt Hist', 'Position', [startX startY-3*yStep-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);
            uilabel(app.FiltersTab, 'Text', 'Noise Red', 'Position', [startX+xStep startY-3*yStep-btnH-labelH-10 imgW labelH], 'HorizontalAlignment', 'center', 'FontSize', 11);

            lastRowY = startY-3*yStep;
            applyBtnY = lastRowY-btnH-labelH-padY-18;
            app.ApplyFiltersButton = uibutton(app.FiltersTab, 'push', 'Text', 'Apply Selected Filters', 'Position', [round((tabW-170)/2) applyBtnY 170 24], 'BackgroundColor', [0.8 0.9 1], 'ButtonPushedFcn', @app.ApplyFiltersButtonPushed);

            % Info Tab
            app.InfoTab = uitab(app.TabGroup, 'Title', 'Info');
            app.ImageInfoText = uitextarea(app.InfoTab, 'Value', "", 'Position', [10 10 330 520], 'Editable', 'off');

            % History Tab
            app.HistoryTab = uitab(app.TabGroup, 'Title', 'History');
            app.HistoryText = uitextarea(app.HistoryTab, 'Value', "", 'Position', [10 40 330 500], 'Editable', 'off');
            app.ExportLogButton = uibutton(app.HistoryTab, 'push', 'Text', 'Export Log', 'Position', [10 10 100 25], 'BackgroundColor', [0.9 0.95 1], 'ButtonPushedFcn', @app.ExportLogButtonPushed);

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

        % Value changed function: CurveChannelDropDown
        function CurveChannelDropDownValueChanged(app, ~, ~)
            app.CurveManager.setChannel(app.CurveChannelDropDown.Value);
            PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
        end

        % Button pushed function: AddPointButton
        function AddPointButtonPushed(app, ~, ~)
            app.CurveManager.enableAddMode();
            app.AddPointButton.BackgroundColor = [0.2 0.8 0.2];  % Verde brillante
            app.AddPointButton.FontWeight = 'bold';
            app.RemovePointButton.BackgroundColor = [0.96 0.96 0.96];  % Grigio chiaro
            app.RemovePointButton.FontWeight = 'normal';
        end

        % Button pushed function: RemovePointButton
        function RemovePointButtonPushed(app, ~, ~)
            app.CurveManager.enableRemoveMode();
            app.RemovePointButton.BackgroundColor = [0.9 0.2 0.2];  % Rosso brillante
            app.RemovePointButton.FontWeight = 'bold';
            app.AddPointButton.BackgroundColor = [0.96 0.96 0.96];  % Grigio chiaro
            app.AddPointButton.FontWeight = 'normal';
        end

        % Button pushed function: ResetCurveButton
        function ResetCurveButtonPushed(app, ~, ~)
            if isempty(app.CurrentImage)
                return;
            end
            app.CurveManager.reset();
            PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
            stop(app.AdjustmentTimer);
            app.applyAdjustments();
            app.HistoryManager.addToHistoryLog('Curves reset');
            app.updateHistoryText();
        end

        % Mouse click on curve axes
        function CurveAxesButtonDown(app, ~, event)
            if isempty(app.CurrentImage)
                return;
            end
            
            coords = event.IntersectionPoint;
            x = round(coords(1));
            y = round(coords(2));
            
            if app.CurveManager.AddMode
                app.CurveManager.addPoint(x, y);
                PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
                drawnow;
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
                app.CurveManager.disableModes();
                app.AddPointButton.BackgroundColor = [0.96 0.96 0.96];
                app.AddPointButton.FontWeight = 'normal';
                switch app.CurveManager.CurrentChannel
                    case 'RGB'
                        channelStr = 'RGB';
                    case 'R'
                        channelStr = 'Red';
                    case 'G'
                        channelStr = 'Green';
                    case 'B'
                        channelStr = 'Blue';
                    otherwise
                        channelStr = 'RGB';
                end
                app.HistoryManager.addToHistoryLog(sprintf('%s curve point added at (%d, %d)', channelStr, x, y));
                app.updateHistoryText();
            elseif app.CurveManager.RemoveMode
                app.CurveManager.removePoint(x, y);
                PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
                drawnow;
                stop(app.AdjustmentTimer);
                app.applyAdjustments();
                app.CurveManager.disableModes();
                app.RemovePointButton.BackgroundColor = [0.96 0.96 0.96];
                app.RemovePointButton.FontWeight = 'normal';
                switch app.CurveManager.CurrentChannel
                    case 'RGB'
                        channelStr = 'RGB';
                    case 'R'
                        channelStr = 'Red';
                    case 'G'
                        channelStr = 'Green';
                    case 'B'
                        channelStr = 'Blue';
                    otherwise
                        channelStr = 'RGB';
                end
                app.HistoryManager.addToHistoryLog(sprintf('%s curve point removed', channelStr));
                app.updateHistoryText();
            end
        end

    end

end