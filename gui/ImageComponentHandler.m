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

    properties (Constant)
        image_type="image";
        marker_type="list";
        quiver_type="quiver";
    end
    
    methods(Access=public)
        function obj= ImageComponentHandler(imageDisplayHandler, imageBuilder, app)
            obj.ImageDisplayHandler=imageDisplayHandler;
            obj.ImageBuilder=imageBuilder;
            obj.app_=app;
            obj.layer_data_panel_=LayerDataPanel(obj.app_.GridLayout3, obj);
            obj.layers_panel_=LayersPanel(app.GridLayout8, obj);
        end
        
        function show(obj)
            obj.renderFromImageBuilder(obj.app_);
            obj.app_.ImageTab.Parent=obj.app_.TabGroup;
            obj.showLayers(obj.app_);
            obj.setImageSettings(obj.app_);
        end
        
        function saveFigures(obj)
            [~, path] = uiputfile("*.*");
            if(path ==0)
                return;
            end
            obj.ImageBuilder.output_folder(path).draw();
        end
        
        function renderFromInput(obj, app)
            obj.setImageData(app);
            obj.ImageBuilder.layers_data(obj.shown_layer_,obj.layer_data_panel_.getLayerData(obj.ImageBuilder.layers_data(obj.shown_layer_)))
            obj.renderFromImageBuilder(app);
            if(~obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=false;
            end
        end
        
        function renderFromImageBuilder(obj, app)
            obj.is_layer_first_loaded_=false;
            obj.ImageDisplayHandler.closeFigure;
            obj.ImageDisplayHandler.show;
            app.ChooseFrameSlider.Value=obj.frame_default_value_;
            obj.setNumOfFrames(app, length(obj.ImageBuilder.layer_arr));
        end
        
        function loadBackground(obj)
            back=Utilities.getBackground();
            obj.ImageBuilder.image_data_.setBackgroundImage(back);
            if(obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=true;
            end
        end
        
        function changeLayer(obj, layer_num)
            if(obj.is_layer_first_loaded_)
                obj.ImageBuilder.layers_data(obj.shown_layer_, obj.layer_data_panel_.getLayerData(obj.ImageBuilder.layers_data(obj.shown_layer_)));
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
        function setNumOfFrames(~, app, num)
            if(num==1)
                app.ChooseFrameSlider.Visible=false;
                return;
            end
            app.ChooseFrameSlider.Visible=true;
            app.ChooseFrameSlider.Limits= [1 num];
        end
        
        function setImageData(obj, app)
            obj.ImageBuilder.image_data.setImageTitle(app.ImageTitleEditField.Value);
            color = [app.RValue.Value app.GValue.Value app.BValue.Value];
            obj.ImageBuilder.image_data.setColorForNaN(color);
            obj.ImageBuilder.image_data.setShowColorbar(app.ShowColorbarCheckBox.Value);
            obj.ImageBuilder.image_data.setColorbarTitle(app.ColorbarTitleEditField.Value);
            scale=[app.ColorbarAxisMin.Value app.ColorbarAxisMax.Value];
            obj.ImageBuilder.image_data.setColorbarAxisScale(scale);
            obj.ImageBuilder.image_data.setLegendForMarkers(app.ShowLegendCheckBox.Value);
        end
        
        function setImageSettings(obj, ~)
            obj.app_.ImageTitleEditField.Value=obj.ImageBuilder.image_data.getImageTitle();
            color=obj.ImageBuilder.image_data.getColorForNaN();
            obj.app_.RValue.Value=color(1);
            obj.app_.GValue.Value=color(2);
            obj.app_.BValue.Value=color(3);
            obj.app_.ShowColorbarCheckBox.Value =obj.ImageBuilder.image_data.getShowColorbar();
            obj.app_.ColorbarTitleEditField.Value=obj.ImageBuilder.image_data.getColorbarTitle();
            colorbar_scale=obj.ImageBuilder.image_data.getColorbarAxisScale();
            if(~isempty(colorbar_scale))
                obj.app_.ColorbarAxisMin.Value=colorbar_scale(1);
                obj.app_.ColorbarAxisMax.Value=colorbar_scale(2);
            end
            obj.app_.ShowLegendCheckBox.Value=obj.ImageBuilder.image_data.getLegendForMarkers();
            obj.app_.DeleteBackgroundButton.Enable=true;
            if(~obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=false;
            end
        end
        
        function can_delete= canDeleteBackground(obj)
            [~, col]=size(obj.ImageBuilder.layers_data);
            if(isempty(obj.ImageBuilder.image_data.getBackgroundImage()))
                can_delete=false;
                return;
            end
            for i=1:col
                can_delete=(~obj.ImageBuilder.layers_data(i).getType()==obj.image_type);
                if(can_delete)
                    return;
                end
            end
        end
        
        function showLayers(obj, ~)
            obj.layers_panel_.create(obj.ImageBuilder.layers_data);
        end 
        
        function showLayerData(obj)
            obj.layer_data_panel_.create(obj.ImageBuilder.layers_data(obj.shown_layer_))
        end 
    end
end

