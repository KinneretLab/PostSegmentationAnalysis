classdef ImageComponentHandler < handle
    %IMAGECOMPONENTHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        ImageDisplayHandler
        ImageBuilder
        frame_default_value_=1
        shown_layer_
        app_ %TODO: remove app from functions that recieve it
        layer_data_panel_
        is_layer_first_loaded_=false
        figures_
        layers_panel_
    end
    
    methods(Access=public)
        function obj= ImageComponentHandler(imageDisplayHandler, imageBuilder, app)
            obj.ImageDisplayHandler=imageDisplayHandler;
            obj.ImageBuilder=imageBuilder;
            obj.app_=app;
            obj.layer_data_panel_=LayerDataPanel(obj.app_.GridLayout3, obj);
            obj.layers_panel_=LayersPanel(app.GridLayout8, obj);


        end
        
        function show(obj, app)
            obj.renderFromImageBuilder(app);
            app.ImageTab.Parent=app.TabGroup;
            obj.showLayers(app);
            obj.setImageSettings(app);
        end
        
        function saveFigures(obj)
            [file, path] = uiputfile("*.*");
            if(file ==0)
                return;
            end          
            obj.ImageBuilder.save(obj.figures_, path, file);
        end
        
        function renderFromInput(obj, app)
            obj.setImageData(app);
            obj.ImageBuilder.layers_data_{obj.shown_layer_}=obj.layer_data_panel_.getLayerData(obj.ImageBuilder.layers_data_{obj.shown_layer_});
            obj.renderFromImageBuilder(app);
            if(~obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=false;
            end
        end
        
        function renderFromImageBuilder(obj, app)
            obj.is_layer_first_loaded_=false;
            obj.ImageDisplayHandler.forceCloseFigures();
            obj.figures_=obj.ImageBuilder.draw(false);
            obj.ImageDisplayHandler.setFigures(obj.figures_);
            obj.ImageDisplayHandler.show(app);
            app.ChooseFrameSlider.Value=obj.frame_default_value_;
            obj.setNumOfFrames(app, obj.figures_);
        end
        
        function loadBackground(obj)
            back=Utilities.getBackground();
            obj.ImageBuilder.image_data_.setBackgroundImage(back);
            if(obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=True;
            end
        end
        
        function changeLayer(obj, layer_num)
            if(obj.is_layer_first_loaded_)
                obj.ImageBuilder.layers_data_{obj.shown_layer_}=obj.layer_data_panel_.getLayerData(obj.ImageBuilder.layers_data_{obj.shown_layer_});
            else
                obj.is_layer_first_loaded_=true;
            end
            obj.shown_layer_=layer_num;
            obj.showLayerData();
        end
        
        function deleteBackground(obj)
            obj.ImageBuilder.image_data_.setBackgroundImage({});
        end
        
    end
    
    methods (Access=private)     
        function setNumOfFrames(~, app, figures)
            [~, col]=size(figures);
            if(col==1)
                app.ChooseFrameSlider.Visible=false;
                return;
            end
            app.ChooseFrameSlider.Visible=true;
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
        
        function setImageSettings(obj, ~)
            obj.app_.ImageTitleEditField.Value=obj.ImageBuilder.image_data_.getImageTitle();
            color=obj.ImageBuilder.image_data_.getColorForNaN();
            obj.app_.RValue.Value=color(1);
            obj.app_.GValue.Value=color(2);
            obj.app_.BValue.Value=color(3);
            obj.app_.ShowColorbarCheckBox.Value =obj.ImageBuilder.image_data_.getShowColorbar();
            obj.app_.ColorbarTitleEditField.Value=obj.ImageBuilder.image_data_.getColorbarTitle();
            colorbar_scale=obj.ImageBuilder.image_data_.getColorbarAxisScale();
            if(~isempty(colorbar_scale))
                obj.app_.ColorbarAxisMin.Value=colorbar_scale(1);
                obj.app_.ColorbarAxisMax.Value=colorbar_scale(2);
            end
            obj.app_.ShowLegendCheckBox.Value=obj.ImageBuilder.image_data_.getLegendForMarkers();
            obj.app_.DeleteBackgroundButton.Enable=true;
            if(~obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=false;
            end
        end
        
        function can_delete= canDeleteBackground(obj)
            [~, col]=size(obj.ImageBuilder.layers_data_);
            if(isempty(obj.ImageBuilder.image_data_.getBackgroundImage()))
                can_delete=false;
                return;
            end
            for i=1:col
                can_delete=~obj.ImageBuilder.layers_data_{i}.getIsMarkerLayer() && ~obj.ImageBuilder.layers_data_{i}.getIsMarkerQuiver();
                if(can_delete)
                    return;
                end
            end
        end
        
        function showLayers(obj, ~)
            obj.layers_panel_.create(obj.ImageBuilder.layers_data_);
        end 
        
        function showLayerData(obj)
            obj.layer_data_panel_.create(obj.ImageBuilder.layers_data_{obj.shown_layer_})
        end 
    end
end

