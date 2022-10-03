classdef ImageLayerDrawData
    %IMAGELAYERDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        scale_
        colormap_
        opacity_
        show_
        markers_shape_ %TODO
        markers_color_
        markers_size_
        markers_color_by_value_ %bool
        markers_size_by_value_ %bool
        is_marker_quiver_ %TODO
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
        end
        
        %         function obj = setScale(obj, scale)
        %             obj.scale_ = scale;
        %         end
        %
        %         function scale = getScale(obj)
        %             scale = obj.scale_;
        %         end
        
    end
end

