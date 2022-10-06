classdef ImageLayerDrawData < handle
    %IMAGELAYERDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        scale_
        colormap_
        opacity_
        show_
        markers_shape_
        markers_color_
        markers_size_
        markers_color_by_value_ %bool
        markers_size_by_value_ %bool
        is_marker_quiver_ %TODO
        is_marker_layer_
        
        %todo add option to if there are lines make them bolder
    end
    
    methods (Access=public)
        function obj = ImageLayerDrawData()
            obj.scale_=[];
            obj.colormap_="jet";
            obj.opacity_=1;
            obj.show_= true; %bool
            obj.markers_shape_="o"; %arrows using quiver, everything else using scatter??
            %  Use one of these values: '+' | 'o' | '*' | '.' | 'x' |
            % 'square' | 'diamond' | 'v' | '^' | '>' | '<' | 'pentagram' | 'hexagram' | 'none'.
            obj.markers_color_="red"; %add option for rgb value? add option for colormap in case markers color by value true.
            obj.markers_size_=2;
            obj.markers_color_by_value_= false; %bool
            obj.markers_size_by_value_= false; %bool
            obj.is_marker_quiver_=false; %use setter- if markers_shape=="quiver or arrow" is_quiver=false or just add tis
            obj.is_marker_layer_=false;
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
        
        function value = getMarkersSizeByValue(obj)
            value = obj.markers_size_by_value_;
        end
        
        function obj = setIsMarkerQuiver(obj, value)
            obj.is_marker_quiver_ = value;
        end
        
        function value = getIsMarkerQuiver(obj)
            value = obj.is_marker_quiver_;
        end
        
        function obj = setIsMarkerLayer(obj, value)
            obj.is_marker_layer_ = value;
        end
        
        function value = getIsMarkerLayer(obj)
            value = obj.is_marker_layer_;
        end
    end
end
