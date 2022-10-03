classdef ImageComponentHandler < handle
    %IMAGECOMPONENTHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        ImageDisplayHandler
        %         ImageRawData
        %         NumOfFrames
        %         NumOfLayers
        %         ShownFrame
        ImageBuilder
        frame_default_value_=1
    end
    
    methods(Access=public)
        function obj= ImageComponentHandler(imageDisplayHandler, imageBuilder)
            obj.ImageDisplayHandler=imageDisplayHandler;
            obj.ImageBuilder=imageBuilder;
        end
        
        %         function addImage(obj, app, imageRawData)
        %             obj.ImageRawData=imageRawData;
        %             obj.show(app);
        %             [obj.NumOfLayers, obj.NumOfFrames] = size(obj.ImageRawData);
        %             obj.showNumOfFrames(app);
        %             obj.setFrame(obj.frameDefaultValue);
        %             obj.ImageDisplayHandler.show(app, obj.ShownFrame);
        %         end
        
        function show(obj, app)
            obj.renderFromImageBuilder(app);
            app.ImageTab.Parent=app.TabGroup;
        end
        
    end
    
    methods (Access=private)
        %         function showNumOfFrames(obj, app) %add joint support for load images
        %             app.FrameNumberEditField.Visible='on';
        %             app.FrameNumberEditFieldLabel.Visible='on';
        %             app.FrameNumberEditFieldLabel.Text=sprintf('Frame Number (Between 1-%d):',obj.NumOfFrames);
        %         end
        
        function renderFromImageBuilder(obj, app)
            figures=obj.ImageBuilder.draw();
            obj.ImageDisplayHandler.setFigures(figures);
            obj.ImageDisplayHandler.show(app, obj.frame_default_value_);
            obj.setNumOfFrames(app, figures);
        end
        
        function setNumOfFrames(obj, app, figures)
            [row col]=size(figures);
            app.ChooseFrameSlider.Limits= [1 col];
        end 
        
        function chooseFrame(obj, app) %add joint support for load images
%             value = app.FrameNumberEditField.Value;
%             %add validation
%             obj.setFrame(value);
        end
        
        function setFrame(obj, frame) %add joint support for load images
            %add validation
            %             obj.ShownFrame=obj.ImageRawData{frame};
        end
        
    end
end

