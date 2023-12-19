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
        % Option to draw the marker layer as a line rather than a scatter (good for
        % outlines of regions)
        % type: bool
        markers_as_line_
        % Option for line style for marker (dashed, etc) if used as line
        % type: str
        marker_line_spec_
        %For a marker or quiver layer- the line width of the marker/quiver        
        %type: float
        line_width_
        %For a quiver layer: indecates whether the quiers will have an
        %arrawhead.
        %type: bool
        quiver_show_arrow_head_
        %For calculate: the class of the layer.
        %example: "cells", "bonds", etc.
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
        logger = Logger('ImageLayerDrawData');
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
            obj.markers_as_line_ = false;
            obj.marker_line_spec_ = '-';
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
            %SETSCALE  Sets the scale of the data in layer, for example:
            %areas between a certain scale. example: [min, max]
            % Input: type: float[]
            %returns: ImageDrawData
            obj.scale_ = value;
        end

        function value = getScale(obj)
            %GETSCALE  Gets the scale of the data in layer, for example:
            %areas between a certain scale. example: [min, max]
            %returns: type: float[]           
            value = obj.scale_;
        end

        function obj = setColormap(obj, value)
            %SETCOLORMAP  Sets the colormap.
            %defalut: "jet"
            %must be a colormap defined by matlab
            % Input: type: string
            %returns: ImageDrawData
            colormaps=PresetValues.getColormaps;
            if isstring(value)
                if(ismember(value, colormaps))
                    obj.colormap_ = value;
                else
                    obj.logger.error("Coundn't set value for setColormap please check if colormap is one recognized by matlab");
                end
            else
               if (size(value,1)>1 && size(value,2)==3)
                   obj.colormap_ = value;
               else
                obj.logger.error("Coundn't set value for setColormap please check if colormap is one recognized by matlab");
               end
            end
        end

        function value = getColormap(obj)
            %GETCOLORMAP  Gets the colormap.
            %returns: string
            value = obj.colormap_;
        end

        function obj = setColorbar(obj, value)
            %SETCOLORBAR  Sets if the colorbar is set for this layer.
            %Indicates whether the colorbar is displayed for the current layer (displays the data of the current layer).
            %for the colorbar to be displayed this needs to be true but also in
            %ImageDrawData the show_colorbar_ property needs to be set to true
            %(by using image_data.setShowColorbar(true))
            % Input: type: bool
            %returns: ImageDrawData
            obj.colorbar_ = value;
        end

        function value = getColorbar(obj)
            %GETCOLORMAP  Gets if the colorbar is set for this layer.
            %Indicates whether the colorbar is displayed for the current layer (displays the data of the current layer).
            %for the colorbar to be displayed this needs to be true but also in
            %ImageDrawData the show_colorbar_ property needs to be set to true
            %(by using image_data.setShowColorbar(true))
            %returns: bool
            value = obj.colorbar_;
        end

        function obj = setOpacity(obj, value)
            %SETOPACITY  Sets the opacity for the layer.
            %The opacity of the layer, values between 0 and 1
            % type: float - between 0 and 1
            %returns: ImageDrawData
            if value>=0 && value<=1
                obj.opacity_ = value;
            else
                obj.logger.error("Coundn't set value for setOpacity please check if value is between 0 and 1");
            end
        end

        function value = getOpacity(obj)
            %GETOPACITY  Gets the opacity for the layer.
            %The opacity of the layer, values between 0 and 1
            %returns: float - between 0 and 1
            value = obj.opacity_;
        end

        function obj = setShow(obj, value)
            %SETSHOW  Sets whether the layer is visible
            %type: Input: bool
            %returns: ImageDrawData
            obj.show_ = value;
        end

        function value = getShow(obj)
            %GETSHOW  Sets whether the layer is visible
            %returns: bool
            value = obj.show_;
        end

        function obj = setMarkersShape(obj, value)
            %SETMARKERSSHAPE  Sets the shape of the markers
            %For a marker layer- the shape (name) of the markers as recorgnized
            %by matlab.
            %  Use one of these values: '+' | 'o' | '*' | '.' | 'x' |
            % 'square' | 'diamond' | 'v' | '^' | '>' | '<' | 'pentagram' | 'hexagram' | 'none'.
            %type: input: str
            shapes=PresetValues.getMarkerShapes;
            if(ismember(value,shapes))
                obj.markers_shape_ = value;
            else 
                obj.logger.error("Coundn't set value for setMarkersShape please check if the shape is one recognized by matlab");
            end
            
        end

        function value = getMarkersShape(obj)
            %GETMARKERSSHAPE  Gets the shape of the markers
            %returns: str
            value = obj.markers_shape_;
        end

        function obj = setMarkersColor(obj, value)
            %SETMARKERSCOLOR  Sets the color of the markers
            %For a marker or quiver layer- the color (name) of the markers/quivers as recorgnized
            %by matlab.
            %type: str
            colors=PresetValues.getColors;
            if(ismember(value, colors))
                obj.markers_color_ = value;
            else
                obj.logger.error("Coundn't set value for setMarkersColor please check if the color is one recognized by matlab");
            end
        end

        function value = getMarkersColor(obj)
            %GETMARKERSCOLOR Get the color of the markers
            %returns: str
            value = obj.markers_color_;
        end

        function obj = setMarkersSize(obj, value)
            %SETMARKERSSIZE  Sets the size of the markers
            %For a marker or quiver layer- the size of the markers/quivers. (if
            %they aren't displayed by the value (markers_size_by_value_=false)).
            %type: input: float values between 0 and inf
            obj.markers_size_ = value;
        end

        function value = getMarkersSize(obj)
            %GETMARKERSSIZE  Sets the size of the markers
            %For a marker or quiver layer- the size of the markers/quivers. (if
            %they aren't displayed by the value (markers_size_by_value_=false)).
            %returns: float values between 0 and inf
            value = obj.markers_size_;
        end


        function obj = setMarkersColorByValue(obj, value)
            %SETMARKERSCOLORBYVALUE Sets whether the color of the markers will be set by the
            %value (in the layer_arr) if true the colormap used is the one set in
            %the property colormap_
            %type: input: bool

            obj.markers_color_by_value_ = value;
        end

        function value = getMarkersColorByValue(obj)
            %GETMARKERSCOLORBYVALUE Gets whether the color of the markers will be set by the
            %value (in the layer_arr) if true the colormap used is the one set in
            %the property colormap_
            %returns: bool
            value = obj.markers_color_by_value_;
        end

        function obj = setMarkersSizeByValue(obj, value)
            %SETMARKERSSIZEBYVALUE Sets whether the size of the markers will be set by the
            %value (in the layer_arr)
            %type: input: bool
            obj.markers_size_by_value_ = value;
        end

        function value = getMarkersSizeByValue(obj)
            %GETMARKERSSIZEBYVALUE Gets whether the size of the markers will be set by the
            %value (in the layer_arr)
            %returns: bool
            value = obj.markers_size_by_value_;
        end

        function value = getDialation(obj)
            %NOT FUNCTIONAL, WILL HAVE NO EFFECT
            value = obj.dialation_;
        end

        function obj = setDialation(obj, value)
            %NOT FUNCTIONAL, WILL HAVE NO EFFECT
            obj.dialation_ = value;
        end

        function obj = setLineWidth(obj, value)
            %SETLINEWIDTH Sets the line width of the marker/quiver
            %For a marker or quiver layer- the line width of the marker/quiver
            %type: input: float
            obj.line_width_ = value;
        end

        function value = getLineWidth(obj)
            %GETLINEWIDTH Gets the line width of the marker/quiver
            %For a marker or quiver layer- the line width of the marker/quiver
            %returns: float
            value = obj.line_width_;
        end

        function obj = setMarkersAsLine(obj, value)
            %SETMARKERSASLINE Sets whether the marker layer should be
            %plotted as a line.
            %For a marker layer, whether to plot as a line.
            %type: input: float
            obj.markers_as_line_ = value;
        end

        function value = getMarkersAsLine(obj)
            %GETMARKERSASLINE  whether the marker layer should be
            %plotted as a line.
            %For a marker layer, whether to plot as a line.
            %returns: float
            value = obj.markers_as_line_;
        end

        function obj = setMarkerLineSpec(obj, value)
            %SETMARKERLINESPE Sets the line width of the marker/quiver
            %For a marker layer that is drawn as a line - the line spec of the marker
            %type: input: float
            obj.marker_line_spec_ = value;
        end

        function value = getMarkerLineSpec(obj)
            %GETMARKERLINESPEC Gets the line specification of the marker
            %For a marker layer that is drawn as a line - the line spec of the marker
            %returns: float
            value = obj.marker_line_spec_;
        end


        function obj = setQuiverShowArrowHead(obj, value)
            %SETQUIVERSHOWARROWHEAD Sets  whether the quiers will have an
            %arrawhead. For a quiver layer.
            %type: input: bool
            obj.quiver_show_arrow_head_ = value;
        end

        function value = getQuiverShowArrowHead(obj)
            %GETQUIVERSHOWARROWHEAD Gets  whether the quiers will have an
            %arrawhead. For a quiver layer.
            %returns: bool
            value = obj.quiver_show_arrow_head_;
        end

        function obj = setIsSolidColor(obj, value)
            %SETISSOLIDCOLOR Sets whether the layer is of a single solid color
            %type: input: bool
            obj.is_solid_color_ = value;
        end

        function value = getIsSolidColor(obj)
            %GETISSOLIDCOLOR Gets whether the layer is of a single solid color
            %returns: bool
            value = obj.is_solid_color_;
        end

        function obj = setSolidColor(obj, value)
            %SETSOLIDCOLOR Sets color in rgb of the pixels of the layer.
            %if is_solid_color_ is
            %false will be disregarded.
            % type: input: float[] (array) example: [256,256,256] -> white
            obj.solid_color_ = value;
        end

        function value = getSolidColor(obj)
            %GETSOLIDCOLOR Gets color in rgb of the pixels of the layer.
            %if is_solid_color_ is
            %false will be disregarded.
            %returns: float[] (array) example: [256,256,256] -> white
            value = obj.solid_color_;
        end

        function obj = setFilterFunction(obj, func)
            % SETFILTERFUNCTION Add a filter to apply on the data before starting the calculation at all.
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
            % GETFILTERFUNCTION returns the filter function.
            value = obj.filter_fun_;
        end

        function obj = setValueFunction(obj, func)
            %SETVALUEFUNCTION Sets the value function for the layer.
            %For calculate: the value function for the layer. Used to sort
            %the values of the data.
            %example: @(cell)( mod(atan([cell.elong_yy]./[cell.elong_xx])+pi,pi)),'aspect_ratio','area'
            %type: input: str or anonymus function
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
            %GETVALUEFUNCTION Gets the value function for the layer.
            %For calculate: the value function for the layer. Used to sort
            %the values of the data.
            %example: @(cell)( mod(atan([cell.elong_yy]./[cell.elong_xx])+pi,pi)),'aspect_ratio','area'
            %returns: str or anonymus function
            value = obj.value_fun_;
        end

        function obj = setClass(obj, value)
            %SETCLASS Sets the class of the layer, for calculate.
            %example: "cells", "bonds", etc.
            %type: str
            obj.class_ = value;
        end

        function value = getClass(obj)
            %GETCLASS Gets the class of the layer, for calculate.
            %example: "cells", "bonds", etc.
            %type: str
            value = obj.class_;
        end

        function obj = setType(obj, value)
            %SETTYPE Sets the type of layer: "image", "quiver" or "list" (marker)
            %type: input: string
            obj.type_ = value;
        end

        function value = getType(obj)
            %GETTYPE Gets the type of layer: "image", "quiver" or "list" (marker)
            %returns: string
            value = obj.type_;
        end

        function obj = setCalibrationFunction(obj, value)
            %SETCALIBRATIONFUNCTION Sets the calibration data for
            %calculate.
            %example: {'xy',0}
            %type: cell{}
            obj.calibration_fun_ = value;
        end

        function value = getCalibrationFunction(obj)
            %GETCALIBRATIONFUNCTION Gets the calibration data for
            %calculate.
            %example: {'xy',0}
            %type: cell{}
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

