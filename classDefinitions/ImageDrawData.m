classdef ImageDrawData < handle
    %IMAGEDRAWDATA class that stores the Image data that is not layer
    %specific.
    %  For example: image title, background image etc.

    properties (Access=private)
        %Stores the ImageBulder class that contains it, used by close()
        % so you can go back to the Image
        % builder after setting all the properties.
        % type: ImageBuilder
        image_builder_
        %Background image to be displayed bellow all the other layers. Can
        %be one for all frames or one per frame. Make sure that the array
        %size matches the number of frames and that the order is correct.
        % type: Image or Image{} (Cell Array)
        background_image_
        %Indicates if the background image is per frame (meaning it is a cell array) or for all frames.
        %True: Cell array of images, one per frame
        %False: one image for all the frames
        % type: bool
        is_background_per_frame_
        %Color in rgb of all pixels that are nan in the final image. if
        %there is a background image set this is disregarded.
        % type: float[] (array)
        color_for_nan_
        %Indicates if the colorbar will be shown.
        % type: bool
        show_colorbar_
        %The colorbar title that appears bellow the colorbar
        % type: str
        colorbar_title_
        %The image title that appears over the image
        % type: str
        image_title_
        %Indicates if the legend is shown.
        % type: bool
        legend_for_markers_
        %Indicates if the image will be cropped.
        % type: bool
        crop_
        %Number of pixels from crop centerpoint if such is noted, if not,
        %size of pixels from edge of automatic crop.
        % type: int
        crop_size_
        %Center point of crop (x,y coordinates)
        % type: int[]
        crop_center_point_

    end

    properties (Constant)
        logger = Logger('ImageDrawData');
    end

    methods
        function obj = ImageDrawData(image_builder)
            obj.color_for_nan_= [0 0 0];
            obj.background_image_=[];
            obj.is_background_per_frame_=false;
            obj.show_colorbar_= true;
            obj.image_title_="";
            obj.colorbar_title_="";
            obj.legend_for_markers_=false;
            obj.crop_=false;
            obj.image_builder_=image_builder;
            obj.crop_size_=64;
            obj.crop_center_point_=[0 0];
        end

        function obj=setBackgroundImage(obj, value)
            %SETBACKGROUNDIMAGE Sets the background image to be displayed bellow all the other layers. Can
            %be one for all frames or one per frame. Make sure that the array
            %size matches the number of frames. 
            % is_background_per_frame_ is set accordingly
            %sets 
            %Input Type: Image or Image{} (Cell Array)
            %returns: ImageDrawData
            [row, ~]=size(value);
            if(row==1)
                obj.setIsBackgroundPerFrame(true);
            else 
                obj.setIsBackgroundPerFrame(false);
            end
            obj.background_image_ = value;
        end

        function value = getBackgroundImage(obj)
            %GETBACKGROUNDIMAGE Gets the background image to be displayed bellow all the other layers. Can
            %be one for all frames or one per frame.
            %returns: Image or Image{} (Cell Array)
            value = obj.background_image_;
        end

        function obj=setColorForNaN(obj, value)
           %SETCOLORFORNAN  Sets Color in rgb of all pixels that are nan in the final image. if
            %there is a background image set this is disregarded.
            % Input: type: float[] (array), format: [r,g,b]  and r,g,b
            % between 0 and 1
            %returns: ImageDrawData             
            if(length(value)==3)
                if(isfloat(value(1)))
                    obj.color_for_nan_ = value;
                end
            else
                obj.logger.error("Coundn't set value for setColorForNan check help ImageDrawData for format");
            end
        end

        function value = getColorForNaN(obj)
            %GETCOLORFORNAN  Gets Color in rgb of all pixels that are nan in the final image.
            % returns: type: float[] (array), format: [r g b]  and r,g,b
            % between 0 and 1
            value = obj.color_for_nan_;
        end

        function obj=setShowColorbar(obj, value)
            %SETSHOWCOLORBAR  Sets if colorbar is shown
            % Input: type: bool
            %returns: ImageDrawData   
            obj.show_colorbar_ = value;
        end

        function value = getShowColorbar(obj)
            %GETSHOWCOLORBAR  Gets if colorbar is shown
            %returns: bool 
            value = obj.show_colorbar_;
        end

        function obj=setColorbarTitle(obj, value)
            %SETCOLORBARTITLE  Sets Colorbar Title that appears bellow the colorbar
            % Input: type: str
            %returns: ImageDrawData 
            obj.colorbar_title_ = value;
        end

        function value = getColorbarTitle(obj)
            %GETCOLORBARTITLE  Gets Colorbar Title that appears bellow the colorbar
            %returns: str 
            value = obj.colorbar_title_;
        end

        function obj=setImageTitle(obj, value)
            %SETIMAGETITLE  Sets Image Title that appears over the image
            % Input: type: str
            %returns: ImageDrawData 
            obj.image_title_ = value;
        end

        function value = getImageTitle(obj)
            %GETIMAGETITLE  Gets Image Title that appears over the image
            %returns: str 
            value = obj.image_title_;
        end

        function obj=setLegendForMarkers(obj, value)
            %SETLEGENDFORMARKERS Sets if legend is shown
            % Input: type: bool
            %returns: ImageDrawData 
            obj.legend_for_markers_ = value;
        end

        function value = getLegendForMarkers(obj)
            %GETLEGENDFORMARKERS Gets if legend is shown
            %returns: bool
            value = obj.legend_for_markers_;
        end

        function obj=setCrop(obj, value)
            %SETCROP Sets if image will be cropped, if this is set to true
            %and the crop_center_point_ is empty will perform automatic
            %cropping around the center point of the data (not the image)
            %using the masks and will make sure that in all the frames all
            %the data will be shown.
            % Input: type: bool
            %returns: ImageDrawData 
            obj.crop_ = value;
        end

        function value = getCrop(obj)
            %SETCROP Gets if image will be cropped
            %returns: bool
            value = obj.crop_;
        end

        function obj=setCropSize(obj, value)
            %SETCROPSIZE Sets the number of pixels that the image will be cropped to from EACH DIRECTION (4 directions). If crop_center_point_ is not set 
            % the crop size indicates the number of pixels from each side
            % of the determined automatic boundary and if it is set the
            % number indicates the number of pixels from each size of the
            % center point.
            % input: int
            %returns: ImageDrawData
            obj.crop_size_ = value;
        end

        function value = getCropSize(obj)
            % GETCROPSIZE Gets the number of pixels that the image will be cropped to from EACH DIRECTION (4 directions).
            % returns: int
            value = obj.crop_size_;
        end

        function obj=setCropCenterPoint(obj, value)
            % SETCROPCENTERPOINT Sets the center point from which to crop.
            % x,y coordinates.
            % input: type: int[], format: [x y]
            % returns: ImageDrawData
            obj.crop_center_point_ = value;
        end

        function value = getCropCenterPoint(obj)
            % GETCROPCENTERPOINT Gets the center point from which to crop.
            % x,y coordinates.
            % retuns: type: int[], format: [x y]
            value = obj.crop_center_point_;
        end

        function obj=setIsBackgroundPerFrame(obj, value)
            % SETISBACKGROUNDPERFRAME Sets if the background image is per frame (meaning it is a cell array) or for all frames.
            % true: Cell array of images, one per frame
            % false: one image for all the frames
            % input: bool
            % returns: ImageDrawData

            obj.is_background_per_frame_ = value;
        end

        function value = getIsBackgroundPerFrame(obj)
            % GETISBACKGROUNDPERFRAME Gets if the background image is per frame (meaning it is a cell array) or for all frames.
            % true: Cell array of images, one per frame
            % false: one image for all the frames
            % returns: bool
            value = obj.is_background_per_frame_;
        end


        function builder=close(obj)
            % CLOSE  Returns the ImageBulder class that contains it,
            % so you can go back to the Image builder after setting all the properties.
            % returns: ImageBuilder
            builder=obj.image_builder_;
        end
    end
end

