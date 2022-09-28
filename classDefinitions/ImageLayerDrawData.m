classdef ImageLayerDrawData
    %IMAGELAYERDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        scale_
        color_for_nan_
        colormap_
        opacity_
        show_
        markers_shape_
        markers_color_
        markers_size_
        markers_shape_by_value_ %bool
        markers_color_by_value_ %bool
        markers_size_by_value_ %bool
    end
    
    methods
        function obj = ImageLayerDrawData()
            obj.scale_=[];
            obj.color_for_nan_= "black";
            obj.colormap_="jet";
            obj.opacity_=1;
            obj.show_= true; %bool
            obj.markers_shape_="circle";
            obj.markers_color_="red";
            obj.markers_size_=2;
            obj.markers_shape_by_value_= false; %bool
            obj.markers_color_by_value_= false; %bool
            obj.markers_size_by_value_= false; %bool
        end
        
    end
end

