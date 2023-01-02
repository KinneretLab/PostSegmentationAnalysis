classdef ImageComponentHandler < handle
    %IMAGECOMPONENTHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        ImageDisplayHandler
        ImageBuilder
        frame_default_value_=1
        shown_layer_
        app_ 
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
            obj.renderFromImageBuilder(true);
            obj.app_.ImageTab.Parent=obj.app_.TabGroup;
            obj.showLayers(obj.app_);
            obj.setImageSettings(obj.app_);
        end
        
        function saveFigures(obj)
            path = uigetdir;
            if(path ==0)
                return;
            end
            obj.ImageBuilder.output_folder(path).draw();
        end
        
        function renderFromInput(obj)
            obj.setImageData;
            obj.ImageBuilder.layers_data(obj.shown_layer_,obj.layer_data_panel_.getLayerData(obj.ImageBuilder.layers_data(obj.shown_layer_)));
            obj.renderFromImageBuilder(false);
            if(~obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=false;
            end
        end
        
        function renderFromImageBuilder(obj, is_new_image)
            obj.is_layer_first_loaded_=false;
            obj.ImageDisplayHandler.closeFigure;
            obj.ImageDisplayHandler.show;
            if(is_new_image)
                obj.setNumOfFrames( length(obj.ImageBuilder.layer_arr));
            end
        end
        
        function loadBackground(obj)
            back=Utilities.getBackground();
            obj.ImageBuilder.image_data.setBackgroundImage(back);
            if(obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=true;
            end
        end

        function setDisplayedFrameNumber(obj, frame_num)
            obj.app_.FrameNumLabel.Text = sprintf("%d",frame_num);
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
            obj.ImageBuilder.image_data.setBackgroundImage({});
        end
        
    end
    
    methods (Access=private)     
        function setNumOfFrames(obj, num)
            if(num==1)
                obj.app_.ChooseFrameSlider.Visible=false;
                return;
            end
            obj.app_.ChooseFrameSlider.Visible=true;
            obj.app_.ChooseFrameSlider.Limits= [1 num];
            obj.app_.ChooseFrameSlider.Value=obj.frame_default_value_;
        end
        
        function setImageData(obj)
            obj.ImageBuilder.image_data.setImageTitle(obj.app_.ImageTitleEditField.Value);
            color = [obj.app_.RValue.Value obj.app_.GValue.Value obj.app_.BValue.Value];
            obj.ImageBuilder.image_data.setColorForNaN(color);
            obj.ImageBuilder.image_data.setShowColorbar(obj.app_.ShowColorbarCheckBox.Value);
            obj.ImageBuilder.image_data.setColorbarTitle(obj.app_.ColorbarTitleEditField.Value);
            obj.ImageBuilder.image_data.setLegendForMarkers(obj.app_.ShowLegendCheckBox.Value);
            obj.ImageBuilder.image_data.setCrop(obj.app_.CropCheckBox.Value);
            obj.ImageBuilder.image_data.setCropSize(obj.app_.CropSizeEditField.Value);
            crop_center_point=[obj.app_.CropC_X.Value obj.app_.CropC_Y.Value];
            obj.ImageBuilder.image_data.setCropCenterPoint(crop_center_point);
        end
        
        function setImageSettings(obj, ~)
            obj.app_.ImageTitleEditField.Value=obj.ImageBuilder.image_data.getImageTitle();
            color=obj.ImageBuilder.image_data.getColorForNaN();
            obj.app_.RValue.Value=color(1);
            obj.app_.GValue.Value=color(2);
            obj.app_.BValue.Value=color(3);
            obj.app_.ShowColorbarCheckBox.Value =obj.ImageBuilder.image_data.getShowColorbar();
            obj.app_.ColorbarTitleEditField.Value=obj.ImageBuilder.image_data.getColorbarTitle();
            obj.app_.ShowLegendCheckBox.Value=obj.ImageBuilder.image_data.getLegendForMarkers();
            obj.app_.DeleteBackgroundButton.Enable=true;
            if(~obj.canDeleteBackground())
                obj.app_.DeleteBackgroundButton.Enable=false;
            end
            obj.app_.CropCheckBox.Value=obj.ImageBuilder.image_data.getCrop;
            obj.app_.CropSizeEditField.Value=obj.ImageBuilder.image_data.getCropSize;
            crop_c_point=obj.ImageBuilder.image_data.getCropCenterPoint;
            obj.app_.CropC_X.Value=crop_c_point(1);
            obj.app_.CropC_Y.Value=crop_c_point(2);

        end
        
        function can_delete= canDeleteBackground(obj)
            [~, col]=size(obj.ImageBuilder.layers_data);
            if(isempty(obj.ImageBuilder.image_data.getBackgroundImage()))
                can_delete=false;
                return;
            end
            for i=1:col
                if(obj.ImageBuilder.layers_data(i).getType()==obj.image_type)
                    can_delete=true;
                    return;
                end
            end
            can_delete=false;
        end
        
        function showLayers(obj, ~)
            obj.layers_panel_.create(obj.ImageBuilder.layers_data);
        end 
        
        function showLayerData(obj)
            obj.layer_data_panel_.create(obj.ImageBuilder.layers_data(obj.shown_layer_));
        end 
    end
end

