classdef ImageLoaderComponent < handle
    %IMAGELOADERCOMPONENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        image_component_handler_
        image_builder_
    end
    
    methods (Access=public)
        function obj = ImageLoaderComponent(imageCompHandler,imageBuilder)
            obj.image_component_handler_=imageCompHandler;
            obj.image_builder_=imageBuilder;
        end 
        
        function loadImageData(obj, app) %add joint support for load images
            [f, p] = uigetfile();
            
            %Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
                fname = [p f];
            end
            obj.image_builder_.load(p, f);
            %obj.ImageComponentHandler.addImage(app,imageRawData);
            obj.image_component_handler_.show(app);
        end
    end
    

end

