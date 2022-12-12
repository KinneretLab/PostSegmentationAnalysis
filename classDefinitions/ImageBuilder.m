classdef ImageBuilder <  FigureBuilder & handle
    
    properties (Access = protected)
        data_ = {};                  % {obj array...}
        layer_arr_   = {};           % cell array of double arrays
        save_format_ = "png";
        frame_to_draw_ = [];
        output_folder_="";
        layers_data_ = {};
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
            search_path = '../*/matlab-utility-functions';
            while isempty(dir(search_path))
                search_path = ['../', search_path];
            end
            addpath(dir(search_path).folder)
            search_path = '../*/freezeColors';
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

    methods
        
        % This function arranges the data according to the desired layers,
        % to later be converted into graphical representation. MORE
        % DETAILED EXPLANATION TO BE ADDED
        function [obj,layer_arr] = calculate(obj)
            
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
        
        function saveFigure(obj, figure, frame_num, xlims, ylims)
            frame=obj.data_{1}(frame_num);
            name=frame.frame_name;
            fname = fullfile(obj.output_folder_, sprintf("%s.%s",name,obj.save_format_));
            xlim(xlims);
            ylim(ylims);
            switch obj.save_format_
                case "png"
                    if(obj.image_data.getShowColorbar)
                        exportgraphics(figure,fname,'Resolution',600)
                        return;
                    end
                    ax=findall(figure,'type','axes');
                    frame=getframe(ax);
                    image=frame.cdata;
                    image=obj.fixBorders(image);
                    imwrite(image, fname);
                case "fig"
                    set(gcf,'visible','on');
                    savefig(figure, fname)
            end
        end

        function image = fixBorders(obj, image)
            [rows ,cols, ~]=size(image);
            if([rows, cols]~=obj.data_{1}(1).experiment.image_size_)
                image(end,:, :)=[];
                image(1,:, :)=[];
                image(:,1, :)=[];
            end
        end

        function loadBuilder(obj, input)
            load(input, 'saved_builder');
            obj.layer_arr_=saved_builder.layer_arr;
            obj.data_=saved_builder.data;
            obj.image_data_=saved_builder.image_data;
            obj.layers_data_=saved_builder.layers_data;
        end

        function obj= saveBuilder(obj, file_name)
            saved_builder=obj;
            save(fullfile(obj.output_folder_, file_name), 'saved_builder');
        end
        
        function figures = draw(obj, input) 
            if(nargin==1)
                input=[];
            end
            if(isempty(input))
                if(isempty(obj.layer_arr_))
                    obj.calculate;
                end
            else
                obj.loadBuilder(input);
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
                return;
            end
            for i= 1 : col
                frame = obj.layer_arr_(:, i);
                fig=obj.drawFrame(frame, false, i);
                obj.saveFigure(fig, i, xlims, ylims);
                close(fig);
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
            if(layer_data.getMarkersSizeByValue())
                marker_size=value;
                marker_size(marker_size==0)=nan;
                marker_size=marker_size.*layer_data.getMarkersSize();
            else
                marker_size=ones(size(value)).*layer_data.getMarkersSize();
            end
            if(layer_data.getMarkersColorByValue())
                s=scatter(x,y, marker_size, "CData" , value);
                colormap(gca, layer_data.getColormap());
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
                layer_data.setScale([mi ma]);
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
                    caxis(layer_data.getScale);
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
        
        function obj = addData(obj, frame_arr)
            if ~strcmp(class(frame_arr),'Frame')
                disp(sprint('Data must be an object or array of class frame'));
            else
                obj.data_{1} = frame_arr;
            end
        end

        function obj = save_format(obj,format)
            obj.save_format_ = format;
        end
        
        function layer_data=layers_data(obj, layer_num, data)
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
            if(isempty(obj.image_data_))
                obj.image_data_=ImageDrawData(obj);
            end
            image_data = obj.image_data_;
        end

        function layer_arr = layer_arr(obj)
            layer_arr = obj.layer_arr_;
        end

        function data = data(obj)
            data = obj.data_;
        end

        function obj = frame_to_draw(obj, frame_to_draw)
            obj.frame_to_draw_= frame_to_draw;
        end

        function obj = builder_file_name(obj, builder_file_name)
            obj.builder_file_name_= builder_file_name;
        end

        function obj = output_folder(obj, output_folder)
            obj.output_folder_= output_folder;
        end
    end  
end