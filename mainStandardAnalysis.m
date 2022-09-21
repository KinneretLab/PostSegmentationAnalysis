addpath('classDefinitions');
close all
%% parameters
max_area = 1800;
min_area = 30;
calibration = 0.52; % calibration of images in um/pixel
time_only = false;
match_frames = true;

%% Configuration - here you can set the big experiment folders to draw graphs for.
% Don't worry about hand segmentation, the program will do this for you.

experiment_folders = {
    ... hand segmented, sorted by time
...    'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1', ... COMPLETED, no correlation
...     'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_08_18hr_set1', ... COMPLETED
...    'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6', ... COMPLETED, no correlation
    ... auto-segmented, sorted by user then time
...     'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos1', ...
...     'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos2', ...
    'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos3', ...
%     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos5', ...
%     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos6', ...
%     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos2', ...
%     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos3', ...
%     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos4', ...
    };

%% the actual code execution

for exp_idx = 1:length(experiment_folders)
    folder = experiment_folders{exp_idx};
    fprintf("generating figures for experiment (%d/%d): %s\n", exp_idx, length(experiment_folders), folder);
    
    cell_plotter = loadPlotter(folder, class(Cell), [min_area max_area], match_frames);
    bond_plotter = loadPlotter(folder, class(Bond), [min_area max_area], match_frames);
    frame_pair_plotter = loadFramePlotter(folder, match_frames);
    
    getGraphs(cell_plotter, bond_plotter, frame_pair_plotter, [folder, '\Figures\'], calibration, time_only, [min_area max_area]);
end

%% functions
function plotter = loadPlotter(experiment_folder, lookup_clazz, area_constraints, match_frames)
    if exist([experiment_folder, '\Cells_auto'], 'dir')
        auto_data = Experiment.load([experiment_folder, '\Cells_auto']).lookup(lookup_clazz);
        if match_frames
            hand_frames = [Experiment.load([experiment_folder, '\Cells']).frames.frame];
            auto_data = auto_data(ismember([auto_data.frame], hand_frames));
        end
        auto_data = checkArea(auto_data, area_constraints, true);
        hand_data = Experiment.load([experiment_folder, '\Cells']).lookup(lookup_clazz);
        hand_data = checkArea(hand_data, area_constraints, true);
        plotter = PlotBuilder().addData(auto_data, 'auto')...
            .addData(auto_data([auto_data.confidence] > 0.5), 'scored')...
            .addData(hand_data, 'hand');
    else
        auto_data = Experiment.load([experiment_folder, '\Cells']).lookup(lookup_clazz);
        auto_data = checkArea(auto_data, area_constraints, true);
        plotter = PlotBuilder().addData(auto_data, 'auto')...
            .addData(auto_data([auto_data.confidence] > 0.5), 'scored');
    end
end

function plotter = loadFramePlotter(experiment_folder, match_frames)
    dist_func = BulkFunc(@(l_frame, r_frame) abs([l_frame.frame] - [r_frame.frame]));
    if exist([experiment_folder, '\Cells_auto'], 'dir')
        auto_data = Experiment.load([experiment_folder, '\Cells_auto']).frames.pair(dist_func);
        if match_frames
            hand_frames = [Experiment.load([experiment_folder, '\Cells']).frames.frame];
            auto_data = auto_data(ismember([auto_data.frame], hand_frames));
        end
        hand_data = Experiment.load([experiment_folder, '\Cells']).frames.pair(dist_func);
        plotter = PlotBuilder().addData(auto_data, 'auto')...
            .addData(hand_data, 'hand');
        % pre-load frames.cells
        Experiment.load([experiment_folder, '\Cells_auto']).frames.cells;
        Experiment.load([experiment_folder, '\Cells']).frames.cells;
    else
        auto_data = Experiment.load([experiment_folder, '\Cells']).frames.pair(dist_func);
        plotter = PlotBuilder().addData(auto_data, 'auto');
        % pre-load frames.cells
        Experiment.load([experiment_folder, '\Cells']).frames.cells;
    end
end

function filtered_phys_arr = checkArea(phys_arr, area_constraints, remove_flag)
    transposed = phys_arr';
    if isa(phys_arr(1), class(Bond))
        transposed = transposed(~isnan([transposed.bond_length]));
    end
    cells = transposed.cells;
    areas = area_constraints(1) * ones(size(cells));
    areas(~isnan(cells)) = [cells(~isnan(cells)).area];
    test = area_constraints(1) <= areas & areas <= area_constraints(2);
    existing_filter = logical(prod(test, 2));
    final_filter = false(size(phys_arr));
    if isa(phys_arr(1), class(Bond))
        final_filter(~isnan([phys_arr.bond_length])) = existing_filter;
    else
        final_filter = existing_filter;
    end
    if remove_flag
        filtered_phys_arr = phys_arr(final_filter);
    else
        filtered_phys_arr = phys_arr;
        filtered_phys_arr(final_filter) = feval(class(phys_arr(1)));
    end
end
    
function getGraphs(cell_plotter, bond_plotter, frame_pair_plotter, save_dir, scale, time_only, area_constraints)
    % iterate oveer auto and hand to generate corresponding data
    meas_functions = {"area", PlotUtils.xNormalize("area", "frame"), ...
        "perimeter", PlotUtils.xNormalize("perimeter", "frame"), ...
        "bond_length", PlotUtils.xNormalize("bond_length", "frame"), ...
        PlotUtils.shape, PlotUtils.numNeighbors, PlotUtils.cellFiberAngle};
    meas_filters = {1, 1, 1, 1, 1, 1, 1, "~[obj_arr.is_edge]", "([obj_arr.fibre_coherence]>0.92) & [obj_arr.aspect_ratio]>1.25"};
    meas_scales = [scale ^ 2, 1, scale, 1, scale, 1, 1, 1, 1];
    meas_names = ["Area", "Frame-Normalized Area", ...
        "Perimeter", "Frame-Normalized Perimeter", "Bond Length", ...
        "Frame-Normalized Bond Length", "Shape", "# Cell Neighbors", "Fiber-Cell Angle"];
    meas_units = ["um^2", "AU", "um", "AU", "um", "AU", "AU", "AU", "rad"];
    meas_files = ["area", "area_norm", "perimeter", "perimeter_norm", "bond_length", ...
        "bond_length_norm", "shape", "neighbors", "cell_fiber_angle"];
    
    meas_axes = meas_names + " [" + meas_units + "]";
    meas_bond_flag = arrayfun(@(str) (contains(str, "bond")), meas_files);
    time_flag = [1, 0, 1, 0, 1, 0, 1, 1, 1];
    
    % unique graphs we want that do not fit into the scheme
    f = cell_plotter.xAxis("frame").yAxis("# Cells").title("# Cells (frame)").draw;
    forceSave(f,save_dir + "num_cells_time.png");
    close(f);
    f = cell_plotter.yFunction(@(cell_arr) (sum([cell_arr.area]) / sum(cell_arr(1).frames.mask, 'all'))) ...
        .xAxis("frame").yAxis("% Area").title("Area Coverage (frame)").draw;
    forceSave(f,save_dir + "area_coverage_time.png");
    close(f);

    for i=1:length(meas_functions)
        meas = meas_functions{i};
        filter = meas_filters{i};
        save_prefix = save_dir + meas_files(i);
        name = meas_names(i);
        calib = meas_scales(i);
        axis_name = meas_axes(i);
        if meas_bond_flag(i)
            plotter = bond_plotter.filterFunction(filter);
            from_frame_meas = BulkFunc(@(frames) nanmean(BulkFunc.apply(PlotUtils.axify(meas), checkArea(frames.bonds, area_constraints, false)), 2));
        else
            plotter = cell_plotter.filterFunction(filter);
            from_frame_meas = BulkFunc(@(frames) nanmean(BulkFunc.apply(PlotUtils.axify(meas), checkArea(frames.cells, area_constraints, false)), 2));
        end
        
        if time_flag(i)
            f = plotter.yAxis(axis_name).xAxis("frame").yFunction(PlotUtils.axify(meas, "y")).yCalibration(calib) ...
                .outliers....yErrFunction(PlotUtils.axify(meas, "err"))...
                .title("mean " + name + " (frame)").draw;
            forceSave(f, save_prefix + "_time.png");
            close(f);
            
%             f = frame_pair_plotter.yAxis(axis_name + " correlation").xAxis("frame difference")...
%                 .xFunction("distance").yFunction(PlotUtils.correlation(from_frame_meas)) ...
%                 .outliers.title(name + " time correlation").draw;
%             forceSave(f, save_prefix + "_time_corr.png");
%             close(f);
        end
        
        if ~time_only
            f_arr = PlotUtils.sequenceWithTotal(plotter.invisible.xFunction(meas) ...
                .xAxis(axis_name).xCalibration(calib).distribution.outliers ...
                .title(name + " PDF (frame=%d)"));
            if ~exist(save_prefix + "_dist", 'dir')
                mkdir(save_prefix + "_dist");
            end
            for j = 1:length(f_arr)
                forceSave(f_arr(j),save_prefix + "_dist\" + j + ".png");
                close(f_arr(j));
            end
            f_arr = PlotUtils.sequenceWithTotal(plotter.invisible.xFunction(meas)...
                .xAxis(axis_name).xCalibration(calib).cumulative.normalize.outliers.xLogScale.yLogScale ...
                .title("log-log " + name + " CDF (frame=%d)"));
            if ~exist(save_prefix + "_logcdf", 'dir')
                mkdir(save_prefix + "_logcdf");
            end
            for j = 1:length(f_arr)
                forceSave(f_arr(j),save_prefix + "_logcdf\" + j + ".png");
                close(f_arr(j));
            end
        end
    end
end

function forceSave(obj, file_path)
    dir_path = fileparts(file_path);
    if ~exist(dir_path, 'dir')
        mkdir(dir_path);
    end
    done = false;
    while ~done
        try
            saveas(obj, file_path);
            done = true;
        catch e
            warning(e.message);
            pause(0.1);
        end
    end
end