addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\GroupCodes\July2021'));

dir1 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells';
dir2 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_08_18hr_set1\Cells';

dir3 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells_auto';
dir4 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_08_18hr_set1\Cells_auto';

dir5 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells';

cellIMDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\AllSegmented';

exp_arr = Experiment(dir1);
cell_arr = exp_arr.cells;
bond_arr = exp_arr.bonds;
frame_arr = exp_arr.frames;

%%
class_list = {'cells','cells','bonds','cells'};
filter_list = {'','[obj_arr.aspect_ratio]>1.25','','[obj_arr.is_edge]==0'};
value_fun_list = {{@(cell)( mod(atan([cell.elong_yy]./[cell.elong_xx])+pi,pi)),'aspect_ratio'},'area','bond_length','aspect_ratio'};
calibration_list = {{'xy',0},{'xy',2},{'xy',1},{'xy',0}};
type_list = {'quiver','image','image','list'};
image_size = [512,512];


%% Data for presentation:

% Quiver images of defect example with cell orientation
dir1 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\';

exp = Experiment(dir1);
frame_arr = exp.frames;
class_list = {'cells'};
filter_list = {''};
value_fun_list = {{@(cell)( mod(atan([cell.elong_yy]./[cell.elong_xx])+pi,pi)),'aspect_ratio'}};
calibration_list = {{'xy',0}};
type_list = {'quiver'};
image_size = [512,512];
xyCalib = 0.52;

exp.HMfolder('Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Layer_Separation\Output');
exp.calibrationXY(0.52).calibrationZ(3);

% builder.output_folder("Z:\Analysis\users\Yonit\MatlabCodes\Workspace\test").draw;

builder3d = ImageBuilder3D;
builder3d.addData(frame_arr);
builder3d.setHMSubfolder("Smooth_Height_Maps_1");

builder3d.image_data.setXYCalibration(xyCalib).setImageSize(image_size);
for i=1:length(class_list)
    builder3d.layers_data(i).setClass(class_list{i}).setFilterFunction(filter_list{i}).setValueFunction(value_fun_list{i}).setCalibrationFunction(calibration_list{i}).setType(type_list{i});
end 

builder3d.layers_data(1).setIsMarkerQuiver(1);
builder3d.calculate;

builder3d.saveLayerArr('Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\3d','layer_arr_3d_test');
%%
% Area maps for short movie clips


dir2 = 'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos3\Cells_presentation';

exp2 = Experiment(dir2);
frame_arr = exp2.frames;
class_list = {'cells','bonds','vertices'};
filter_list = {'','',''};
value_fun_list = {'area',1,1};
calibration_list = {{'xy',2},{'xy',0},{'xy',0}};
type_list = {'image','image','image'};
image_size = [1024,1024];
xyCalib = 0.52;


builder = ImageBuilder(util_fun_path);
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
builder = builder.xyCalibration(xyCalib);
builder = builder.class_list(class_list);
builder = builder.filter_list(filter_list);
builder = builder.value_fun_list(value_fun_list);
builder = builder.type_list(type_list);
layer_arr = builder.calculate(calibration_list);

save('Z:\Analysis\users\Yonit\Presentations\Dresden_Seminar_October_2022\DataForImages\2021_07_26_pos3\layer_arr.mat','layer_arr')

%% 
dir3 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\';

exp3 = Experiment(dir3);
frame_arr = exp3.frames(32:43);
class_list = {'cells','bonds','vertices'};
filter_list = {'','',''};
value_fun_list = {'area',1,1};
calibration_list = {{'xy',2},{'xy',0},{'xy',0}};
type_list = {'image','image','image'};
image_size = [1024,1024];
xyCalib = 0.52;


builder = ImageBuilder(util_fun_path);
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
builder = builder.xyCalibration(xyCalib);
builder = builder.class_list(class_list);
builder = builder.filter_list(filter_list);
builder = builder.value_fun_list(value_fun_list);
builder = builder.type_list(type_list);
layer_arr = builder.calculate(calibration_list);
save('Z:\Analysis\users\Yonit\Presentations\Dresden_Seminar_October_2022\DataForImages\2021_05_06_pos6\layer_arr.mat','layer_arr')
%% 
dir4 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells';

exp4 = Experiment(dir4);
frame_arr = exp4.frames;
class_list = {'cells','cells','bonds'};
filter_list = {'and([obj_arr.aspect_ratio]>1.25,[obj_arr.fibre_localOP]>0.98)','[obj_arr.aspect_ratio]>1.25',''};
value_fun_list = {1,1,1};
calibration_list = {{'xy',0},{'xy',0},{'xy',0}};
type_list = {'list','list','image'};
image_size = [512,512];
xyCalib = 0.65;


builder = ImageBuilder(util_fun_path);
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
builder = builder.xyCalibration(xyCalib);
builder = builder.class_list(class_list);
builder = builder.filter_list(filter_list);
builder = builder.value_fun_list(value_fun_list);
builder = builder.type_list(type_list);
layer_arr = builder.calculate(calibration_list);

%% Mark multi-fold vertices

dir5 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\';

exp5 = Experiment(dir5);
frame_arr = exp5.frames;
class_list = {'tVertices','tVertices','tVertices'};
filter_list = {'(sum(~isnan(obj_arr.bonds),2)==4)','(sum(~isnan(obj_arr.bonds),2)==5)','(sum(~isnan(obj_arr.bonds),2)==6)'};
value_fun_list = {1,1,1};
calibration_list = {{'xy',0},{'xy',0},{'xy',0}};
type_list = {'list','list','list'};
image_size = [1024,1024];
xyCalib = 0.52;


builder = ImageBuilder(util_fun_path);
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
builder = builder.xyCalibration(xyCalib);
builder = builder.class_list(class_list);
builder = builder.filter_list(filter_list);
builder = builder.value_fun_list(value_fun_list);
builder = builder.type_list(type_list);
builder = builder.calculate(calibration_list);

builder.saveLayerArr('Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Figures\Images\Data','layer_arr_multifoldV.mat');
%% Mark multi-fold vertices - automatic segmentation

dir5 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells_auto\';

exp5 = Experiment(dir5);
frame_arr = exp5.frames;
class_list = {'tVertices','tVertices','tVertices'};
filter_list = {'(sum(~isnan(obj_arr.bonds),2)==4)','(sum(~isnan(obj_arr.bonds),2)==5)','(sum(~isnan(obj_arr.bonds),2)==6)'};
value_fun_list = {1,1,1};
calibration_list = {{'xy',0},{'xy',0},{'xy',0}};
type_list = {'list','list','list'};
image_size = [1024,1024];
xyCalib = 0.52;


builder = ImageBuilder(util_fun_path);
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
builder = builder.xyCalibration(xyCalib);
builder = builder.class_list(class_list);
builder = builder.filter_list(filter_list);
builder = builder.value_fun_list(value_fun_list);
builder = builder.type_list(type_list);
builder = builder.calculate(calibration_list);

mkdir('Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Figures\Images_auto\Data');
builder.saveLayerArr('Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Figures\Images_auto\Data','layer_arr_multifoldV.mat');


%% Cell reliability maps

dir6 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells_auto';

exp6 = Experiment(dir6);
frame_arr = exp6.frames(1);
class_list = {'cells','cells'};
filter_list = {'[obj_arr.confidence]>0.5','[obj_arr.confidence]<0.5'};
value_fun_list = {1,1};
calibration_list = {{'xy',0},{'xy',0}};
type_list = {'image','image'};
image_size = [512,512];
xyCalib = 0.65;

builder = ImageBuilder(util_fun_path);
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
builder = builder.xyCalibration(xyCalib);
builder = builder.class_list(class_list);
builder = builder.filter_list(filter_list);
builder = builder.value_fun_list(value_fun_list);
builder = builder.type_list(type_list);
layer_arr = builder.calculate(calibration_list);
%% Test new version

dir6 = 'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos3\Cells';


exp6 = Experiment(dir6);
frame_arr = exp6.frames;
class_list = {'tVertices','tVertices','tVertices'};
filter_list = {'(sum(~isnan(obj_arr.bonds),2)==4)','(sum(~isnan(obj_arr.bonds),2)==5)','(sum(~isnan(obj_arr.bonds),2)==6)'};
value_fun_list = {1,1,1};
calibration_list = {{'xy',0},{'xy',0},{'xy',0}};
type_list = {'list','list','list'};
image_size = [1024,1024];
xyCalib = 0.52;


builder = ImageBuilder;
builder = builder.addData(frame_arr);
builder.image_data.setXYCalibration(xyCalib).setImageSize(image_size);
for i=1:length(class_list)
    builder.layers_data(i).setClass(class_list{i}).setFilterFunction(filter_list{i}).setValueFunction(value_fun_list{i}).setCalibrationFunction(calibration_list{i}).setType(type_list{i});
end 
[~,layer_arr] = builder.calculate;
%%



dir2 = 'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos3\Cells_presentation';

exp2 = Experiment(dir2);
frame_arr = exp2.frames;
class_list = {'cells','bonds','vertices'};
filter_list = {'','',''};
value_fun_list = {PlotUtils.xNormalize("area","frame"),1,1};
calibration_list = {{'xy',2},{'xy',0},{'xy',0}};
type_list = {'image','image','image'};
image_size = [1024,1024];
xyCalib = 0.52;

builder = ImageBuilder;
builder.addData(frame_arr);
builder.image_data.setXYCalibration(xyCalib).setImageSize(image_size);
for i=1:length(class_list)
    builder.layers_data(i).setClass(class_list{i}).setFilterFunction(filter_list{i}).setValueFunction(value_fun_list{i}).setCalibrationFunction(calibration_list{i}).setType(type_list{i});
end 


builder.output_folder("Z:\Analysis\users\Yonit\MatlabCodes\Workspace\test").draw;

