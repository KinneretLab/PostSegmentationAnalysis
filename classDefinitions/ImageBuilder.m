classdef ImageBuilder <  FigureBuilder & handle 
    % IMAGEBUILDER A tool used to draw, display and save the data from the cell database in
    % layers on top of each other.
    properties (Access = protected)
        %Stores the metadata of the frames that will be drawn.
        % type: {obj array...}
        data_ = {};
        %Stores the graphic data for each layer of the frames that will be
        %drawn. if the layer is an image layer it contains a matrix, if the
        %layer is a marker or quiver layer it contains a list of
        %coordinates
        % type: cell array of double arrays
        layer_arr_   = {};
        %The save format of the images when there is an output_folder_ and
        %frame_to_draw_ is empty can be png or fig
        % type: str
        save_format_ = "png";
        %The frame that will be drawn and displayed. after each run it is
        %restored to the default value, when set the draw function will
        %only draw this frame and will not save the images even if output
        %folder exists.
        % type: int
        frame_to_draw_ = [];
        %The path of the folder that will contain all the saved images
        %(image per frame) and if the builder is saved it will also be
        %saved into this folder
        % type: str
        output_folder_="";
        %The data for calculating and drawing each layer in a cell array
        % type: ImageLayerDrawData{}
        layers_data_ = {};
        %The data for calculating and drawing the image - all the data that isn't layer specific.
        % type: ImageDrawData
        image_data_ = [];
    end

    properties (Constant)
        logger = Logger('ImageBuilder');
        image_type="image";
        marker_type="list";
        quiver_type="quiver";
    end

    methods

        function obj = ImageBuilder()
            obj@FigureBuilder()

            % generic global search for a particular folder; works independent of user
            search_path = '../*/MatlabGeneralFunctions';
            while isempty(dir(search_path))
                search_path = ['../', search_path];
            end
            addpath(dir(search_path).folder)
            search_path = '../*/freezeColors';
            while isempty(dir(search_path))
                search_path = ['../', search_path];
            end
            addpath(dir(search_path).folder)
            search_path = '../*/gui';
            while isempty(dir(search_path))
                search_path = ['../', search_path];
            end
            addpath(dir(search_path).folder)
        end

    end

    methods(Static)
        function func = property(prop_name)
            func = @(obj) (obj.(prop_name));
        end

        function func = logical(const_value)
            % MISSING DOCUMENTATION
            func = BulkFunc(@(entity_arr) const_value & true(size(entity_arr)));
        end
    end

    methods (Access=public)


        function [obj,layer_arr] = calculate(obj)
            %CALCULATE   This function arranges the data according to the desired layers,
            % to later be converted into graphical representation.

            % Initiate output array

            layer_arr = {};

            % Run over list of layers to calculate

            for i= 1:length(obj.layers_data_)
                class=obj.layers_data_{i}.getClass;
                filter_fun=obj.layers_data_{i}.getFilterFunction;
                value_fun=obj.layers_data_{i}.getValueFunction;
                type=obj.layers_data_{i}.getType;
                calibration_fun=obj.layers_data_{i}.getCalibrationFunction;
                frame_arr = obj.data_{:};
                calibration_xy =  obj.data_{1}(1).experiment.calibration_xy_; % Get calibration from experiment
                calibration_z = obj.data_{1}(1).experiment.calibration_z_; % Get calibration from experiment


                for j = 1:length(frame_arr)

                    % Get data arrays for frame, apply filter
                    phys_arr = frame_arr(j).(class);

                    % Apply filter to each entity

                    filtered_arr =  phys_arr(filter_fun(phys_arr));

                    % Get value for each object using the specified value
                    % function for this layer.

                    %  value_arr = arrayfun(value_fun{1},filtered_arr);
                    value_arr = BulkFunc.apply(value_fun{1},filtered_arr,obj,phys_arr);


                    % Apply calibration to values if specified (to convert
                    % pixels to microns)

                    if exist('calibration_list')
                        if strcmp(calibration_fun{1},'xy')
                            value_arr = value_arr*(calibration_xy^(calibration_fun{2}));

                        else if strcmp(calibration_fun{1},'z')
                                value_arr = value_arr*(calibration_z^(calibration_fun{2}));
                        end
                        end
                    end
                    if ~isempty(filtered_arr)

                        if strcmp(type,'image')

                            image_size = obj.data_{1}(1).experiment.image_size_; % GET THIS FROM EXPERIMENT INFO, NEED TO IMPLEMENT THIS

                            % Get relevant pixels (the function plot_pixels is
                            % implemented in every relevant class)
                            plot_pixels = filtered_arr.plot_pixels;

                            this_im = NaN(image_size);

                            for k=1:size(plot_pixels,2)
                                for l=1:size(plot_pixels{k},1)
                                    this_im(plot_pixels{k}(l,1),plot_pixels{k}(l,2)) = value_arr(k); % MAKE THIS NOT NEED LOOP
                                end
                            end

                            layer_arr{i,j} = this_im;

                        elseif strcmp(type,'list')

                            % Get relevant pixels (the function list_pixels is
                            % implemented in every relevant class). For cells,
                            % this is the centre of the cell, for bonds the
                            % middle point of the bond, and for vertices it is
                            % the vertex location.
                            list_pixels = filtered_arr.list_pixels;
                            this_list = [list_pixels,value_arr'];
                            layer_arr{i,j} = this_list;

                        elseif strcmp(type,'quiver')
                            % Get relevant pixels (the function list_pixels is
                            % implemented in every relevant class). For cells,
                            % this is the centre of the cell, for bonds the
                            % middle point of the bond, and for vertices it is
                            % the vertex location.
                            list_pixels = filtered_arr.list_pixels;
                            value_fun_dir = value_fun{1};
                            value_arr_dir = arrayfun(value_fun_dir,filtered_arr);
                            value_fun_size = value_fun{2};
                            value_arr_size = arrayfun(value_fun_size,filtered_arr);
                            this_list = [list_pixels,value_arr_dir',value_arr_size'];
                            layer_arr{i,j} = this_list;

                        else
                            disp(sprintf('Typelist needs to specify image, list or quiver'));
                        end

                    else
                        layer_arr{i,j} = {};
                    end
                end
            end
            obj.layer_arr_ = layer_arr;
        end

        function loadBuilder(obj, input)
            % LOADBUILDER loads an image builder into current builder from the path indicated in input, the
            % builder is saved in a .mat file and the format is the one the
            % function saveBuilder generates.
            % input: str - the path of the saved image builder.
            load(input, 'saved_builder');
            obj.layer_arr_=saved_builder.layer_arr;
            obj.data_=saved_builder.data;
            obj.image_data_=saved_builder.image_data;
            obj.layers_data_=saved_builder.layers_data;
        end

        function obj= saveBuilder(obj, file_name)
            % SAVEBUILDER saves the current image builder into a .mat file.
            % saves it to the folder indicated by output_folder and with
            % the file name file_name that is the input of the function
            % input: str - the file name of the image builder .mat file.
            saved_builder=obj;
            save(fullfile(obj.output_folder_, file_name), 'saved_builder');
        end

        function figures = draw(obj, input)
            % DRAW draws and saves the images.
            % if frame_num_to_draw is given will draw and will only display
            % the image without saving. after each time it is given the
            % frame num to draw will be reset and the next time you will
            % need to give it again. mare detailed explanation in the
            % frame_to_draw function.
            %if input is given the function will load the saved image
            %builder and will later do all the other functionalities
            % if layer_arr is empty the function will call calculate and
            % will later do all the othe functionalities. if you want to
            % call calculate (when there is a layer_arr) you need to call
            % it seperately 
            % input: (optional) str - the path of the saved image builder. 
            %returns: only if the frame_to_draw is set returns the figure.
            %type: matlab figure
            
            if(nargin==1)
                input=[];
            end
            if(~isempty(input)) %checks if there is an input path for the image builder
                obj.loadBuilder(input); %loads builder
            end
            if(isempty(obj.layer_arr_)) %checks if there is a layer_arr - what it draws
                obj.calculate; %calculates a new layer_arr
            end
            [~, col]=size(obj.layer_arr_);
            if(obj.image_data.getCrop)
                [xlims, ylims]=obj.getAxisLims;
            else
                image_size=obj.data_{1}(1).experiment.image_size_;
                xlims=[1, image_size(1)];
                ylims=[1, image_size(2)];
            end
            if(~isempty(obj.frame_to_draw_))
                frame = obj.layer_arr_(:, obj.frame_to_draw_);
                figures{1} = obj.drawFrame(frame, true, obj.frame_to_draw_);
                obj.frame_to_draw_=[];
                xlim(xlims);
                ylim(ylims);
                return;
            end
            if(obj.output_folder_~="")
                for i= 1 : col
                    frame = obj.layer_arr_(:, i);
                    fig=obj.drawFrame(frame, false, i);
                    obj.saveFigure(fig, i, xlims, ylims);
                    close(fig);
                end
            end 
        end

        function obj = addData(obj, frame_arr)
            % ADDDATA add the experiment data here- calculate uses this
            % data
            %input: {obj array...}
            %returns: ImageBuilder
            if ~strcmp(class(frame_arr),'Frame')
                disp(sprint('Data must be an object or array of class frame'));
            else
                obj.data_{1} = frame_arr;
            end
        end

        function obj = save_format(obj,format)
            %SAVE_FORMAT sets the format that the putput (the images) will be saved.
            % either "fig" of "png".
            %input: str
            %returns: ImageBuilder
            obj.save_format_ = format;
        end

        function layer_data=layers_data(obj, layer_num, data)
            %LAYERS_DATA gets or sets the layers_data (type: Image
            %LayerDrawData) depending on the input.
            %example: builder.layers_data(1)-> returns the
            %ImageLayerDrawData for layer 1. if there isn't a layer in
            %the array of that index it creates a default layer objects
            %which you can then change to your liking.
            %builder.layers_data(1, data) data (type: Image
            %LayerDrawData) sets layer 1 with the object data.
            %after setting it the function eturns the new layer (type:
            %ImageLayerDrawData).
            %input: layer_num: int, data: ImageLayerDrawData
            %output: ImageLayerDrawData
            if(nargin==1)
                layer_data=obj.layers_data_;
                return;
            elseif(nargin==3)
                obj.layers_data_{layer_num}=data;
            end
            if(length(obj.layers_data_)<layer_num)
                obj.layers_data_{layer_num}=ImageLayerDrawData(obj);
            elseif(isempty(obj.layers_data_{layer_num}))
                obj.layers_data_{layer_num}=ImageLayerDrawData(obj);
            end
            layer_data = obj.layers_data_{layer_num};
        end


        function image_data = image_data(obj)
            %IMAGE_DATA gets the image data (type: ImageDrawData) if doesnt exist then create default objects and returns it.
            %returns: type: ImageDrawData
            if(isempty(obj.image_data_))
                obj.image_data_=ImageDrawData(obj);
            end
            image_data = obj.image_data_;
        end

        function layer_arr = layer_arr(obj)
            %LAYER_ARR gets the layer_arr
            %returns: type: cell array of double arrays
            layer_arr = obj.layer_arr_;
        end

        function data = data(obj)
            %DATA gets the data that the calculate function uses to
            %calculate the layer_arr
            %returns: type: {obj array...}

            data = obj.data_;
        end

        function obj = frame_to_draw(obj, frame_to_draw)
            %FRAME_TO_DRAW sets the frame to draw- if frame to draw is set
            %the draw function will only *draw and display* that particular
            %frame but will save nothing to the output folder. every time
            %you call the draw function after setting the frame_to_draw it
            %is reset meaning you have to set it again. If you want to
            %consistanaly 
            %example: builder.frame_to_draw(1).draw; 
            %will draw the first frame and you can run that same line again
            %to draw the first frame again.
            %but: builder.frame_to_draw(1); builder.draw(); will draw the
            %first frame and display it. running draw again immedeatly after will draw and
            %save all the frames in the output folder *without displaying*
            obj.frame_to_draw_= frame_to_draw;
        end

        function obj = output_folder(obj, output_folder)
            %OUTPUT_FOLDER sets the output folder for images that draw
            %produces as well as current builder (type: ImageBuilder) that
            %saved using saveBuilder;
            obj.output_folder_= output_folder;
        end
    end

    methods (Access=private)
        function saveFigure(obj, figure, frame_num, xlims, ylims)
            frame=obj.data_{1}(frame_num);
            name=frame.frame_name;
            fname = fullfile(obj.output_folder_, sprintf("%s.%s",name,obj.save_format_));
            xlim(xlims);
            ylim(ylims);
            switch obj.save_format_
                case "png"
                    if(obj.image_data.getShowColorbar || obj.image_data.getImageTitle~="")
                        exportgraphics(figure,fname,'Resolution',600)
                        return;
                    end
                    ax=findall(figure,'type','axes');
                    frame=getframe(ax);
                    image=frame.cdata;
                    image=obj.fixBorders(image);
                    [rows ,cols, ~]=size(image);
                    if([rows, cols]~=obj.data_{1}(1).experiment.image_size_)
                        obj.logger.warn("The resolution of your screen is not enough so image will be rescaled, you might see some distortion");
                        image = imresize(image, obj.data_{1}(1).experiment.image_size_, 'bilinear');
                    end
                    imwrite(image, fname);
                case "fig"
                    set(gcf,'visible','on');
                    savefig(figure, fname)
            end
        end
        function fig = drawFrame(obj, frame, show_figures, frame_num)
            fig=figure;
            if(~show_figures)
                set(gcf,'visible','off');
            end
            if(isempty(obj.image_data_.getBackgroundImage())) %if the marker layer is the only layer then there must be a background image
                background=obj.createBackground(obj.data_{1}(1).experiment.image_size_, obj.image_data_.getColorForNaN());
            else
                background=obj.image_data_.getBackgroundImage();
                if(obj.image_data_.getIsBackgroundPerFrame())
                    background=background{frame_num};
                end
            end
            imshow(background);
            %axis off;

            hold on;
            [row, ~]=size(frame);
            for i = 1 : row
                obj.drawLayer(frame{i}, i);
                if i == row
                    hold off;
                end
            end
            set(0, 'CurrentFigure', fig);
            title(obj.image_data_.getImageTitle());
            if(obj.image_data_.getLegendForMarkers())
                legend;
            end
        end

        function drawLayer(obj, layer, layer_num)
            if(isempty(layer))
                return;
            end
            layer_data=obj.layers_data_{layer_num};
            if(~layer_data.getShow())
                return;
            end
            type=layer_data.getType();
            switch type
                case obj.image_type
                    obj.drawImageLayer(layer, layer_num);
                case obj.marker_type
                    obj.drawMarkerLayer(layer, layer_num);
                case obj.quiver_type
                    obj.drawQuiverLayer(layer, layer_num);
            end
        end

        function drawMarkerLayer(obj, layer, layer_num)
            layer_data=obj.layers_data_{layer_num};
            x=layer(:,1);
            y=layer(:, 2);
            value=layer(:,3);
            if isempty(layer_data.getScale())
                mi=min(value);
                ma=max(value);
                scale=[mi ma];
                scale(isnan(scale))=0;
                layer_data.setScale(scale);
            end
            if(layer_data.getMarkersSizeByValue())
                marker_size=value;
                marker_size(marker_size==0)=nan;
                marker_size=marker_size.*layer_data.getMarkersSize();
            else
                marker_size=ones(size(value)).*layer_data.getMarkersSize();
            end
            if(layer_data.getMarkersColorByValue())
                s=scatter(x,y, marker_size, "CData" , value);
                colormap(layer_data.getColormap());
                if(obj.image_data.getShowColorbar && layer_data.getColorbar)
                    freezeColors(colorbar);
                    try
                        caxis(layer_data.getScale);
                    catch
                    end
                end
                freezeColors;
            else
                s=scatter(x,y, marker_size, layer_data.getMarkersColor());
            end
            s.Marker=layer_data.getMarkersShape();
            s.LineWidth=layer_data.getLineWidth();
            s.MarkerEdgeAlpha=layer_data.getOpacity();
            s.MarkerFaceAlpha=layer_data.getOpacity();
        end

        function drawQuiverLayer(obj, layer, layer_num)
            layer_data=obj.layers_data_{layer_num};
            x=layer(:,1);
            y=layer(:, 2);
            rad=layer(:,3);
            length=layer(:,4);
            if(layer_data.getMarkersSizeByValue())
                q=layer_data.getMarkersSize();
                size_q=length.*q;
            else
                q=layer_data.getMarkersSize();
                size_q=ones(size(length)).*q;
            end
            [u,v]=pol2cart(rad,size_q);
            x=x-u./2;
            y=y-v./2;
            q=quiver(x,y,u,v, layer_data.getMarkersColor());
            q.LineWidth=layer_data.getLineWidth();
            q.AutoScale="off";
            if(layer_data.getQuiverShowArrowHead())
                q.ShowArrowHead="on";
            else
                q.ShowArrowHead="off";
            end
        end

        function [xlims,ylims]= getAxisLims(obj)
            [~, col]=size(obj.layer_arr_);
            if(~isempty(obj.image_data.getCropCenterPoint))
                max_length=obj.image_data.getCropSize;
                center=obj.image_data.getCropCenterPoint;
            else
                mask=[];
                for i= 1:col
                    frame_data=obj.data_{1}(i);
                    new_mask=obj.fixImageAxes(frame_data.mask);
                    if(isempty(mask))
                        mask=new_mask;
                    else
                        mask=mask+new_mask;
                    end
                end
                [x,y]=find(mask);
                lengths=[abs(max(x)-min(x)),abs(max(y)-min(y))];
                center=[(max(x)+ min(x))/2, (max(y)+ min(y))/2];
                max_length=max(lengths)+obj.image_data.getCropSize;
            end
            xlims = [center(1)-max_length/2,center(1)+max_length/2 ];
            ylims = [center(2)-max_length/2,center(2)+max_length/2 ];
        end

        function drawImageLayer(obj, layer, layer_num)
            layer_data=obj.layers_data_{layer_num};
            if isempty(layer_data.getScale())
                mi=min(layer(:));
                ma=max(layer(:));
                scale=[mi ma];
                scale(isnan(scale))=0;
                layer_data.setScale(scale);
            end
            layer=obj.fixImageAxes(layer);
            image=mat2gray(layer, layer_data.getScale());
            ind=gray2ind(image, 256);
            if(layer_data.getIsSolidColor())
                image=obj.createBackground(obj.data_{1}(1).experiment.image_size_,layer_data.getSolidColor());
            else
                image=ind2rgb(ind, colormap(layer_data.getColormap()));
                if(obj.image_data.getShowColorbar && layer_data.getColorbar)
                    freezeColors(colorbar);
                    try
                        caxis(layer_data.getScale);
                    catch
                    end
                end
            end
            %creates the image
            alpha_mask=zeros(size(layer));
            alpha_mask(~isnan(layer)) = 1; %creates regular mask
            if(~isempty(layer_data.getDialation))
                %                 se=strel('line',layer_data.getDialation,0);
                %                 alpha_mask=imdilate(alpha_mask,se);
            end
            alpha_mask=alpha_mask.*layer_data.getOpacity();
            layer_im = imshow(image);
            layer_im.AlphaData = alpha_mask;
            freezeColors;
        end

        function image = fixImageAxes(~, im)
            fliplr(im);
            image=im';
        end

        function back_image = createBackground(~, size, color)
            back_image = ones(size);
            for i = 1:3
                back_image(:,:,i)=color(i);
            end
        end
        function image = fixBorders(obj, image)
            [rows ,cols, ~]=size(image);
            border_color=[240 240 240];
            if(image(1,2,:)==border_color)
                image(1,:, :)=[];
            end
            if(image(end, 2, :)==border_color)
                image(end,:, :)=[];
            end
            if(image(2,1, :)==border_color)
                image(:,1, :)=[];
            end
            if(image(2,end, :)==border_color)
                image(:,end, :)=[];
            end

        end

        function s = getBackgroundSize(obj, frame)
            [row, ~]=size(frame); 
            for i = 1:row
                layer_data=obj.layers_data_{i};
                if(~isempty(frame) && layer_data.getType()==obj.image_type)
                    s=size(frame{i});
                    return;
                end
            end
            obj.logger.error('your layer_arr only contains markers. If you want to draw the image you need to add either image layer or background!');
        end
    end
end