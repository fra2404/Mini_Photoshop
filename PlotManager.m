% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 20/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Contains static methods for updating histograms and curve plots in the GUI.

classdef PlotManager < handle
    
    methods (Static)
        
        function updateHistogram(img, histogramAxes)
            if isempty(img)
                return;
            end
            cla(histogramAxes);
            
            % Ensure image is uint8 (0-255)
            if isa(img, 'double') || isa(img, 'single')
                img = uint8(img * 255);
            elseif ~isa(img, 'uint8')
                img = uint8(img);
            end
            
            if size(img, 3) == 3
                % For color images, show separate histograms for R, G, B
                % Calculate histograms with explicit bins 0-255
                [countsR, edgesR] = histcounts(img(:,:,1), 0:256);
                [countsG, edgesG] = histcounts(img(:,:,2), 0:256);
                [countsB, edgesB] = histcounts(img(:,:,3), 0:256);
                
                % Apply logarithmic scale for better visibility
                countsR = log1p(countsR);  % log(1 + x) to handle zeros
                countsG = log1p(countsG);
                countsB = log1p(countsB);
                
                % Plot using bar at bin centers
                binsR = edgesR(1:end-1);
                binsG = edgesG(1:end-1);
                binsB = edgesB(1:end-1);
                
                hold(histogramAxes, 'on');
                bar(histogramAxes, binsR, countsR, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'BarWidth', 1);
                bar(histogramAxes, binsG, countsG, 'FaceColor', 'g', 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'BarWidth', 1);
                bar(histogramAxes, binsB, countsB, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'BarWidth', 1);
                hold(histogramAxes, 'off');
                legend(histogramAxes, 'R', 'G', 'B');
            else
                % For grayscale images
                [counts, edges] = histcounts(img(:), 0:256);
                counts = log1p(counts);  % Apply logarithmic scale
                bins = edges(1:end-1);
                bar(histogramAxes, bins, counts, 'FaceColor', 'k', 'EdgeColor', 'none', 'BarWidth', 1);
            end
            title(histogramAxes, 'Histogram (log scale)');
            xlim(histogramAxes, [0 255]);
            grid(histogramAxes, 'on');
        end
        
        function updateCurvePlots(curveAxes, pointsR, pointsG, pointsB, currentChannel)
            cla(curveAxes);
            hold(curveAxes, 'on');
            
            % Plot diagonal reference line (always visible)
            plot(curveAxes, [0 255], [0 255], 'k--', 'LineWidth', 1);
            
            % Plot interpolated curves
            xFine = 0:255;
            if strcmp(currentChannel, 'R') || strcmp(currentChannel, 'RGB')
                if size(pointsR, 1) >= 2 && size(pointsR, 2) >= 2
                    yR = interp1(pointsR(1,:), pointsR(2,:), xFine, 'pchip', 'extrap');
                    yR = max(0, min(255, yR));  % Clamp to 0-255
                    plot(curveAxes, xFine, yR, 'r', 'LineWidth', 2);
                    plot(curveAxes, pointsR(1,:), pointsR(2,:), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
                else
                    % Show default line when no points
                    plot(curveAxes, [0 255], [0 255], 'r', 'LineWidth', 2);
                end
            end
            if strcmp(currentChannel, 'G') || strcmp(currentChannel, 'RGB')
                if size(pointsG, 1) >= 2 && size(pointsG, 2) >= 2
                    yG = interp1(pointsG(1,:), pointsG(2,:), xFine, 'pchip', 'extrap');
                    yG = max(0, min(255, yG));  % Clamp to 0-255
                    plot(curveAxes, xFine, yG, 'g', 'LineWidth', 2);
                    plot(curveAxes, pointsG(1,:), pointsG(2,:), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
                else
                    % Show default line when no points
                    plot(curveAxes, [0 255], [0 255], 'g', 'LineWidth', 2);
                end
            end
            if strcmp(currentChannel, 'B') || strcmp(currentChannel, 'RGB')
                if size(pointsB, 1) >= 2 && size(pointsB, 2) >= 2
                    yB = interp1(pointsB(1,:), pointsB(2,:), xFine, 'pchip', 'extrap');
                    yB = max(0, min(255, yB));  % Clamp to 0-255
                    plot(curveAxes, xFine, yB, 'b', 'LineWidth', 2);
                    plot(curveAxes, pointsB(1,:), pointsB(2,:), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
                else
                    % Show default line when no points
                    plot(curveAxes, [0 255], [0 255], 'b', 'LineWidth', 2);
                end
            end
            
            hold(curveAxes, 'off');
            title(curveAxes, ['RGB Curve - ' currentChannel ' Channel']);
            xlim(curveAxes, [0 255]);
            ylim(curveAxes, [0 255]);
            xlabel(curveAxes, 'Input');
            ylabel(curveAxes, 'Output');
            grid(curveAxes, 'on');
        end
        
    end
    
end