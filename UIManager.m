classdef UIManager < handle
    
    methods (Static)
        
        function updateHistogram(img, histogramAxes)
            if isempty(img)
                return;
            end
            cla(histogramAxes);
            if size(img, 3) == 3
                % For color images, show separate histograms for R, G, B
                r = img(:,:,1);
                g = img(:,:,2);
                b = img(:,:,3);
                histogram(histogramAxes, r(:), 'BinWidth', 1, 'FaceColor', 'r', 'FaceAlpha', 0.5);
                hold(histogramAxes, 'on');
                histogram(histogramAxes, g(:), 'BinWidth', 1, 'FaceColor', 'g', 'FaceAlpha', 0.5);
                histogram(histogramAxes, b(:), 'BinWidth', 1, 'FaceColor', 'b', 'FaceAlpha', 0.5);
                hold(histogramAxes, 'off');
                legend(histogramAxes, 'R', 'G', 'B');
            else
                histogram(histogramAxes, img(:), 'BinWidth', 1, 'FaceColor', 'k');
            end
            title(histogramAxes, 'Histogram');
            xlim(histogramAxes, [0 255]);
            grid(histogramAxes, 'on');
        end
        
        function updateCurvePlots(curveAxes, pointsR, pointsG, pointsB, currentChannel)
            cla(curveAxes);
            hold(curveAxes, 'on');
            
            % Plot diagonal reference line
            plot(curveAxes, [0 255], [0 255], 'k--', 'LineWidth', 1);
            
            % Plot interpolated curves
            xFine = 0:255;
            if strcmp(currentChannel, 'R') || strcmp(currentChannel, 'RGB')
                if size(pointsR, 2) >= 2
                    yR = interp1(pointsR(1,:), pointsR(2,:), xFine, 'pchip', 'extrap');
                    yR = max(0, min(255, yR));  % Clamp to 0-255
                    plot(curveAxes, xFine, yR, 'r', 'LineWidth', 2);
                end
                plot(curveAxes, pointsR(1,:), pointsR(2,:), 'ro', 'MarkerSize', 8);
            end
            if strcmp(currentChannel, 'G') || strcmp(currentChannel, 'RGB')
                if size(pointsG, 2) >= 2
                    yG = interp1(pointsG(1,:), pointsG(2,:), xFine, 'pchip', 'extrap');
                    yG = max(0, min(255, yG));  % Clamp to 0-255
                    plot(curveAxes, xFine, yG, 'g', 'LineWidth', 2);
                end
                plot(curveAxes, pointsG(1,:), pointsG(2,:), 'go', 'MarkerSize', 8);
            end
            if strcmp(currentChannel, 'B') || strcmp(currentChannel, 'RGB')
                if size(pointsB, 2) >= 2
                    yB = interp1(pointsB(1,:), pointsB(2,:), xFine, 'pchip', 'extrap');
                    yB = max(0, min(255, yB));  % Clamp to 0-255
                    plot(curveAxes, xFine, yB, 'b', 'LineWidth', 2);
                end
                plot(curveAxes, pointsB(1,:), pointsB(2,:), 'bo', 'MarkerSize', 8);
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