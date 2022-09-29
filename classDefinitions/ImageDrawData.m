classdef ImageDrawData
    %IMAGEDRAWDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        overlay_ %see how
        background_image_
        color_for_nan_ %in rgb, if there is a background image this setting is disregarded
        %TODO: add protected way to add properties to this class, so they
        %will be validated
        show_colorbar_ %bool %TODO fix for showing multiple colorbars usin freezeColors pack
        colorbar_title_
        colorbar_axis_scale_
        image_title_
        legend_for_markers_
        crop_ %bool %TODO
        crop_size_ %TODO
        crop_center_point_ %TODO
    end
    
    methods
        function obj = ImageDrawData()
            obj.color_for_nan_= [0 0 0];
            obj.background_image_=[];
            obj.show_colorbar_= true;
            obj.colorbar_axis_scale_ = [0 1];
            obj.image_title_="";
            obj.colorbar_title_="";

        end
    end
end

