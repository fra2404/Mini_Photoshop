% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 20/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Manages additional windows (Photo Info, Modification History) for the Mini Photoshop application.

classdef WindowManager
    
    methods (Static)
        
        % Show Photo Info Window
        function ShowPhotoInfo(parentFigure, imageInfoText, originalImage)
            if isempty(originalImage)
                uialert(parentFigure, 'No image loaded', 'Info', 'Icon', 'warning');
                return;
            end
            
            % Create small info window
            infoFig = uifigure('Name', 'Photo Info', 'Position', [200 200 450 350], 'Resize', 'off');
            infoFig.CloseRequestFcn = @closeFig;
            
            % Text area with info
            infoText = uitextarea(infoFig, 'Position', [10 10 430 330], 'Editable', 'off', 'FontSize', 11);
            infoText.Value = imageInfoText;
            
            function closeFig(~,~)
                delete(infoFig);
            end
        end
        
        % Show Modification History Window
        function ShowModificationHistory(parentFigure, historyLog)
            if isempty(historyLog)
                uialert(parentFigure, 'No modifications yet', 'Info', 'Icon', 'info');
                return;
            end
            
            % Create small history window
            histFig = uifigure('Name', 'Modification History', 'Position', [200 200 500 400], 'Resize', 'off');
            
            % Text area with history
            histText = uitextarea(histFig, 'Position', [10 50 480 340], 'Editable', 'off', 'FontSize', 10);
            histText.Value = historyLog;
            
            % Export button
            uibutton(histFig, 'push', 'Text', '📄 Export Log', ...
                'Position', [10 10 120 30], 'ButtonPushedFcn', @(~,~) exportHistory());
            
            function exportHistory()
                [file, path] = uiputfile('*.txt', 'Export modifications log');
                if isequal(file, 0)
                    return;
                end
                fullpath = fullfile(path, file);
                fid = fopen(fullpath, 'w');
                for i = 1:length(historyLog)
                    fprintf(fid, '%s\n', historyLog{i});
                end
                fclose(fid);
                uialert(histFig, 'Log exported successfully', 'Success', 'Icon', 'success');
            end
        end
        
    end
    
end
