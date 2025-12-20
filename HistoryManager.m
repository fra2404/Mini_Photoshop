% Project: Mini Photoshop
% Author: Francesco Albano - LJ2506219
% University: BUAA
% Course: Technical Computing & Programming for Engineers
% Date: 20/12/2025
% Version: v1.0 (final delivery)
% GitHub: https://github.com/fra2404/Mini_Photoshop
% Description: Manages the undo/redo history for image states and adjustments. Stores full image states and provides history navigation.

classdef HistoryManager < handle
    
    properties
        History
        HistoryIndex
        HistoryLog
    end
    
    methods
        
        function obj = HistoryManager()
            obj.History = {};
            obj.HistoryIndex = 0;
            obj.HistoryLog = {};
        end
        
        function addToHistoryLog(obj, msg)
            obj.HistoryLog{end+1} = msg;
        end
        
        function entry = undo(obj)
            if obj.HistoryIndex > 1
                obj.HistoryIndex = obj.HistoryIndex - 1;
                entry = obj.History{obj.HistoryIndex};
            else
                entry = [];
            end
        end
        
        function entry = redo(obj)
            if obj.HistoryIndex < length(obj.History)
                obj.HistoryIndex = obj.HistoryIndex + 1;
                entry = obj.History{obj.HistoryIndex};
            else
                entry = [];
            end
        end
        
        function pushToHistory(obj, img, brightness, contrast, saturation, pointsR, pointsG, pointsB)
            obj.HistoryIndex = obj.HistoryIndex + 1;
            if obj.HistoryIndex > length(obj.History)
                obj.History{obj.HistoryIndex} = struct('image', img, 'brightness', brightness, 'contrast', contrast, 'saturation', saturation, 'pointsR', pointsR, 'pointsG', pointsG, 'pointsB', pointsB);
            else
                obj.History{obj.HistoryIndex} = struct('image', img, 'brightness', brightness, 'contrast', contrast, 'saturation', saturation, 'pointsR', pointsR, 'pointsG', pointsG, 'pointsB', pointsB);
                obj.History(obj.HistoryIndex+1:end) = [];
            end
        end
    end
    
end