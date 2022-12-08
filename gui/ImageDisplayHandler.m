classdef ImageDisplayHandler < handle
    %IMAGEDISPLAYHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        figure_=[];
        displayed_frame_num_=1;
        image_builder_
        app_
    end
    
    methods (Access=public)

        function obj = ImageDisplayHandler(app, imageBuilder)
            obj.image_builder_=imageBuilder;
            obj.app_=app;
        end

        function show(obj)
            obj.figure_=obj.image_builder_.frame_to_draw(obj.displayed_frame_num_).draw{1};
            set(obj.figure_,'CloseRequestFcn',[]);
        end
        
        function setFrame(obj, frameNum)
            obj.closeFigure;
            obj.displayed_frame_num_=frameNum;
            obj.show();
        end
        
        function closeFigure(obj)
            if(~isempty(obj.figure_))
                try
                    close(obj.figure_, "force")
                catch
                end 
            end
        end
        
%         function forceCloseFigures(obj)
%             if(~isempty(obj.figures_))
%                 [~, col]=size(obj.figures_);
%                 for i= 1:col
%                     close(obj.figures_{i}, "force");
%                 end
%                 obj.figures_={};
%             end
%         end
        
%         function setFigures(obj, figures)
%             obj.figures_=figures;
%         end
    end
end

