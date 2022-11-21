classdef ImageBuilder <  FigureBuilder & handle
    
    properties (Access = protected)
        data_ = {};                  % {obj array...}
        layer_arr_   = {};           % cell array of double arrays
        save_format_ = "png";
        frame_to_draw_ = [];
        output_folder_="";
        builder_file_name_="builder";
    end

    properties (Constant)
        logger = Logger('ImageBuilder');
        image_type="image";
        marker_type="list";
        quiver_type="quiver";
    end
    
    properties (Access = public)
        
        layers_data_ = {};
        image_data_ = ImageDrawData;
    end
    
    methods
        
        function obj = ImageBuilder()
            obj@FigureBuilder()           

            % generic global search for a particular folder; works independent of user
            search_path = '../*/matlab-utility-functions';
            while isempty(dir(search_path))
                search_path = ['../', search_path];
            end
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
                
                for j = 1:length(frame_arr)

                    % Get data arrays for frame, apply filter
                    phys_arr = frame_arr(j).(class);
                    
                    % Apply filter to each entity
                    
                    filtered_arr =  phys_arr(filter_fun(phys_arr));
                    
                    % Get value for each object using the specified value
                    % function for this layer.

                    value_arr = arrayfun(value_fun{1},filtered_arr);
                    
                    
                    % Option for normalization by frame average
                    %                     norm_fun = plotUtils.xNormalize(value_fun_list{i},"frame");
                    % NEED TO UNDERSTAND WHAT THIS RUNS ON, AND IN WHAT
                    % ORDER TO APPLY FILTERING AND CALCULATING VALUE.
                    
                    % Apply calibration to values if specified (to convert
                    % pixels to microns)

                    if exist('calibration_list')
                        if strcmp(calibration_fun{1},'xy')
                            value_arr = value_arr*(obj.image_data.getXYCalibration^(calibration_fun{2}));
                            
                        else if strcmp(calibration_fun{1},'z')
                                value_arr = value_arr*(obj.image_data.getZCalibration^(calibration_fun{2}));
                            end
                        end
                    end
                    if ~isempty(filtered_arr)
                        % NEED TO ADD OPTIONS FOR CALIBRATION

                        if strcmp(type,'image')

                            image_size = obj.image_data_.getImageSize; % GET THIS FROM EXPERIMENT INFO, NEED TO IMPLEMENT THIS

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

                        elseif strcmp(type_list{i},'list')

                            % Get relevant pixels (the function list_pixels is
                            % implemented in every relevant class). For cells,
                            % this is the centre of the cell, for bonds the
                            % middle point of the bond, and for vertices it is
                            % the vertex location.
                            list_pixels = filtered_arr.list_pixels;
                            this_list = [list_pixels,value_arr'];
                            layer_arr{i,j} = this_list;

                        elseif strcmp(type_list{i},'quiver')
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
        
%         function obj = load(obj, path, file_name) 
%             fname = fullfile(path, file_name);
%             struct = load(fname);
%             fieldNames = fieldnames(struct);
%             obj.layer_arr_ = getfield(struct, fieldNames{1});
%             obj.createDefaultLayerData(); % TODO see if needs to run here or where, or if it is only run by user...
% 
%             obj.image_data_=ImageDrawData;
%         end
        
        function saveFigure(obj, figure, frame_num)
            frame=obj.data_{1}(frame_num);
            name=frame.frame_name;
            fname = fullfile(obj.output_folder_, sprintf("%s.%s",name,obj.save_format_));
            figure=tightfig(figure);
            switch obj.save_format_
                case "png"
                    saveas(figure, fname);
                case "fig"
                    savefig(figure, fname)
            end
        end

        function loadBuilder(obj, input)
            load(input, 'saved_builder');
            obj.layer_arr_=saved_builder.layer_arr;
            obj.data_=saved_builder.data;
            obj.image_data_=saved_builder.image_data;
            obj.layers_data_=saved_builder.layers_data;
        end

        function obj= saveBuilder(obj)
            saved_builder=obj;
            save(fullfile(obj.output_folder_, obj.builder_file_name_), 'saved_builder');
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
            if(~isempty(obj.frame_to_draw_))
                frame = obj.layer_arr_(:, obj.frame_to_draw_);
                figures{1} = obj.drawFrame(frame, true, obj.frame_to_draw_);
                obj.frame_to_draw_=[];
                return;
            end
            [~, col]=size(obj.layer_arr_);
            for i= 1 : col
                frame = obj.layer_arr_(:, i);
                fig=obj.drawFrame(frame, false, i);
                obj.saveFigure(fig, i);
                close(fig);
            end
        end
        
        function fig = drawFrame(obj, frame, show_figures, frame_num)
            fig=figure;
            if(~show_figures)
                 set(gcf,'visible','off'); 
            end
            if(isempty(obj.image_data_.getBackgroundImage())) %if the marker layer is the only layer then there must be a background image
                background=obj.createBackground(obj.getBackgroundSize(frame), obj.image_data_.getColorForNaN());
            else
                background=obj.image_data_.getBackgroundImage();
                if(obj.image_data_.getIsBackgroundPerFrame())
                    background=background{frame_num};
                end
            end
            imshow(background);
            hold on;
            [row, ~]=size(frame);
            for i = 1 : row
                obj.drawLayer(frame{i}, i,fig);
                if i == row
                    hold off;
                end
            end
            set(0, 'CurrentFigure', fig);
            title(obj.image_data_.getImageTitle());
            if(obj.image_data_.getLegendForMarkers())
                legend;
            end
            if(obj.image_data_.getShowColorbar())
                cb=colorbar; 
                if(~isempty(obj.image_data_.getColorbarAxisScale()))
                    caxis(obj.image_data_.getColorbarAxisScale());
                end
                cb.Label.String=obj.image_data_.getColorbarTitle();
            end
            
        end
        
        function drawLayer(obj, layer, layer_num, fig)
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
                    obj.drawImageLayer(layer, layer_num, fig);
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
            q.LineWidth=layer_data.getQuiverLineWidth();
            q.AutoScale="off";
            if(layer_data.getQuiverShowArrowHead())
                q.ShowArrowHead="on";
            else
                q.ShowArrowHead="off";
            end
        end
        
        function drawImageLayer(obj, layer, layer_num,fig)
            layer_data=obj.layers_data_{layer_num};
            if isempty(layer_data.getScale()) %TODO:fix because if i want scale to be set dina,ically it only sets it on the first frame!!
                mi=min(layer(:));
                ma=max(layer(:));
                layer_data.setScale([mi ma]);
            end
            fliplr(layer);
            layer=layer';
            image=mat2gray(layer, layer_data.getScale());
            ind=gray2ind(image, 256);
            if(layer_data.getIsSolidColor())
                image=obj.createBackground(size(layer),layer_data.getSolidColor());
            else
                f_temp=figure;
                set(gcf,'visible','off'); 
                image=ind2rgb(ind, colormap(layer_data.getColormap()));
                close(f_temp, "force");
                set(0, 'CurrentFigure', fig);
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
        
        function layer_data=layers_data(obj, layer_num)
            if(nargin==1)
                layer_data=obj.layers_data_;
                return;
            end
            if(length(obj.layers_data_)<layer_num)
               obj.layers_data_{layer_num}=ImageLayerDrawData;
            elseif(isempty(obj.layers_data_{layer_num}))
                obj.layers_data_{layer_num}=ImageLayerDrawData;
            end
            layer_data = obj.layers_data_{layer_num};
        end

        function image_data = image_data(obj)
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