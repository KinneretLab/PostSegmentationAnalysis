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
        ShapeDropDownLabel
        ShapeDropDown
        ColorbyValueCheckBox
        ColorDropDownLabel
        ColorDropDown
        SizeByValueCheckBox
        SizeSpinnerLabel
        SizeSpinner
    end
    
    methods
        function obj = LayerDataPanel(grid, image_component_handler)
            obj.grid_=grid;
            obj.image_component_handler_=image_component_handler;
            obj.createData();
            obj.hide();
        end
        
        function create(obj, layer_data)
            obj.hide();
            if(~layer_data.getIsMarkerLayer() && ~layer_data.getIsMarkerQuiver())
                obj.showImageLayerPanel();
                obj.setImageLayerSettings(layer_data);
            elseif(layer_data.getIsMarkerLayer())
                obj.showMarkerLayerPanel();
                obj.setMarkerLayerSettings(layer_data);
            end
        end
        
        function hide(obj)
            obj.hideImageLayerPanel();
            obj.hideMarkerLayerPanel();
            obj.hideSharedLayerPanel();
        end
        
        function showMarkerLayerPanel(obj)
            obj.grid_.RowHeight = { '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            obj.Type.Text = 'Marker';
            obj.ShowCheckBox.Parent=obj.grid_;
            obj.ShowCheckBox.Layout.Row = 2;
            obj.ShowCheckBox.Layout.Column = 1;
            
            obj.ColormapDropDownLabel.Parent=obj.grid_;
            obj.ColormapDropDownLabel.Layout.Row = 3;
            obj.ColormapDropDownLabel.Layout.Column = 1;
            
            obj.ColormapDropDown.Parent=obj.grid_;
            obj.ColormapDropDown.Layout.Row = 3;
            obj.ColormapDropDown.Layout.Column = 2;
            
            obj.OpacitySpinnerLabel.Parent = obj.grid_;
            obj.OpacitySpinnerLabel.Layout.Row = 4;
            obj.OpacitySpinnerLabel.Layout.Column = 1;
            
            obj.OpacitySpinner.Parent = obj.grid_;
            obj.OpacitySpinner.Layout.Row = 4;
            obj.OpacitySpinner.Layout.Column = 2;
            
            obj.ShapeDropDownLabel.Parent = obj.grid_;
            obj.ShapeDropDownLabel.Layout.Row = 5;
            obj.ShapeDropDownLabel.Layout.Column = 1;
            
            obj.ShapeDropDown.Parent = obj.grid_;
            obj.ShapeDropDown.Layout.Row = 5;
            obj.ShapeDropDown.Layout.Column = 2;
            
            obj.ColorbyValueCheckBox.Parent = obj.grid_;
            obj.ColorbyValueCheckBox.Layout.Row = 6;
            obj.ColorbyValueCheckBox.Layout.Column = 1;
            
            obj.ColorDropDownLabel.Parent = obj.grid_;
            obj.ColorDropDownLabel.Layout.Row = 7;
            obj.ColorDropDownLabel.Layout.Column = 1;
            
            obj.ColorDropDown.Parent = obj.grid_;
            obj.ColorDropDown.Layout.Row = 7;
            obj.ColorDropDown.Layout.Column = 2;
            
            obj.SizeByValueCheckBox.Parent = obj.grid_;
            obj.SizeByValueCheckBox.Layout.Row = 6;
            obj.SizeByValueCheckBox.Layout.Column = 2;
            
            obj.SizeSpinnerLabel.Parent = obj.grid_;
            obj.SizeSpinnerLabel.Layout.Row = 8;
            obj.SizeSpinnerLabel.Layout.Column = 1;
            
            obj.SizeSpinner.Parent = obj.grid_;
            obj.SizeSpinner.Layout.Row = 8;
            obj.SizeSpinner.Layout.Column = 2;
            
            obj.TypeLabel.Parent = obj.grid_;
            obj.TypeLabel.Layout.Row = 1;
            obj.TypeLabel.Layout.Column = 1;
            
            obj.Type.Parent = obj.grid_;
            obj.Type.Layout.Row = 1;
            obj.Type.Layout.Column = 2;
        end
        
        function showImageLayerPanel(obj)
            obj.grid_.RowHeight={'1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            obj.Type.Text = 'Image';
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
        end
        
        function hideMarkerLayerPanel(obj)
            obj.ShapeDropDownLabel.Parent = [];
            obj.ShapeDropDown.Parent = [];
            obj.ColorbyValueCheckBox.Parent = [];
            obj.ColorDropDownLabel.Parent = [];
            obj.ColorDropDown.Parent = [];
            obj.SizeByValueCheckBox.Parent = [];
            obj.SizeSpinnerLabel.Parent = [];
            obj.SizeSpinner.Parent = [];
        end
        
        function hideSharedLayerPanel(obj)
            obj.ShowCheckBox.Parent=[];
            obj.ColormapDropDownLabel.Parent=[];
            obj.ColormapDropDown.Parent=[];
            obj.OpacitySpinnerLabel.Parent = [];
            obj.OpacitySpinner.Parent = [];
            obj.TypeLabel.Parent = [];
            obj.Type.Parent = [];
        end
        
        function createData(obj)
            obj.createSharedLayerData();
            obj.createImageLayerData();
            obj.createMarkerLayerData();
        end
        
        function createSharedLayerData(obj)
            obj.ShowCheckBox=uicheckbox(obj.grid_);
            obj.ColormapDropDownLabel=uilabel(obj.grid_);
            obj.ColormapDropDown = uidropdown(obj.grid_);
            obj.ColormapDropDown.Items=PresetValues.getColormaps;
            obj.OpacitySpinnerLabel = uilabel(obj.grid_);
            obj.OpacitySpinner = uispinner(obj.grid_);
            obj.TypeLabel = uilabel(obj.grid_);
            obj.Type = uilabel(obj.grid_);
            obj.ShowCheckBox.Text = 'Show';
            obj.ColormapDropDownLabel.Text = 'Colormap';
            obj.OpacitySpinnerLabel.Text = 'Opacity';
            obj.OpacitySpinner.Limits = [0 1];
            obj.OpacitySpinner.Step =0.1;
            obj.TypeLabel.Text = 'Type';
            
        end
        
        function createImageLayerData(obj)
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
        end
        
        function createMarkerLayerData(obj)
            obj.ShapeDropDownLabel = uilabel(obj.grid_);
            obj.ShapeDropDown = uidropdown(obj.grid_);
            obj.ColorbyValueCheckBox = uicheckbox(obj.grid_);
            obj.ColorDropDownLabel = uilabel(obj.grid_);
            obj.ColorDropDown = uidropdown(obj.grid_);
            obj.SizeByValueCheckBox = uicheckbox(obj.grid_);
            obj.SizeSpinnerLabel = uilabel(obj.grid_);
            obj.SizeSpinner = uispinner(obj.grid_);
            obj.SizeSpinner.Step =0.1;
            obj.SizeSpinner.Limits =[0 Inf];
            obj.ShapeDropDownLabel.Text = 'Shape';
            obj.ColorbyValueCheckBox.Text = 'Color by Value';
            obj.ColorDropDownLabel.Text = 'Color';
            obj.SizeByValueCheckBox.Text = 'Size By Value';
            obj.SizeSpinnerLabel.Text = 'Size';
            obj.ColorDropDown.Items=PresetValues.getColors;
            obj.ShapeDropDown.Items=PresetValues.getMarkerShapes;
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
            obj.ColormapDropDown.Value=layer_data.getColormap();
        end
        
        function setMarkerLayerSettings(obj, layer_data)
            obj.ShowCheckBox.Value=layer_data.getShow();
            obj.OpacitySpinner.Value=layer_data.getOpacity();
            obj.ColorbyValueCheckBox.Value = layer_data.getMarkersColorByValue();
            obj.SizeByValueCheckBox.Value= layer_data.getMarkersSizeByValue();
            obj.SizeSpinner.Value=layer_data.getMarkersSize();
            obj.ColormapDropDown.Value=layer_data.getColormap();
            obj.ShapeDropDown.Value=layer_data.getMarkersShape();
        end
        
        function layer_data =getLayerData(obj, layer_data)
            if(~layer_data.getIsMarkerLayer() && ~layer_data.getIsMarkerQuiver())
                layer_data=obj.getImageLayerSettings(layer_data);
            elseif(layer_data.getIsMarkerLayer())
                layer_data=obj.getMarkerLayerSettings(layer_data);
            end
        end
        
        function layer_data = getImageLayerSettings(obj, layer_data)
            layer_data.setShow(obj.ShowCheckBox.Value);
            layer_data.setScale([obj.ScaleMin.Value obj.ScaleMax.Value]);
            layer_data.setIsSolidColor(obj.FillCheckBox.Value);
            layer_data.setSolidColor([obj.RValue.Value obj.GValue.Value obj.BValue.Value] );
            layer_data.setOpacity(obj.OpacitySpinner.Value);
            layer_data.setColormap(obj.ColormapDropDown.Value);
        end
        
        function layer_data= getMarkerLayerSettings(obj, layer_data)
            layer_data.setShow(obj.ShowCheckBox.Value);
            layer_data.setOpacity(obj.OpacitySpinner.Value);
            layer_data.setMarkersColorByValue(obj.ColorbyValueCheckBox.Value);
            layer_data.setMarkersSizeByValue(obj.SizeByValueCheckBox.Value);
            layer_data.setMarkersSize(obj.SizeSpinner.Value);
            layer_data.setColormap(obj.ColormapDropDown.Value);
            layer_data.setMarkersShape(obj.ShapeDropDown.Value);
            layer_data.setColormap(obj.ColormapDropDown.Value);
            layer_data.setMarkersColor(obj.ColorDropDown.Value);
            layer_data.setMarkersShape(obj.ShapeDropDown.Value);
        end
    end
end

