%% Create the Expirement
% per expirement: image size, calibration xy and z-> this is data not
% stored in the expirement object and you need it to generate the images.
dir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\'; 
exp = Experiment(dir);
xy_calib = 0.65; %these are different per experimnet and you need to know per microscope used.
z_alib= 3;
image_size = [1024,1024];

% now we will set the data, done like this:
exp.calibrationXY(xy_calib);
exp.calibrationZ(z_alib);
exp.imageSize(image_size);
% or in one line (completely equivalent):
exp.calibrationXY(xy_calib).calibrationZ(z_alib).imageSize(image_size);

%% Create the ImageBuilder 
builder = ImageBuilder;
builder.output_folder("Z:\Analysis\users\Projects\Iris\Codes\test\tutorial"); %you need to configure an output folder unless you want the image builder to save to the active matlab folder.
builder.save_format("png"); %
%% Get relevant data (frames) from the experiment and add to builder
frame_arr= exp.frames(1:3); % you can also add a part of the frames or only one frame-> exp.frames(1) or exp.frames(1:3) or exp.frames
builder = builder.addData(frame_arr);
% this is where you access the data from where you create the visualizations so it's very important 

%% Configure the layers for calculation -> use help(ImageLayerDrawData)
% (done in the same way for drawing but we are making a distinction cause you need the data for different things)
% you need to decide what you want to draw (for the calculation).
% settings relevant:  
% per layer: class, filter, value_fun, calibration, type

% this is how you access the layers: (you can see all the things you can
% set using help(ImageLayerDrawData) and an explanation of what to enter
builder.layers_data(1).setClass("cells"); %in class you put one of the properties of Frame use help(Frame) to find them (you need to use the name from the methods part).
builder.layers_data(1).setType("list");
builder.layers_data(1).setFilterFunction("[obj_arr.is_edge]==1"); %refers to the properties of the class you decided, if you don't have any will not use filter
builder.layers_data(1).setValueFunction('perimeter'); %what will be the value in case of marker or quiver layer, if image layer the default is 1
%you can also set the calibration in the same way. in this case we will use
%the default.

%also, oneline is also possible:
builder.layers_data(1).setClass("cells").setType("list").setFilterFunction("[obj_arr.is_edge]==1").setValueFunction('perimeter');

%% Calculate the layers (if you forget to run this and run draw it will rerun calculate if it has never been run before in the builder).
builder.calculate;

%% Configure settings to draw the image -> use help(ImageDrawData)
builder.image_data.setShowColorbar(true); %you can use all the functions that begin with set

%% Configure settings to draw the layers
builder.layers_data(1).setMarkersColor("green").setMarkersColorByValue(true).setColorbar(false);

%% Draw (if you don't configure frame to draw first it will save the images in the output folder you set before)
builder.frame_to_draw(1).draw; % draws the 1st frame
%builder.draw; % draws and saves to output folder

%% Add image layer -you don't have to do it after calculating the first layer, you can do it all together, this is just for the sake of the tutorial.
%% Educational mistake
builder.layers_data(2).setClass("vertices"); 
builder.layers_data(2).setType("image");
builder.layers_data(2).setFilterFunction("[obj_arr.is_edge]==1") 
% need to recalculate
builder.calculate.frame_to_draw(1).draw;

%oh no, no is_edge in vertex? let's see what is, type help(Bond);
%we see that confidence is an attribute, maybe we want to filter by that.
%% Add image layer- no educational mistake ;)
builder.layers_data(2).setClass("bonds"); %in class you put one of the properties of Frame use help(Frame) to find them (you need to use the name from the methods part).
builder.layers_data(2).setType("image");
builder.layers_data(2).setFilterFunction('');
builder.layers_data(2).setValueFunction(1);

builder.layers_data(2).setIsSolidColor(true);
builder.calculate.frame_to_draw(1).draw; %run like this if you want to recalculate
%% Tip: if you just want to run and tweek the visualization (colormap, colorbar, scale etc.) don't run calculate!
builder.draw;
%% Add quiver layer
builder.layers_data(3).setClass("cells"); %in class you put one of the properties of Frame use help(Frame) to find them (you need to use the name from the methods part).
builder.layers_data(3).setType("quiver");
builder.layers_data(3).setFilterFunction('');
builder.layers_data(3).setValueFunction({@(cell)(cell.fibre_orientation), 'aspect_ratio'}); 

builder.calculate.frame_to_draw(1).draw; %run like this if you want to recalculate

%% Save builder for future reuse / editing in the GUI
builder.saveBuilder("tutorial_builder");