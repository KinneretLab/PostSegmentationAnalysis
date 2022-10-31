classdef ImageBuilder <  FigureBuilder & handle
    
    properties (Access = protected)
        
        xy_calibration_         % double
        z_calibration_          % double
        image_size_             % double array
        data_                   % {obj array...}
        layer_arr_              % cell array of double arrays
        save_format_
    end
    
    properties (Access = public)
        
        layers_data_
        image_data_
    end
    
    methods
        
        function obj = ImageBuilder(matlab_utility_funcs_path)
            obj@FigureBuilder()
            
            obj.xy_calibration_         = 1;
            obj.z_calibration_           = 1;
            obj.image_size_              = [];
            obj.data_                    = {};
            layers_data_                 = {};
            image_data_                   = ImageDrawData;
            addpath(matlab_utility_funcs_path); 
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
        
        function this_funct = objFunction(func)
            if isa(func, 'char') || isa(func, 'string')
                this_funct = ImageBuilder.property(func);
            end
            if isa(func, 'double')
                this_funct = @(obj) (func);
            end
            if isa(func, 'function_handle')
                this_funct = func;
            end
        end
        
        function filter_fun = filterFunction(func)
            % FILTERFUNCTION Add a filter to apply on the data before starting the calculation at all.
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
                filter_fun = ImageBuilder.logical(true);
            else
                if isa(func, 'char') || isa(func, 'string')
                    if ~contains(func, "obj_arr")
                        warning("[WARN] your filter string does not contain obj_arr. This probably will lead to errors.");
                    end
                    if ~contains(func, "[")
                        warning("[WARN] your filter string does not contain square brackets for working on array. This probably will lead to errors.");
                    end
                    filter_fun = @(obj_arr) (eval(func)); % WARNING: do NOT rename obj_arr!
                end
                if isa(func, 'logical') || isa(func, 'double')
                    filter_fun = PlotBuilder.logical(logical(func));
                end
                if isa(func, 'function_handle') || isa(func, 'BulkFunc')
                    filter_fun = func;
                end
            end
        end
        
    end
    
    
    methods
        
        % This function arranges the data according to the desired layers,
        % to later be converted into graphical representation. MORE
        % DETAILED EXPLANATION TO BE ADDED
        function [layer_arr] = calculate(obj,class_list,filter_list,value_fun_list,type_list,calibration_list, varargin)
            
            % Initiate output array
            layer_arr = {};
            
            % Run over list of layers to calculate
            for i= 1:length(class_list)
                
                frame_arr = obj.data_{:};
                
                for j = 1:length(frame_arr)
                    % Get data arrays for frame, apply filter
                    phys_arr = frame_arr(j).(class_list{i});
                    
                    % Apply filter to each entity
                    
                    filter_fun = ImageBuilder.filterFunction(filter_list{i});
                    filtered_arr =  phys_arr(filter_fun(phys_arr));
                    
                    % Get value for each object using the specified value
                    % function for this layer.
                    value_fun = ImageBuilder.objFunction(value_fun_list{i});
                    value_arr = arrayfun(value_fun,filtered_arr);
                    
                    
                    % Option for normalization by frame average
                    %                     norm_fun = plotUtils.xNormalize(value_fun_list{i},"frame");
                    % NEED TO UNDERSTAND WHAT THIS RUNS ON, AND IN WHAT
                    % ORDER TO APPLY FILTERING AND CALCULATING VALUE.
                    
                    % Apply calibration to values if specified (to convert
                    % pixels to microns)
                    if exist('calibration_list')
                        if strcmp(calibration_list{i}{1},'xy')
                            value_arr = value_arr*(obj.xy_calibration_^(calibration_list{i}{2}));
                            
                        else if strcmp(calibration_list{i}{1},'z')
                                value_arr = value_arr*(obj.z_calibration_^(calibration_list{i}{2}));
                            end
                        end
                    end
                    
                    % NEED TO ADD OPTIONS FOR CALIBRATION
                    
                    if strcmp(type_list{i},'image')
                        
                        image_size = obj.image_size_; % GET THIS FROM EXPERIMENT INFO, NEED TO IMPLEMENT THIS
                        
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
                        
                        % TEMPORARILY HERE
                        permuteMap = permute(this_im,[2 1]);
                        imshow(permuteMap,[])
                        colormap jet
                        pause(1)
                        
                    elseif strcmp(type_list{i},'list')
                        
                        % Get relevant pixels (the function list_pixels is
                        % implemented in every relevant class). For cells,
                        % this is the centre of the cell, for bonds the
                        % middle point of the bond, and for vertices it is
                        % the vertex location.
                        list_pixels = filtered_arr.list_pixels;
                        this_list = [list_pixels,value_arr'];
                        layer_arr{i,j} = this_list;
                    else
                        disp(sprintf('Typelist needs to specify image or list'));
                    end
                    
                end
            end
            obj.layer_arr_=layer_arr;
            obj.createDefaultLayerData(); % TODO see if needs to run here or where, or if it is only run by user...
        end
        
        function obj=createDefaultLayerData(obj) % TODO see if add if override version, in case we want to load or calculate different data..
            obj.layers_data_={};
            [row, col]=size(obj.layer_arr_);
            for i=1:row
                obj.layers_data_{i} = ImageLayerDrawData;
                j=1;
                frame = obj.layer_arr_(:, j);
                while isempty(frame{i}) && j<=col
                    j=j+1;
                    frame = obj.layer_arr_(:, j);
                end
                obj.layers_data_{i}.setIsMarkerLayer(obj.isMarkerLayer(frame{i}));
                obj.layers_data_{i}.setIsMarkerQuiver(obj.isMarkerQuiver(frame{i}));               
%                 frame = obj.layer_arr_(:, 1);
%                 obj.layers_data_{i}.setIsMarkerLayer(obj.isMarkerLayer(frame{i}));
%                 obj.layers_data_{i}.setIsMarkerQuiver(obj.isMarkerQuiver(frame{i}));               
            end
        end
        
        function obj = load(obj, path, file_name) %todo maybe add option to if dispose of layer and image data
            fname = fullfile(path, file_name);
            struct = load(fname);
            fieldNames = fieldnames(struct);
            obj.layer_arr_ = getfield(struct, fieldNames{1});
            obj.createDefaultLayerData(); % TODO see if needs to run here or where, or if it is only run by user...

            obj.image_data_=ImageDrawData;
        end
        
        function save(~, figures, path, file_name)
            [~, col]=size(figures);
            for i = 1:col
                fname = fullfile(path, sprintf("%s%d.png",file_name,i));
                figure=figures{i};
                figure=tightfig(figure);
                saveas(figure, fname);
                %TODO make sure that at some point figures are closed...
            end
        end
        
        function figures = draw(obj, show_figures) %returns as many figures as there are frames, add order of layers
            [~, col]=size(obj.layer_arr_); 
            figures = {};
            for i= 1 : col
                frame = obj.layer_arr_(:, i);
                figures{i} = obj.drawFrame(frame, show_figures, i);
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
            if(~layer_data.getIsMarkerLayer() && ~layer_data.getIsMarkerQuiver())
                obj.drawImageLayer(layer, layer_num, fig);                
            elseif(layer_data.getIsMarkerLayer())
                obj.drawMarkerLayer(layer, layer_num);
            else
                obj.drawQuiverLayer(layer, layer_num);
            end
        end
        
        function drawMarkerLayer(obj, layer, layer_num)
            layer_data=obj.layers_data_{layer_num};
            x=layer(:,1);
            y=layer(:, 2);
            value=layer(:,3);
            rescaled_value=rescale(value);
            if(layer_data.getMarkersSizeByValue())
                marker_size=rescaled_value;
                marker_size(marker_size==0)=nan;
                marker_size=marker_size.*layer_data.getMarkersSize();
            else
                marker_size=ones(size(value)).*layer_data.getMarkersSize();
            end
            if(layer_data.getMarkersColorByValue())
                s=scatter(x,y, marker_size, "CData" , rescaled_value);
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
                size_q=rescale(length).*q;
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
            alpha_mask=alpha_mask.*layer_data.getOpacity();
            layer_im = imshow(image);
            layer_im.AlphaData = alpha_mask;
        end
        
        function is_marker = isMarkerLayer(~, layer)
            [~, col]=size(layer);
            if(col==3)
                is_marker=true;
            else
                is_marker=false;
            end
        end
        
        function is_marker_quiver = isMarkerQuiver(~, layer)
            [~, col]=size(layer);
            if(col==4)
                is_marker_quiver=true;
            else
                is_marker_quiver=false;
            end
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
                if(~isempty(frame) && ~layer_data.getIsMarkerLayer() && ~layer_data.getIsMarkerQuiver())
                    s=size(frame{i});
                    return;
                end
            end
            error("[ERROR] your layer_arr only contains markers. If you want to draw the image you need to add either image layer or background!");
        end
        
        function obj = addData(obj, frame_arr)
            if ~strcmp(class(frame_arr),'Frame')
                disp(sprint('Data must be an object or array of class frame'));
            else
                obj.data_{1} = frame_arr;
            end
        end
        
        function obj = image_size(obj,im_size)
            obj.image_size_ = im_size;
        end
        function obj = xyCalibration(obj, calib)
            % XYCALIBRATION Micron to pixel calibration for the xy plane of
            % the image.
            % Parameters:
            %   calib: double
            %      the scaling value to multiply the values by. That is,
            %      final_value = calib * pixel_value;
            obj.xy_calibration_ = calib;
        end
        
        function obj = zCalibration(obj, calib)
            % ZCALIBRATION Micron to pixel calibration for the z axis of
            % the image stack.
            % Parameters:
            %   calib: double
            %      the scaling value to multiply the values by. That is,
            %      final_value = calib * pixel_value;
            obj.z_calibration_ = calib;
        end
        
        
    end
    
    
end