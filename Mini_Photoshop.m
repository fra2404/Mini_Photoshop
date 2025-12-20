% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 20/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Main application class for the Mini Photoshop GUI. Handles user interface, event logic, and coordinates all image processing and history management.

classdef Mini_Photoshop < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure matlab.ui.Figure
        UIAxes matlab.ui.control.UIAxes
        HistogramAxes matlab.ui.control.UIAxes
        PlaceholderLabel matlab.ui.control.Image
        OpenButton matlab.ui.control.Button
        SaveButton matlab.ui.control.Button
        ResetButton matlab.ui.control.Button
        UndoButton matlab.ui.control.Button
        RedoButton matlab.ui.control.Button
        ShowOriginalButton matlab.ui.control.Button
        BrightnessLabel matlab.ui.control.Label
        BrightnessSlider matlab.ui.control.Slider
        BrightnessField matlab.ui.control.NumericEditField
        ContrastLabel matlab.ui.control.Label
        ContrastSlider matlab.ui.control.Slider
        ContrastField matlab.ui.control.NumericEditField
        SaturationLabel matlab.ui.control.Label
        SaturationSlider matlab.ui.control.Slider
        SaturationField matlab.ui.control.NumericEditField
        ImageInfoText matlab.ui.control.TextArea
        Rotate90Button matlab.ui.control.Button
        Rotate180Button matlab.ui.control.Button
        Rotate270Button matlab.ui.control.Button
        FlipHorizontalButton matlab.ui.control.Button
        FlipVerticalButton matlab.ui.control.Button

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
        LoadingLabel matlab.ui.control.Label
        RightPanel matlab.ui.container.Panel
        BaseRightPanelWidth double
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
        HistoryFigure  % handle to the history window figure
        HistoryTextArea  % handle to the text area in history window
    end

    % Callbacks that handle component events
    methods (Access = public)

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
            app.HistoryFigure = [];
            app.HistoryTextArea = [];
            app.AdjustmentTimer = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.2, 'TimerFcn', @app.applyAdjustmentsWithLog);
            app.UIAxes.Visible = 'off';
            app.HistogramAxes.Visible = 'off';
            app.PlaceholderLabel.Visible = 'on';
            app.CurveAxes.ButtonDownFcn = @app.CurveAxesButtonDown;
            PlotManager.updateCurvePlots(app.CurveAxes, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB, app.CurveManager.CurrentChannel);
        end

        function updateHistoryText(app)
            app.HistoryText.Value = strjoin(app.HistoryManager.HistoryLog, newline);
            if ~isempty(app.HistoryFigure) && isvalid(app.HistoryFigure) && ~isempty(app.HistoryTextArea) && isvalid(app.HistoryTextArea)
                app.HistoryTextArea.Value = app.HistoryManager.HistoryLog;
            end
        end

        function applyAdjustments(app, ~, ~)
            if isempty(app.CurrentImage)
                return;
            end
            % Always apply from original image
            adjusted = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB);
            
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
            adjusted = app.FilterManager.applySelectedFilters(adjusted);
            
            cla(app.UIAxes);
            imshow(adjusted, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(adjusted, app.HistogramAxes);
            app.CurrentImage = adjusted;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB);
            app.HasUnsavedChanges = true;
        end

        function applyAdjustmentsWithLog(app, ~, ~)
            app.LoadingLabel.Visible = 'on';
            drawnow;
            app.applyAdjustments();
            app.HistoryManager.addToHistoryLog(sprintf('Adjustments: B=%.1f, C=%.1f, S=%.1f', app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation));
            app.updateHistoryText();
            app.LoadingLabel.Visible = 'off';
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
            % Convert cell array to string array for uitextarea
            if iscell(textLines)
                app.ImageInfoText.Value = textLines;
            else
                app.ImageInfoText.Value = {textLines};
            end
            
            app.CurrentImage = app.OriginalImage;
            app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, [], [], []);
            cla(app.UIAxes);
            imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
            PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
            app.UIAxes.Visible = 'on';
            app.HistogramAxes.Visible = 'on';
            app.PlaceholderLabel.Visible = 'off';
            app.OpenButton.Visible = 'off';
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
            app.LoadingLabel.Visible = 'on';
            drawnow;
            filtered = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB);
            filtersApplied = {};
            if app.FilterGaussianBlurBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Gaussian Blur');
                filtersApplied{end+1} = 'Gaussian Blur';
            end
            if app.FilterSharpenBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Sharpen');
                filtersApplied{end+1} = 'Sharpen';
            end
            if app.FilterSobelBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Sobel)');
                filtersApplied{end+1} = 'Edge Detection (Sobel)';
            end
            if app.FilterCannyBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Edge Detection (Canny)');
                filtersApplied{end+1} = 'Edge Detection (Canny)';
            end
            if app.FilterEmbossBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Emboss');
                filtersApplied{end+1} = 'Emboss';
            end
            if app.FilterHistEqBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Automatic correction (histeq)');
                filtersApplied{end+1} = 'Automatic correction (histeq)';
            end
            if app.FilterAdaptHistBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Adaptive correction (adapthisteq)');
                filtersApplied{end+1} = 'Adaptive correction (adapthisteq)';
            end
            if app.FilterNoiseReductionBtn.Value
                filtered = ImageFilter.applyFilter(filtered, 'Noise reduction');
                filtersApplied{end+1} = 'Noise reduction';
            end
            if isempty(filtersApplied)
                % Reset to original image with current adjustments applied
                app.CurrentImage = ImageAdjuster.applyAllAdjustments(app.OriginalImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB);
                app.HistoryManager.pushToHistory(app.CurrentImage, app.CurrentBrightness, app.CurrentContrast, app.CurrentSaturation, app.CurveManager.CurvePointsR, app.CurveManager.CurvePointsG, app.CurveManager.CurvePointsB);
                cla(app.UIAxes);
                imshow(app.CurrentImage, 'Parent', app.UIAxes, 'InitialMagnification', 'fit');
                PlotManager.updateHistogram(app.CurrentImage, app.HistogramAxes);
                app.HasUnsavedChanges = true;
                app.HistoryManager.addToHistoryLog('Filters reset');
                app.updateHistoryText();
                app.LoadingLabel.Visible = 'off';
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
            app.LoadingLabel.Visible = 'off';
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
            app.LoadingLabel.Visible = 'on';
            drawnow;
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
            app.LoadingLabel.Visible = 'off';
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
            app.LoadingLabel.Visible = 'on';
            drawnow;
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
            app.LoadingLabel.Visible = 'off';
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
            app.LoadingLabel.Visible = 'on';
            drawnow;
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
            app.LoadingLabel.Visible = 'off';
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
            app.LoadingLabel.Visible = 'on';
            drawnow;
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
            app.LoadingLabel.Visible = 'off';
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
            app.LoadingLabel.Visible = 'on';
            drawnow;
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
            app.LoadingLabel.Visible = 'off';
        end

        % Show Photo Info Window
        function ShowPhotoInfoWindow(app)
            WindowManager.ShowPhotoInfo(app.UIFigure, app.ImageInfoText.Value, app.OriginalImage);
        end

        % Show Modification History Window
        function ShowModificationHistoryWindow(app)
            if isempty(app.HistoryManager.HistoryLog)
                uialert(app.UIFigure, 'No modifications yet', 'Info', 'Icon', 'info');
                return;
            end
            
            if ~isempty(app.HistoryFigure) && isvalid(app.HistoryFigure)
                % Bring to front and update
                figure(app.HistoryFigure);
                app.HistoryTextArea.Value = app.HistoryManager.HistoryLog;
                return;
            end
            
            % Create new history window
            app.HistoryFigure = uifigure('Name', 'Modification History', 'Position', [200 200 500 400], 'Resize', 'off', 'DeleteFcn', @app.onHistoryFigureDelete);
            
            % Text area with history
            app.HistoryTextArea = uitextarea(app.HistoryFigure, 'Position', [10 50 480 340], 'Editable', 'off', 'FontSize', 10);
            app.HistoryTextArea.Value = app.HistoryManager.HistoryLog;
            
            % Export button
            uibutton(app.HistoryFigure, 'push', 'Text', '📄 Export Log', ...
                'Position', [10 10 120 30], 'ButtonPushedFcn', @app.exportHistory);
        end
        
        function onHistoryFigureDelete(app, ~, ~)
            app.HistoryFigure = [];
            app.HistoryTextArea = [];
        end
        
        function exportHistory(app, ~, ~)
            [file, path] = uiputfile('*.txt', 'Export modifications log');
            if isequal(file, 0)
                return;
            end
            fullpath = fullfile(path, file);
            fid = fopen(fullpath, 'w');
            for i = 1:length(app.HistoryManager.HistoryLog)
                fprintf(fid, '%s\n', app.HistoryManager.HistoryLog{i});
            end
            fclose(fid);
            uialert(app.HistoryFigure, 'Log exported successfully', 'Success', 'Icon', 'success');
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
            if ~isempty(app.HistoryFigure) && isvalid(app.HistoryFigure)
                delete(app.HistoryFigure);
            end
            delete(app.UIFigure);
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
            filtered = ImageFilter.applyFilter(img, 'Gaussian Blur');
            app.FilterGaussianBlurImg.ImageSource = filtered;
            
            % Sharpen
            filtered = ImageFilter.applyFilter(img, 'Sharpen');
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
            filtered = ImageFilter.applyFilter(img, 'Emboss');
            app.FilterEmbossImg.ImageSource = filtered;
            
            % Hist Eq
            filtered = ImageFilter.applyFilter(img, 'Automatic correction (histeq)');
            app.FilterHistEqImg.ImageSource = filtered;
            
            % Adapt Hist
            filtered = ImageFilter.applyFilter(img, 'Adaptive correction (adapthisteq)');
            app.FilterAdaptHistImg.ImageSource = filtered;
            
            % Noise Reduction
            filtered = ImageFilter.applyFilter(img, 'Noise reduction');
            app.FilterNoiseReductionImg.ImageSource = filtered;
        end

        % SizeChanged callback: RightPanel - scales content width dynamically
        function RightPanelSizeChanged(app, ~, ~)
            if isempty(app.RightPanel) || ~isvalid(app.RightPanel)
                return;
            end
            
            % Calculate scaling factor based on panel width
            currentWidth = app.RightPanel.InnerPosition(3);
            scale = currentWidth / app.BaseRightPanelWidth;
            
            % Only scale if change is significant (avoid micro-adjustments)
            if abs(scale - 1.0) < 0.01
                return;
            end
            
            % Scale all children's X position and width (keep Y/Height for vertical scroll)
            children = app.RightPanel.Children;
            for i = 1:length(children)
                child = children(i);
                if isprop(child, 'Position')
                    pos = child.Position;
                    % Scale X and Width
                    pos(1) = round((pos(1) / app.BaseRightPanelWidth) * currentWidth);
                    pos(3) = round((pos(3) / app.BaseRightPanelWidth) * currentWidth);
                    child.Position = pos;
                end
            end
            
            % Update base width to current to avoid cumulative errors
            app.BaseRightPanelWidth = currentWidth;
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            UIManager.createMainUI(app);
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
            if ~isempty(app.AdjustmentTimer) && isa(app.AdjustmentTimer, 'timer') && isvalid(app.AdjustmentTimer)
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
            app.AddPointButton.BackgroundColor = [0.2 0.8 0.2]; 
            app.AddPointButton.FontWeight = 'bold';
            app.RemovePointButton.BackgroundColor = [0.96 0.96 0.96]; 
            app.RemovePointButton.FontWeight = 'normal';
        end

        % Button pushed function: RemovePointButton
        function RemovePointButtonPushed(app, ~, ~)
            app.CurveManager.enableRemoveMode();
            app.RemovePointButton.BackgroundColor = [0.9 0.2 0.2];
            app.RemovePointButton.FontWeight = 'bold';
            app.AddPointButton.BackgroundColor = [0.96 0.96 0.96]; 
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
                app.LoadingLabel.Visible = 'on';
                drawnow;
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
                app.LoadingLabel.Visible = 'off';
            elseif app.CurveManager.RemoveMode
                app.LoadingLabel.Visible = 'on';
                drawnow;
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
                app.LoadingLabel.Visible = 'off';
            end
        end

    end

end