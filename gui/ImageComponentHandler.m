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
            obj.setImageSettings(app);
        end
        
        function renderFromImageBuilder(obj, app)
            obj.ImageDisplayHandler.hide();
            figures=obj.ImageBuilder.draw(false);
            obj.ImageDisplayHandler.setFigures(figures);
            obj.ImageDisplayHandler.show(app, obj.frame_default_value_);
            app.ChooseFrameSlider.Value=obj.frame_default_value_;
            obj.setNumOfFrames(app, figures);
        end
        
    end
    
    methods (Access=private)
        %         function showNumOfFrames(obj, app) %add joint support for load images
        %             app.FrameNumberEditField.Visible='on';
        %             app.FrameNumberEditFieldLabel.Visible='on';
        %             app.FrameNumberEditFieldLabel.Text=sprintf('Frame Number (Between 1-%d):',obj.NumOfFrames);
        %         end
        
        function setNumOfFrames(obj, app, figures)
            [row col]=size(figures);
            app.ChooseFrameSlider.Limits= [1 col];
        end
        function setImageSettings(obj, app)
            app.ImageTitleEditField.Value=obj.ImageBuilder.image_data_.getImageTitle();
            color=obj.ImageBuilder.image_data_.getColorForNaN();
            app.RValue.Value=color(1);
            app.GValue.Value=color(2);
            app.BValue.Value=color(3);
            app.ShowColorbarCheckBox.Value =obj.ImageBuilder.image_data_.getShowColorbar();
            app.ColorbarTitleEditField.Value=obj.ImageBuilder.image_data_.getColorbarTitle();
            colorbar_scale=obj.ImageBuilder.image_data_.getColorbarAxisScale();
            app.ColorbarAxisMin.Value=colorbar_scale(1);
            app.ColorbarAxisMin.Value=colorbar_scale(2);
            app.ShowLegendCheckBox.Value=obj.ImageBuilder.image_data_.getLegendForMarkers();

            


        end
    end
end

