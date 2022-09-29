classdef ImageLayerDrawData
    %IMAGELAYERDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        scale_ 
        colormap_ 
        opacity_ 
        show_
        markers_shape_ %TODO
        markers_color_ %TODO
        markers_size_ %TODO
        markers_shape_by_value_ %bool, TODO
        markers_color_by_value_ %bool, TODO
        markers_size_by_value_ %bool, TODO
    end
    
    methods (Access=public)
        function obj = ImageLayerDrawData()
            obj.scale_=[];
            obj.colormap_="jet";
            obj.opacity_=1;
            obj.show_= true; %bool
            obj.markers_shape_="circle"; %arrows using quiver, everything else using scatter??
            obj.markers_color_="red";
            obj.markers_size_=2;
            obj.markers_shape_by_value_= false; %bool
            obj.markers_color_by_value_= false; %bool
            obj.markers_size_by_value_= false; %bool
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

