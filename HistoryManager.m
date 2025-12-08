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