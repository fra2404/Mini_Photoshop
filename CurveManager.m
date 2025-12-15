% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 16/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Manages the RGB curve points for tone adjustments. Supports adding, removing, and resetting control points for interactive curve editing.

classdef CurveManager < handle
    
    properties
        CurvePointsR
        CurvePointsG
        CurvePointsB
        CurrentChannel
        AddMode
        RemoveMode
    end
    
    methods
        
        function obj = CurveManager()
            obj.CurvePointsR = [0 255; 0 255];
            obj.CurvePointsG = [0 255; 0 255];
            obj.CurvePointsB = [0 255; 0 255];
            obj.CurrentChannel = 'RGB';
            obj.AddMode = false;
            obj.RemoveMode = false;
        end
        
        function reset(obj)
            obj.CurvePointsR = [0 255; 0 255];
            obj.CurvePointsG = [0 255; 0 255];
            obj.CurvePointsB = [0 255; 0 255];
        end
        
        function setChannel(obj, channel)
            obj.CurrentChannel = channel;
        end
        
        function enableAddMode(obj)
            obj.AddMode = true;
            obj.RemoveMode = false;
        end
        
        function enableRemoveMode(obj)
            obj.RemoveMode = true;
            obj.AddMode = false;
        end
        
        function disableModes(obj)
            obj.AddMode = false;
            obj.RemoveMode = false;
        end
        
        function addPoint(obj, x, y)
            % Clamp coordinates
            x = max(0, min(255, x));
            y = max(0, min(255, y));
            
            if strcmp(obj.CurrentChannel, 'R') || strcmp(obj.CurrentChannel, 'RGB')
                obj.CurvePointsR = [obj.CurvePointsR [x; y]];
                obj.CurvePointsR = sortrows(obj.CurvePointsR', 1)';
            end
            if strcmp(obj.CurrentChannel, 'G') || strcmp(obj.CurrentChannel, 'RGB')
                obj.CurvePointsG = [obj.CurvePointsG [x; y]];
                obj.CurvePointsG = sortrows(obj.CurvePointsG', 1)';
            end
            if strcmp(obj.CurrentChannel, 'B') || strcmp(obj.CurrentChannel, 'RGB')
                obj.CurvePointsB = [obj.CurvePointsB [x; y]];
                obj.CurvePointsB = sortrows(obj.CurvePointsB', 1)';
            end
        end
        
        function removePoint(obj, x, y)
            threshold = 20;
            
            if strcmp(obj.CurrentChannel, 'R') || strcmp(obj.CurrentChannel, 'RGB')
                if size(obj.CurvePointsR, 2) > 2
                    distances = sqrt((obj.CurvePointsR(1,:) - x).^2 + (obj.CurvePointsR(2,:) - y).^2);
                    [minDist, idx] = min(distances);
                    if minDist < threshold
                        if obj.CurvePointsR(1, idx) ~= 0 && obj.CurvePointsR(1, idx) ~= 255
                            obj.CurvePointsR(:, idx) = [];
                        end
                    end
                end
            end
            if strcmp(obj.CurrentChannel, 'G') || strcmp(obj.CurrentChannel, 'RGB')
                if size(obj.CurvePointsG, 2) > 2
                    distances = sqrt((obj.CurvePointsG(1,:) - x).^2 + (obj.CurvePointsG(2,:) - y).^2);
                    [minDist, idx] = min(distances);
                    if minDist < threshold
                        if obj.CurvePointsG(1, idx) ~= 0 && obj.CurvePointsG(1, idx) ~= 255
                            obj.CurvePointsG(:, idx) = [];
                        end
                    end
                end
            end
            if strcmp(obj.CurrentChannel, 'B') || strcmp(obj.CurrentChannel, 'RGB')
                if size(obj.CurvePointsB, 2) > 2
                    distances = sqrt((obj.CurvePointsB(1,:) - x).^2 + (obj.CurvePointsB(2,:) - y).^2);
                    [minDist, idx] = min(distances);
                    if minDist < threshold
                        if obj.CurvePointsB(1, idx) ~= 0 && obj.CurvePointsB(1, idx) ~= 255
                            obj.CurvePointsB(:, idx) = [];
                        end
                    end
                end
            end
        end
        
        function isDefault = isAtDefault(obj)
            isDefault = isequal(obj.CurvePointsR, [0 255; 0 255]) && ...
                       isequal(obj.CurvePointsG, [0 255; 0 255]) && ...
                       isequal(obj.CurvePointsB, [0 255; 0 255]);
        end
        
    end
    
end
