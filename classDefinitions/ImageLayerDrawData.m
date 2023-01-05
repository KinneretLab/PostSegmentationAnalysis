classdef ImageLayerDrawData < handle
    %IMAGELAYERDRAWDATA class that stores the Image data that is layer
    %specific.
    %For example: scale, whether to show the layer, layer type etc.

    properties (Access=private)
        %Stores the ImageBulder class that contains it, used by close()
        % so you can go back to the Image
        % builder after setting all the properties.
        % type: ImageBuilder
        image_builder_
        %The scale of the values of the layer, of all layer types
        %if you run draw it sets automatically according to the first
        %relevant frame
        % example: [min, max]
        %type: float[] 
        scale_
        %The name of the colormap of the layer (has to be recognized by matlab).
        %type: str 
        colormap_
        %Indicates whether the layer is of a single solid color
        %type: bool
        is_solid_color_
        %Color in rgb of the pixels of the layer. if is_solid_color_ id
        %false will be disregarded.
        % type: float[] (array)
        solid_color_
        %The opacity of the layer, values between 0 and 1
        % type: float - between 0 and 1
        opacity_
        %Indicates whether the layer is shown
        %type: bool
        show_
        %For a marker layer- the shape (name) of the markers as recorgnized
        %by matlab.
        %  Use one of these values: '+' | 'o' | '*' | '.' | 'x' |
        % 'square' | 'diamond' | 'v' | '^' | '>' | '<' | 'pentagram' | 'hexagram' | 'none'.
        %type: str
        markers_shape_
        %For a marker or quiver layer- the color (name) of the markers/quivers as recorgnized
        %by matlab.
        %type: str
        markers_color_
        %For a marker or quiver layer- the size of the markers/quivers. (if
        %they aren't displayed by the value (markers_size_by_value_=false)).
        %type: float values between 0 and inf
        markers_size_
        %Indicates whether the color of the markers will be set by the
        %value (in the layer_arr) if true the colormap used is the one set in
        %the property colormap_
        %type: bool
        markers_color_by_value_ 
        %Indicates whether the size of the markers will be set by the
        %value (in the layer_arr)
        %type: bool
        markers_size_by_value_
        %For a marker or quiver layer- the line width of the marker/quiver
        %type: float
        line_width_
        %For a quiver layer: indecates whether the quiers will have an
        %arrawhead.
        %type: bool
        quiver_show_arrow_head_
        %For calculate: the class of the layer.
        %example: "cells", "bonds", "etc".
        %type: str
        class_
        %For calculate: the filter function for the layer that indicates
        %which objects from the data will be displayed. 
        %example: "[obj_arr.aspect_ratio]>1.25"
        %type: str
        filter_fun_
        %For calculate: the value function for the layer.
        %example: @(cell)( mod(atan([cell.elong_yy]./[cell.elong_xx])+pi,pi)),'aspect_ratio','area'
        %type: str or anonymus function
        value_fun_
        %The type of layer: "image", "quiver" or "list" (marker)
        %type: string
        type_
        %For calculate: the calibration data
        %example: {'xy',0}
        %type: cell{}
        calibration_fun_
        %Indicates whether the colorbar is displayed for the current layer (displays the data of the current layer).
        %for the colorbar to be displayed this needs to be true but also in
        %ImageDrawData the show_colorbar_ property needs to be set to true
        %(by using image_data.setShowColorbar(true))
        colorbar_
        dialation_ %NOT FUNCTIONAL YET!
    end

    properties (Constant)
        logger = Logger('ImageDrawData');
    end

    methods (Access=public)
        function obj = ImageLayerDrawData(image_builder)
            obj.scale_=[];
            obj.colormap_="jet";
            obj.opacity_=1;
            obj.show_= true;
            obj.markers_shape_="o";
            obj.markers_color_="red";
            obj.markers_size_=2;
            obj.markers_color_by_value_= false;
            obj.markers_size_by_value_= false;
            obj.line_width_=0.5;
            obj.quiver_show_arrow_head_=false;
            obj.is_solid_color_=false;
            obj.solid_color_ = [1 1 1];
            obj.filter_fun_=obj.setFilterFunction("");
            obj.value_fun_={1};
            obj.calibration_fun_={'xy', 0};
            obj.dialation_=[];
            obj.image_builder_=image_builder;
            obj.colorbar_=false;

        end

        function obj = setScale(obj, value)
            obj.scale_ = value;
        end

        function value = getScale(obj)
            value = obj.scale_;
        end

        function obj = setColormap(obj, value)
            colormaps=PresetValues.getColormaps;
            if(ismember(value, colormaps))
                obj.colormap_ = value;
            else
                obj.logger.error("Coundn't set value for setColormap please check if colormap is one recognized by matlab");
            end
        end

        function value = getColormap(obj)
            value = obj.colormap_;
        end

        function obj = setColorbar(obj, value)
            obj.colorbar_ = value;
        end

        function value = getColorbar(obj)
            value = obj.colorbar_;
        end

        function obj = setOpacity(obj, value)
            obj.opacity_ = value;
        end

        function value = getOpacity(obj)
            value = obj.opacity_;
        end

        function obj = setShow(obj, value)
            obj.show_ = value;
        end

        function value = getShow(obj)
            value = obj.show_;
        end

        function obj = setMarkersShape(obj, value)
            shapes=PresetValues.getMarkerShapes;
            if(ismember(value,shapes))
                obj.markers_shape_ = value;
            else 
                obj.logger.error("Coundn't set value for setMarkersShape please check if the shape is one recognized by matlab");
            end
            
        end

        function value = getMarkersShape(obj)
            value = obj.markers_shape_;
        end

        function obj = setMarkersColor(obj, value)
            colors=PresetValues.getColors;
            if(ismember(value, colors))
                obj.markers_color_ = value;
            else
                obj.logger.error("Coundn't set value for setMarkersColor please check if the color is one recognized by matlab");
            end
        end

        function value = getMarkersColor(obj)
            value = obj.markers_color_;
        end

        function obj = setMarkersSize(obj, value)
            obj.markers_size_ = value;
        end

        function value = getMarkersSize(obj)
            value = obj.markers_size_;
        end

        function obj = setMarkersColorByValue(obj, value)
            obj.markers_color_by_value_ = value;
        end

        function value = getMarkersColorByValue(obj)
            value = obj.markers_color_by_value_;
        end

        function obj = setMarkersSizeByValue(obj, value)
            obj.markers_size_by_value_ = value;
        end

        function value = getDialation(obj)
            value = obj.dialation_;
        end

        function obj = setDialation(obj, value)
            obj.dialation_ = value;
        end

        function value = getMarkersSizeByValue(obj)
            value = obj.markers_size_by_value_;
        end

        function obj = setLineWidth(obj, value)
            obj.line_width_ = value;
        end

        function value = getLineWidth(obj)
            value = obj.line_width_;
        end

        function obj = setQuiverShowArrowHead(obj, value)
            obj.quiver_show_arrow_head_ = value;
        end

        function value = getQuiverShowArrowHead(obj)
            value = obj.quiver_show_arrow_head_;
        end

        function obj = setIsSolidColor(obj, value)
            obj.is_solid_color_ = value;
        end

        function value = getIsSolidColor(obj)
            value = obj.is_solid_color_;
        end

        function obj = setSolidColor(obj, value)
            obj.solid_color_ = value;
        end

        function value = getSolidColor(obj)
            value = obj.solid_color_;
        end

        function obj = setFilterFunction(obj, func)
            % FILTERFUNCTION Add a filter to apply on the data before starting the calculation at all.
            % This is not neccesary (you can apply this beforehand in ADDDATA,
            % but is a very useful utility.
            % Parameters:
            %   func: char[], string, double, function, BulkFunc
            %      The function (or property name) to use to determine the
            %      data to keep for the calculation (1 is keep, 0 is
            %      ignore).
            %      All types will be translated into some form of
            %      boolean[](PhysicalEntity[]).
            %      no args: the true function: @(entity_arr) ones(size(entity_arr))
            %      logical or double: this is translated into the constant function.
            %      For example, for f = FILTERFUNCTION(false):
            %         f(entity_arr) = false(size(entity_arr))
            %      char[] or string: this is translated into a function as
            %      if it is literal MATLAB code. You can refer to the input
            %      array using "obj_arr".
            %      For example, for f = FILTERFUNCTION("[obj_arr.confidence] > 0.5"):
            %         f(entity_arr) = [entity_arr.confidence] > 0.5
            %      function or BulkFunc: this is simply set. Function must accept a
            %      PhysicalEntity[] array and return a boolean[].
            %      For example, for f = FILTERFUNCTION(myFunction):
            %         f(entity_arr) = myFunction(entity_arr)
            %      Default: the true function: @(entity_arr) ones(size(entity_arr))

            if isempty(func)
                obj.filter_fun_ = ImageBuilder.logical(true);
            else
                if isa(func, 'char') || isa(func, 'string')
                    if ~contains(func, "obj_arr")
                        warning("[WARN] your filter string does not contain obj_arr. This probably will lead to errors.");
                    end
                    if ~contains(func, "[")
                        warning("[WARN] your filter string does not contain square brackets for working on array. This probably will lead to errors.");
                    end
                    obj.filter_fun_ = @(obj_arr) (eval(func)); % WARNING: do NOT rename obj_arr!
                end
                if isa(func, 'logical') || isa(func, 'double')
                    obj.filter_fun_ = ImageBuilder.logical(logical(func));
                end
                if isa(func, 'function_handle') || isa(func, 'BulkFunc')
                    obj.filter_fun_ = func;
                end
            end
        end

        function value = getFilterFunction(obj)
            value = obj.filter_fun_;
        end

        function obj = setValueFunction(obj, func)
            if ~iscell(func)
                obj.value_fun_{1} = obj.createValueFunction(func);
            else
                for i = 1:length(func)
                    obj.value_fun_{i} = obj.createValueFunction(func{i});
                end
            end
        end

        function this_func=createValueFunction(obj, func)
            if isa(func, 'char') || isa(func, 'string')
                this_func = ImageBuilder.property(func);
            end
            if isa(func, 'double')
                this_func = @(obj) (func);
            end
            if isa(func, 'function_handle')
                this_func = func;
            end
        end

        function value = getValueFunction(obj)
            value = obj.value_fun_;
        end

        function obj = setClass(obj, value)
            obj.class_ = value;
        end

        function value = getClass(obj)
            value = obj.class_;
        end

        function obj = setType(obj, value)
            obj.type_ = value;
        end

        function value = getType(obj)
            value = obj.type_;
        end

        function obj = setCalibrationFunction(obj, value)
            obj.calibration_fun_ = value;
        end

        function value = getCalibrationFunction(obj)
            value = obj.calibration_fun_;
        end

        function builder=close(obj)
            % CLOSE  Returns the ImageBulder class that contains it,
            % so you can go back to the Image
            % builder after setting all the properties.
            % returns: ImageBuilder
            builder=obj.image_builder_;
        end
    end
end

