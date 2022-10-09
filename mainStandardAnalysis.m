classdef mainStandardAnalysis
    % parameters
    properties
        area_constraints = [30 1800]; % min and max area of an allowed cell, in pixels.
        calibration = 0.52; % calibration of images in um/pixel
        time_only = false;
        match_frames = false;
        
        % Configuration - here you can set the big experiment folders to draw graphs for.
        % Don't worry about hand segmentation, the program will do this for you.

        experiment_folders = {
        ... hand segmented, sorted by time
    ...    'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1', ... COMPLETED, no correlation
         'Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_08_18hr_set1', ... COMPLETED
    ...    'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6', ... COMPLETED, no correlation
        ... auto-segmented, sorted by user then time
    ...     'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos1', ...
    ...     'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos2', ...
    ...    'Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos3', ... COMPLETED, no correlation
    ...     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos5', ...
    ...     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos6', ...
    ...     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos2', ...
    ...     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos3', ... non-existent (yet)
    ...     'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos4', ...
        };
    
        figure_folder_name = 'Figures';
        
        graph_choices = ["num_cells", "coverage", "mean_time", "mean_time_correlation", "pdf", "cdf"];
        
        min_frame_coverage = 0;
    
        logger;
    end
    
    methods
        % the actual code execution
        function main = mainStandardAnalysis(varargin)
            main.logger = Logger(class(main));
            for arg_idx = 1:2:length(varargin)
                main.(varargin{arg_idx}) = varargin{arg_idx+1};
            end
            
            addpath('classDefinitions');
            close all
            
            for exp_idx = 1:length(main.experiment_folders)
                folder = main.experiment_folders{exp_idx};
                main.logger.info("generating figures for experiment (%d/%d): %s", exp_idx, length(main.experiment_folders), folder);
                main.logger.info("loading Cells...");
                cell_plotter = main.loadPlotter(folder, class(Cell));
                main.logger.info("loading Bonds...");
                bond_plotter = main.loadPlotter(folder, class(Bond));
                main.logger.info("loading Frame Pairs...");
                frame_pair_plotter = main.loadFramePlotter(folder);

                main.getGraphs(cell_plotter, bond_plotter, frame_pair_plotter, [folder, '\', main.figure_folder_name, '\']);
            end
        end
        
        function plotter = loadPlotter(main, experiment_folder, lookup_clazz)
            if exist([experiment_folder, '\Cells_auto'], 'dir')
                has_hand = true;
                auto_exp = Experiment.load([experiment_folder, '\Cells_auto']);
                hand_exp = Experiment.load([experiment_folder, '\Cells']);
            else
                has_hand = false;
                auto_exp = Experiment.load([experiment_folder, '\Cells']);
            end
            auto_data = auto_exp.lookup(lookup_clazz);
            auto_data = main.checkArea(auto_data, true);
            if main.min_frame_coverage > 0
                all_frames =  auto_exp.frames;
                all_cells = all_frames.cells;
                all_confidence = reshape([all_cells.confidence] > 0.5, size(all_cells));
                all_areas = reshape([all_cells.area], size(all_cells));
                all_areas(all_areas < main.area_constraints(1) | all_areas > main.area_constraints(2)) = 0;
                total_areas = nansum(all_areas .* all_confidence, 2);
                mask_areas = arrayfun(@(frame) sum(frame.mask, 'all'), all_frames);
                allowed_frames = [all_frames(total_areas ./ mask_areas' > 0.25).frame];
                auto_data = auto_data(ismember([auto_data.frame], allowed_frames));
            end
            if has_hand
                hand_data = Experiment.load([experiment_folder, '\Cells']).lookup(lookup_clazz);
                hand_data = main.checkArea(hand_data, true);
                if main.match_frames
                    hand_frames = [hand_exp.frames.frame];
                    auto_data = auto_data(ismember([auto_data.frame], hand_frames));
                end
                plotter = PlotBuilder().addData(auto_data, 'auto')...
                    .addData(auto_data([auto_data.confidence] > 0.5), 'scored')...
                    .addData(hand_data, 'hand');
            else
                plotter = PlotBuilder().addData(auto_data, 'auto')...
                    .addData(auto_data([auto_data.confidence] > 0.5), 'scored');
            end
        end
        
        function plotter = loadFramePlotter(main, experiment_folder)
            dist_func = BulkFunc(@(l_frame, r_frame) abs([l_frame.frame] - [r_frame.frame]));
            if exist([experiment_folder, '\Cells_auto'], 'dir')
                auto_data = Experiment.load([experiment_folder, '\Cells_auto']).frames.pair(dist_func);
                if main.match_frames
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
        
        function getGraphs(main, cell_plotter, bond_plotter, frame_pair_plotter, save_dir)
            % iterate oveer auto and hand to generate corresponding data
            meas_functions = {"area", PlotUtils.xNormalize("area", "frame"), ...
                "perimeter", PlotUtils.xNormalize("perimeter", "frame"), ...
                "bond_length", PlotUtils.xNormalize("bond_length", "frame"), ...
                PlotUtils.shape, PlotUtils.numNeighbors, PlotUtils.cellFiberAngle};
            meas_filters = {1, 1, 1, 1, 1, 1, 1, "~[obj_arr.is_edge]", "([obj_arr.fibre_coherence]>0.92) & [obj_arr.aspect_ratio]>1.25"};
            meas_scales = [main.calibration ^ 2, 1, main.calibration, 1, main.calibration, 1, 1, 1, 1];
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
            if ismember("num_cells", main.graph_choices)
                main.logger.info("Plotting # Cells");
                f = cell_plotter.xAxis("frame").yAxis("# Cells").title("# Cells (frame)").draw;
                forceSave(f,save_dir + "num_cells_time.png");
                close(f);
            end
            if ismember("coverage", main.graph_choices)
                main.logger.info("Plotting Area Coverage");
                f = cell_plotter.yFunction(@(cell_arr) (sum([cell_arr.area]) / sum(cell_arr(1).frames.mask, 'all'))) ...
                    .xAxis("frame").yAxis("% Area").title("Area Coverage (frame)").draw;
                forceSave(f,save_dir + "area_coverage_time.png");
                close(f);
            end

            for i=1:length(meas_functions)
                meas = meas_functions{i};
                filter = meas_filters{i};
                save_prefix = save_dir + meas_files(i);
                name = meas_names(i);
                calib = meas_scales(i);
                axis_name = meas_axes(i);
                if meas_bond_flag(i)
                    plotter = bond_plotter.filterFunction(filter);
                    from_frame_meas = BulkFunc(@(frames) nanmean(BulkFunc.apply(PlotUtils.axify(meas), main.checkArea(frames.bonds, false)), 2));
                else
                    plotter = cell_plotter.filterFunction(filter);
                    from_frame_meas = BulkFunc(@(frames) nanmean(BulkFunc.apply(PlotUtils.axify(meas), main.checkArea(frames.cells, false)), 2));
                end

                if ~main.time_only
                    if ismember("pdf", main.graph_choices)
                        main.logger.info("Plotting %s PDF", name);
                        f_arr = PlotUtils.sequenceWithTotal(plotter.invisible.xFunction(meas) ...
                            .xAxis(axis_name).xCalibration(calib).distribution.outliers ...
                            .title(name + " PDF (frame=%d)"));
                        main.logger.info("Saving %s PDF", name);
                        if ~exist(save_prefix + "_dist", 'dir')
                            mkdir(save_prefix + "_dist");
                        end
                        for j = 1:length(f_arr)
                            forceSave(f_arr(j),save_prefix + "_dist\" + j + ".png");
                            close(f_arr(j));
                        end
                    end
                    if ismember("cdf", main.graph_choices)
                        main.logger.info("Plotting %s CDF", name);
                        f_arr = PlotUtils.sequenceWithTotal(plotter.invisible.xFunction(meas)...
                            .xAxis(axis_name).xCalibration(calib).cumulative.normalize.outliers.xLogScale.yLogScale ...
                            .title("log-log " + name + " CDF (frame=%d)"));
                        main.logger.info("Saving %s CDF", name);
                        if ~exist(save_prefix + "_logcdf", 'dir')
                            mkdir(save_prefix + "_logcdf");
                        end
                        for j = 1:length(f_arr)
                            forceSave(f_arr(j),save_prefix + "_logcdf\" + j + ".png");
                            close(f_arr(j));
                        end
                    end
                end

                if time_flag(i)
                    if ismember("mean_time", main.graph_choices)
                        main.logger.info("Plotting Mean %s per frame", name);
                        f = plotter.yAxis(axis_name).xAxis("frame").yFunction(PlotUtils.axify(meas, "y")).yCalibration(calib) ...
                            .outliers....yErrFunction(PlotUtils.axify(meas, "err"))...
                            .title("mean " + name + " (frame)").draw;
                        forceSave(f, save_prefix + "_time.png");
                        close(f);
                    end

                    if ismember("mean_time_correlation", main.graph_choices)
                        main.logger.info("Plotting %s time correlation", name);
                        f = frame_pair_plotter.yAxis(axis_name + " correlation").xAxis("frame difference")...
                            .xFunction("distance").yFunction(PlotUtils.correlation(from_frame_meas)) ...
                            .outliers.title(name + " time correlation").draw;
                        forceSave(f, save_prefix + "_time_corr.png");
                        close(f);
                    end
                end
            end
        end
        
        function filtered_phys_arr = checkArea(main, phys_arr, remove_flag)
            main.logger.info("filtering %ss by area", class(phys_arr(1)));
            transposed = phys_arr';
            if isa(phys_arr(1), class(Bond))
                transposed = transposed(~isnan([transposed.bond_length]));
            end
            cells = transposed.cells;
            areas = main.area_constraints(1) * ones(size(cells));
            areas(~isnan(cells)) = [cells(~isnan(cells)).area];
            test = main.area_constraints(1) <= areas & areas <= main.area_constraints(2);
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
    end
end

%% functions

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