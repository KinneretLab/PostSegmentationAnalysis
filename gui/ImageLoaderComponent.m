classdef ImageLoaderComponent < handle
    %IMAGELOADERCOMPONENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        image_component_handler_
        image_builder_
        background_image_={}
        status_table_
        is_image_loaded_=false;
    end
    
    methods (Access=public)
        function obj = ImageLoaderComponent(imageCompHandler,imageBuilder)
            obj.image_component_handler_=imageCompHandler;
            obj.image_builder_=imageBuilder;
            obj.status_table_=obj.createDefualtTable;
        end
        
        function showLoadedData(obj, app)
            app.DrawButton_2.Enable=false;
            app.DrawButton_2.Text="Drawing..";
            if(obj.is_image_loaded_)
                obj.image_component_handler_.show(app);
            end
            app.DrawButton_2.Enable=true;
            app.DrawButton_2.Text="Draw";
        end
        
        function loadImageData(obj, app) %add joint support for load images
            [f, p] = uigetfile();
            
            %Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
                fname = [p f];
            end
            obj.image_builder_.load(p, f);
            if(~isempty(obj.background_image_))
                obj.image_builder_.image_data_.setBackgroundImage(obj.background_image_);
            end
            obj.is_image_loaded_=true;
            app.DrawButton_2.Enable=true;
            obj.status_table_{1,2}="Loaded";
            updateStatusTable(obj,app);
        end
        
        
        function loadBackground(obj, app) %TODO: move extensions to config
%             [file,path] = uigetfile('*.png;*.tiff;*.jpg;*.jpeg', 'Select One or More Files', ...
%                 'MultiSelect', 'on');
%             if(isa(file,'char'))
%                  fname = [path file];
%                  obj.background_image_=imread(fname);
%             else
%                 [~ ,num_of_files]=size(file);
%                 for i= 1:num_of_files
%                     fname = [path file{i}];
%                     obj.background_image_{i}=imread(fname);
%                 end
%             end
            obj.background_image_=Utilities.getBackground;
            if(obj.is_image_loaded_)
                obj.image_builder_.image_data_.setBackgroundImage(obj.background_image_);
            end
            obj.status_table_{2,2}="Loaded";
            [row ,num_of_files]=size(obj.background_image_);
            if(row==1)
                obj.status_table_{2,3}=num_of_files;
            else
                obj.status_table_{2,3}="All Frames";
            end
            updateStatusTable(obj,app);
        end
        
        function updateStatusTable(obj,app)
           app.UITable.Data=obj.status_table_;
        end
    end
    
    methods (Static)
        function t=createDefualtTable()
            object=["Image";"Background"];
            status=["Not Loaded"; "Not Loaded"];
            numberOfFrames=[""; "Unknown"];
            t=table(object,status, numberOfFrames);
        end
    end
    
    
    
end

