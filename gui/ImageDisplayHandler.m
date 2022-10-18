classdef ImageDisplayHandler < handle
    %IMAGEDISPLAYHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        figures_={};
        displayed_frame_num_=1
    end
    
    methods
        function show(obj, app)
            figure=obj.figures_{obj.displayed_frame_num_};
            set(figure,'CloseRequestFcn',[]);
            set(figure,'visible','on');
        end
        
        function setFrame(obj, app, frameNum)
            obj.hide();
            obj.displayed_frame_num_=frameNum;
            obj.show();
        end
        
        function hide(obj, app)
            set(obj.figures_{obj.displayed_frame_num_},'visible','off');
        end
        
        function forceCloseFigures(obj)
            if(~isempty(obj.figures_))
                [~, col]=size(obj.figures_);
                for i= 1:col
                    close(obj.figures_{i}, "force");
                end
                obj.figures_={};
            end
        end
        
        function setFigures(obj, figures)
            obj.figures_=figures;
        end
    end
end

