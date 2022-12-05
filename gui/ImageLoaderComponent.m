classdef ImageLoaderComponent < handle
    %IMAGELOADERCOMPONENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        image_component_handler_
        image_builder_
        background_image_={}
%         status_table_
        is_image_loaded_=false;
        app_
    end
    
    methods (Access=public)
        function obj = ImageLoaderComponent(app, imageCompHandler,imageBuilder)
            obj.image_component_handler_=imageCompHandler;
            obj.image_builder_=imageBuilder;
%             obj.status_table_=obj.createDefualtTable;
            obj.app_=app;
        end
        
        function loadImageBuilder(obj) %add joint support for load images
            [f, p] = uigetfile();
            
            %Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
                fname = fullfile(p, f);
            end
            obj.image_builder_.loadBuilder(fname);
            obj.image_component_handler_.show();
        end
        
        
%         function loadBackground(obj) 
%             obj.background_image_=Utilities.getBackground;
%             if(obj.is_image_loaded_)
%                 obj.image_builder_.image_data_.setBackgroundImage(obj.background_image_);
%             end
%             obj.status_table_{2,2}="Loaded";
%             [row ,num_of_files]=size(obj.background_image_);
%             if(row==1)
%                 obj.status_table_{2,3}=num_of_files;
%             else
%                 obj.status_table_{2,3}="All Frames";
%             end
%             updateStatusTable(obj,obj.app_);
%         end
%         
%         function updateStatusTable(obj)
%            obj.app_.UITable.Data=obj.status_table_;
%         end
    end
    
    methods (Static)
%         function t=createDefualtTable()
%             object=["Image";"Background"];
%             status=["Not Loaded"; "Not Loaded"];
%             numberOfFrames=[""; "Unknown"];
%             t=table(object,status, numberOfFrames);
%         end
    end
    
    
    
end

