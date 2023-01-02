classdef ImageLayerDrawData < handle
    %IMAGELAYERDRAWDATA class that stores the Image data that is layer
    %specific.
    %For example: scale, whether to show the layer, layer type etc.

    properties (Access=private)
        image_builder_
        scale_
        colormap_
        is_solid_color_
        solid_color_
        opacity_
        show_
        markers_shape_
        markers_color_
        markers_size_
        markers_color_by_value_ %bool 
        markers_size_by_value_ %bool
        line_width_
        quiver_show_arrow_head_
        class_
        filter_fun_
        value_fun_
        type_
        calibration_fun_
        colorbar_
        dialation_ %need to add full fuctionality
    end

    methods (Access=public)
        function obj = ImageLayerDrawData(image_builder)
            obj.scale_=[];
            obj.colormap_="jet";
            obj.opacity_=1;
            obj.show_= true; %bool
            obj.markers_shape_="o"; %arrows using quiver, everything else using scatter??
            %  Use one of these values: '+' | 'o' | '*' | '.' | 'x' |
            % 'square' | 'diamond' | 'v' | '^' | '>' | '<' | 'pentagram' | 'hexagram' | 'none'.
            obj.markers_color_="red"; %add option for rgb value?
            obj.markers_size_=2;
            obj.markers_color_by_value_= false; %bool
            obj.markers_size_by_value_= false; %bool
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
            obj.colormap_ = value;
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
            obj.markers_shape_ = value;
        end

        function value = getMarkersShape(obj)
            value = obj.markers_shape_;
        end

        function obj = setMarkersColor(obj, value)
            obj.markers_color_ = value;
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

