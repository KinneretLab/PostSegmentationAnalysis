classdef ImageDisplayHandler < handle
    %IMAGEDISPLAYHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        figures_
        displayed_frame_num_=0
    end
    
    methods
        function show(obj, app, frameNum)
            if(obj.displayed_frame_num_~=0)
                set(obj.figures_{obj.displayed_frame_num_},'visible','off');
            end
            obj.displayed_frame_num_=frameNum;
            figure=obj.figures_{frameNum};
            set(figure,'CloseRequestFcn',[]);
            set(figure,'visible','on');
            %             ax = figure.CurrentAxes;
            %             copyobj(ax, app.UIAxes);
        end
        
        function setFigures(obj, figures)
            obj.figures_=figures;
        end
    end
end

