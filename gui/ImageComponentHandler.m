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
        
        function show(obj, app)
            obj.renderFromImageBuilder(app);
            app.ImageTab.Parent=app.TabGroup;
            obj.setImageSettings(app);
        end
        
        function renderFromInput(obj, app)
            obj.setImageData(app);
            obj.renderFromImageBuilder(app);
        end
        
        function renderFromImageBuilder(obj, app)
            obj.ImageDisplayHandler.forceCloseFigures();
            figures=obj.ImageBuilder.draw(false);
            obj.ImageDisplayHandler.setFigures(figures);
            obj.ImageDisplayHandler.show(app);
            app.ChooseFrameSlider.Value=obj.frame_default_value_;
            obj.setNumOfFrames(app, figures);
        end
        
        function loadBackground(obj)
            back=Utilities.getBackground();
            obj.ImageBuilder.image_data_.setBackground(back);
        end
        
    end
    
    methods (Access=private)     
        function setNumOfFrames(obj, app, figures)
            [~, col]=size(figures);
            app.ChooseFrameSlider.Limits= [1 col];
        end
        
        function setImageData(obj, app)
            obj.ImageBuilder.image_data_.setImageTitle(app.ImageTitleEditField.Value);
            color = [app.RValue.Value app.GValue.Value app.BValue.Value];
            obj.ImageBuilder.image_data_.setColorForNaN(color);
            obj.ImageBuilder.image_data_.setShowColorbar(app.ShowColorbarCheckBox.Value);
            obj.ImageBuilder.image_data_.setColorbarTitle(app.ColorbarTitleEditField.Value);
            scale=[app.ColorbarAxisMin.Value app.ColorbarAxisMax.Value];
            obj.ImageBuilder.image_data_.setColorbarAxisScale(scale);
            obj.ImageBuilder.image_data_.setLegendForMarkers(app.ShowLegendCheckBox.Value);
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
            if(~isempty(colorbar_scale))\
                app.ColorbarAxisMin.Value=colorbar_scale(1);
                app.ColorbarAxisMax.Value=colorbar_scale(2);
            end
            app.ShowLegendCheckBox.Value=obj.ImageBuilder.image_data_.getLegendForMarkers();
        end
    end
end

