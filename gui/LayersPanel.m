classdef LayersPanel <handle
    
    properties (Access=private)
        grid_
        image_component_handler_
        default_shown_layer_=1
        Buttons = {}
    end
    
    methods
        function obj = LayersPanel(grid, image_component_handler)
            %LAYERSPANEL Construct an instance of this class
            %   Detailed explanation goes here
            obj.grid_=grid;
            obj.image_component_handler_=image_component_handler;
        end
        
        function create(obj, layers_data)
            [~, num_layers]=size(layers_data);
            for i=1:num_layers
                obj.grid_.RowHeight{i} = '1x';
                obj.Buttons{i}=uibutton(obj.grid_, 'push');
                obj.Buttons{i}.HorizontalAlignment = 'left';
                obj.Buttons{i}.Layout.Row = i;
                obj.Buttons{i}.UserData=i;
                obj.Buttons{i}.Layout.Column = 1;
                obj.Buttons{i}.Text = sprintf("Layer %d", i);
                obj.Buttons{i}.ButtonPushedFcn=@obj.changedLayer;
            end
            obj.setShownLayer(obj.default_shown_layer_);
        end
        
        function changedLayer(obj,event,~)
            num=event.UserData;
            obj.image_component_handler_.changeLayer(num);
            obj.resetShownLayer();
            obj.setShownLayer(num);
        end
        
        function setShownLayer(obj, layer_num)
            obj.Buttons{layer_num}.FontWeight='bold';
        end
        
        function resetShownLayer(obj)
            [~, col]=size(obj.Buttons);
            for i= 1:col
                obj.Buttons{i}.FontWeight='normal';
            end
        end
    end
end

