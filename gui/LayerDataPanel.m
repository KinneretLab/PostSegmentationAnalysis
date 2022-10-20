classdef LayerDataPanel<handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        grid_
        image_component_handler_
        ShowCheckBox
        ColormapDropDownLabel
        ColormapDropDown
        ScaleGrid
        ScaleMax
        ScaleMin
        ScaleLabel
        ColorLabel
        FillCheckBox
        ColorGrid
        RValue
        BValue
        GValue
        OpacitySpinnerLabel
        OpacitySpinner
        TypeLabel
        Type
    end
    
    methods
        function obj = LayerDataPanel(grid, image_component_handler)
            obj.grid_=grid;
            obj.image_component_handler_=image_component_handler;
            obj.createImageLayerData();
            obj.hideImageLayerPanel();
        end
        
        function create(obj, layer_data)
            obj.hideImageLayerPanel();
            if(~layer_data.getIsMarkerLayer() && ~layer_data.getIsMarkerQuiver())
                obj.showImageLayerPanel();
                obj.setImageLayerSettings(layer_data);
            end
        end
        
        function showImageLayerPanel(obj)
            obj.ShowCheckBox.Parent=obj.grid_;
            obj.ShowCheckBox.Layout.Row = 2;
            obj.ShowCheckBox.Layout.Column = 1;
            
            obj.ColormapDropDownLabel.Parent=obj.grid_;
            obj.ColormapDropDownLabel.Layout.Row = 4;
            obj.ColormapDropDownLabel.Layout.Column = 1;
            
            obj.ColormapDropDown.Parent=obj.grid_;
            obj.ColormapDropDown.Layout.Row = 4;
            obj.ColormapDropDown.Layout.Column = 2;
            
            obj.ScaleGrid.Parent=obj.grid_;
            obj.ScaleGrid.Layout.Row = 3;
            obj.ScaleGrid.Layout.Column = 2;
            
            obj.ScaleMin.Parent=obj.ScaleGrid;
            obj.ScaleMin.Layout.Row = 1;
            obj.ScaleMin.Layout.Column = 1;
            
            obj.ScaleMax.Parent=obj.ScaleGrid;
            obj.ScaleMax.Layout.Row = 1;
            obj.ScaleMax.Layout.Column = 2;
            
            obj.ScaleLabel.Parent = obj.grid_;
            obj.ScaleLabel.Layout.Row = 3;
            obj.ScaleLabel.Layout.Column = 1;
            
            obj.ColorLabel.Parent = obj.grid_;
            obj.ColorLabel.Layout.Row = 6;
            obj.ColorLabel.Layout.Column = 1;
            
            obj.FillCheckBox.Parent = obj.grid_;
            obj.FillCheckBox.Layout.Row = 5;
            obj.FillCheckBox.Layout.Column = [1 2];
            
            obj.ColorGrid.Parent = obj.grid_;
            obj.ColorGrid.Layout.Row = 6;
            obj.ColorGrid.Layout.Column = 2;
            
            obj.RValue.Parent = obj.ColorGrid;
            obj.RValue.Layout.Row = 1;
            obj.RValue.Layout.Column = 1;
            
            obj.GValue.Parent = obj.ColorGrid;
            obj.GValue.Layout.Row = 1;
            obj.GValue.Layout.Column = 2;
            
            obj.BValue.Parent = obj.ColorGrid;
            obj.BValue.Layout.Row = 1;
            obj.BValue.Layout.Column = 3;
            
            obj.OpacitySpinnerLabel.Parent = obj.grid_;
            obj.OpacitySpinnerLabel.Layout.Row = 7;
            obj.OpacitySpinnerLabel.Layout.Column = 1;
            
            obj.OpacitySpinner.Parent = obj.grid_;
            obj.OpacitySpinner.Layout.Row = 7;
            obj.OpacitySpinner.Layout.Column = 2;
            
            obj.TypeLabel.Parent = obj.grid_;
            obj.TypeLabel.Layout.Row = 1;
            obj.TypeLabel.Layout.Column = 1;
            
            obj.Type.Parent = obj.grid_;
            obj.Type.Layout.Row = 1;
            obj.Type.Layout.Column = 2;
        end
        
        function hideImageLayerPanel(obj)
            obj.ShowCheckBox.Parent=[];
            obj.ColormapDropDownLabel.Parent=[];
            obj.ColormapDropDown.Parent=[];
            obj.ScaleGrid.Parent=[];
            obj.ScaleMin.Parent=[];
            obj.ScaleMax.Parent=[];
            obj.ScaleLabel.Parent = [];
            obj.ColorLabel.Parent = [];
            obj.FillCheckBox.Parent = [];
            obj.ColorGrid.Parent = [];
            obj.RValue.Parent = [];
            obj.GValue.Parent = [];
            obj.BValue.Parent = [];
            obj.OpacitySpinnerLabel.Parent = [];
            obj.OpacitySpinner.Parent = [];
            obj.TypeLabel.Parent = [];
            obj.Type.Parent = [];
        end
        
        function createImageLayerData(obj)
            obj.ShowCheckBox=uicheckbox(obj.grid_);
            obj.ColormapDropDownLabel=uilabel(obj.grid_);
            obj.ColormapDropDown = uidropdown(obj.grid_);
            obj.ScaleGrid = uigridlayout(obj.grid_);
            obj.ScaleMin = uieditfield(obj.ScaleGrid, 'numeric');
            obj.ScaleMax = uieditfield(obj.ScaleGrid, 'numeric');
            obj.ScaleLabel = uilabel(obj.grid_);
            obj.ColorLabel = uilabel(obj.grid_);
            obj.FillCheckBox = uicheckbox(obj.grid_);
            obj.ColorGrid = uigridlayout(obj.grid_);
            obj.RValue = uispinner(obj.ColorGrid);
            obj.GValue = uispinner(obj.ColorGrid);
            obj.BValue = uispinner(obj.ColorGrid);
            obj.OpacitySpinnerLabel = uilabel(obj.grid_);
            obj.OpacitySpinner = uispinner(obj.grid_);
            obj.TypeLabel = uilabel(obj.grid_);
            obj.Type = uilabel(obj.grid_);
            obj.grid_.RowHeight={'1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            obj.ShowCheckBox.Text = 'Show';
            obj.ColormapDropDownLabel.Text = 'Colormap';
            obj.ScaleGrid.RowHeight = {'1x'};
            obj.ScaleLabel.Text = 'Scale';
            obj.ColorLabel.Text = 'Color';
            obj.FillCheckBox.Text = 'Fill';
            obj.ColorGrid.ColumnWidth = {'1x', '1x', '1x'};
            obj.ColorGrid.RowHeight = {'1x'};
            obj.RValue.Step = 0.1;
            obj.RValue.Limits = [0 1];
            obj.GValue.Step = 0.1;
            obj.GValue.Limits = [0 1];
            obj.BValue.Step = 0.1;
            obj.BValue.Limits = [0 1];
            obj.OpacitySpinnerLabel.Text = 'Opacity';
            obj.OpacitySpinner.Limits = [0 1];
            obj.OpacitySpinner.Step =0.1;
            obj.TypeLabel.Text = 'Type';
            obj.Type.Text = 'Image';
        end
        
        function setImageLayerSettings(obj, layer_data)
            obj.ShowCheckBox.Value=layer_data.getShow();
            scale=layer_data.getScale();
            obj.ScaleMax.Value=scale(2);
            obj.ScaleMin.Value=scale(1);
            obj.FillCheckBox.Value=layer_data.getIsSolidColor();
            color=layer_data.getSolidColor();
            obj.RValue.Value=color(1);
            obj.GValue.Value=color(2);
            obj.BValue.Value=color(3);
            obj.OpacitySpinner.Value=layer_data.getOpacity();
        end
        
        function layer_data =getLayerData(obj, layer_data)
            if(~layer_data.getIsMarkerLayer() && ~layer_data.getIsMarkerQuiver())
                layer_data=obj.getImageLayerSettings(layer_data);
            end
        end
        
        function layer_data = getImageLayerSettings(obj, layer_data)
            layer_data.setShow(obj.ShowCheckBox.Value);
            layer_data.setScale([obj.ScaleMin.Value obj.ScaleMax.Value]);
            layer_data.setIsSolidColor(obj.FillCheckBox.Value);
            layer_data.setSolidColor([obj.RValue.Value obj.GValue.Value obj.BValue.Value] );
            layer_data.setOpacity(obj.OpacitySpinner.Value);
        end
    end
end

