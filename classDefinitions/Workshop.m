addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes\GroupCodes\July2021'));

dir1 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells';
dir2 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_08_18hr_set1\Cells';

dir3 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells_auto';
dir4 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_08_18hr_set1\Cells_auto';

dir5 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells';

cellIMDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\AllSegmented';

exp_arr = Experiment(dir3);
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
dir1 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells';

exp = Experiment(dir1);
frame_arr = exp.frames;
class_list = {'cells'};
filter_list = {''};
value_fun_list = {{@(cell)( mod(atan([cell.elong_yy]./[cell.elong_xx])+pi,pi)),'aspect_ratio'}};
calibration_list = {{'xy',0}};
type_list = {'quiver'};
image_size = [512,512];

builder = ImageBuilder();
builder = builder.addData(frame_arr(20));
builder = builder.image_size(image_size);

% Area maps for short movie clips

dir2 = 'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos3\Cells_presentation';

exp = Experiment(dir2);
frame_arr = exp.frames;
class_list = {'cells','bonds'};
filter_list = {'',''};
value_fun_list = {'area',1};
calibration_list = {{'xy',2},{'xy',0}};
type_list = {'image','image'};
image_size = [1024,1024];

builder = ImageBuilder();
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
layer_arr = builder.calculate(class_list,filter_list,value_fun_list,type_list,calibration_list);

dir3 = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\';

exp = Experiment(dir3);
frame_arr = exp.frames(32:43);
class_list = {'cells','bonds'};
filter_list = {'',''};
value_fun_list = {'area',1};
calibration_list = {{'xy',2},{'xy',0}};
type_list = {'image','image'};
image_size = [1024,1024];

builder = ImageBuilder();
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
layer_arr = builder.calculate(class_list,filter_list,value_fun_list,type_list,calibration_list);

dir4 = 'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells';

exp = Experiment(dir4);
frame_arr = exp.frames;
class_list = {'cells','cells','bonds'};
filter_list = {'and([obj_arr.aspect_ratio]>1.25,[obj_arr.fibre_localOP]>0.98)','[obj_arr.aspect_ratio]>1.25',''};
value_fun_list = {1,1,1};
calibration_list = {{'xy',0},{'xy',0},{'xy',0}};
type_list = {'list','list','image'};
image_size = [512,512];

builder = ImageBuilder();
builder = builder.addData(frame_arr);
builder = builder.image_size(image_size);
layer_arr = builder.calculate(class_list,filter_list,value_fun_list,type_list,calibration_list);