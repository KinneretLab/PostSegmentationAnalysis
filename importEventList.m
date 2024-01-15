classdef importEventList
    properties(Constant)
        logger = Logger('importEventList');
    end

    properties
        source_event_table = "test\example\tissuedeformation5.xlsx";

        target_experiment = "test\example"

        target_name = "SD1_2021_05_06_pos6";

        % max graph distance from the cell holding the defect to take into
        % account when searching for the peak event frame
        max_graph_distance = 3;
        % the minimum amount of "core" cells required to find a proper mean
        % and not skip the frame when calculating the peak event frame
        min_cell_threshold = 10;
    end

    methods 
        function obj = importEventList
            addpath('classDefinitions')
            target_experiment_path = Path(obj.target_experiment);

            % to look up stuff we need the date in matching form, the
            % postion, and optional microscope customization
            % using this we can target the correct row group
            full_data_table = readtable(obj.source_event_table);

            if isempty(obj.target_name)
                obj.target_name = target_experiment_path.name.string;
            end
            % extract experiment identifiers: microscope, date, position
            % from the experiment name
            experiment_idenifiers = regexp(obj.target_name,"(SD1)?_?(\d[\d_]*)_pos(\d+)","tokens");
            experiment_idenifiers = experiment_idenifiers{1};
            experiment_idenifiers(2) = string(datetime(experiment_idenifiers(2), InputFormat="yyyy_MM_dd", Format="d.M.yy"));

            % start by finding matching date & position
            event_start_row = find(full_data_table.Date == experiment_idenifiers(2) & string(full_data_table.Pos) == experiment_idenifiers(3));
            % next, filter by testing for SD1
            event_start_row = event_start_row(full_data_table.Date(event_start_row + 1) == experiment_idenifiers(1));
            % at this point we are guaranteed event_starting_row is a
            % scalar, or nonexistent. If it is nonexistent, error out.
            if isempty(event_start_row)
                obj.logger.error("The target experiment was not found in the provided event table. Aborting.");
                return
            end
            % next, get the idx of the next entry in the list so we know
            % what are the entries to read
            event_candidate_rows = find(~isnan(full_data_table.Pos));
            event_final_row = min(event_candidate_rows(event_candidate_rows > event_start_row)) - 1;

            % now we have all the ingrediants. All we need to do now is get
            % the entries from the table and save them as individual
            % parameters.

            % event_id acts as the unique identifier. For now since we only
            % expect one event source, we don't need to work so hard and
            % just use the row IDs
            event_id = (1:event_final_row - event_start_row + 1)';

            type = full_data_table.Events1_significantStreching2_smallStreching3_domes4_smallRaptu(event_start_row:event_final_row);

            start_frame = full_data_table.beginFramesOfEvent(event_start_row:event_final_row);

            end_frame = full_data_table.endFramesOfEvent(event_start_row:event_final_row);

            comment = string(full_data_table.remarks(event_start_row:event_final_row));

            % finding the peak frame is a bit harder since:
            % 1. the column might not exist at all
            % 2. even if the column exists there is no guarantee that all
            %    events were manually written down. Therefore for those
            %    frames we have to go to the experiment and algorithmically
            %    find the peak frame
            if ismember("peakFramesOfEvent", string(full_data_table.Properties.VariableNames))
                peak_frame = full_data_table.peakFramesOfEvent(event_start_row:event_final_row);
            else
                peak_frame = nan(size(event_id));
            end
            % an easy shortcut: if the and end are the same obviously so is
            % the peak (sandwich)
            peak_frame(start_frame == end_frame) = start_frame(start_frame == end_frame);

            i = 1;
            non_trivial_rows = find(isnan(peak_frame));
            if ~isempty(non_trivial_rows)
                
                defects = Experiment.load(target_experiment_path \ "Cells").defects;

                all_event_frames = arrayfun(@colon, start_frame, end_frame, UniformOutput=false);
                defects = defects(ismember([defects.frame], [all_event_frames{:}]));
                
                % For each frame, find cell that is closest to defect:
                defect_cells = defects.cells('');
                % Create array of cell pairs with topological distance:
                pair_arr = unique(defect_cells.createNeighborPairs);
    
                for unpeaked_event_row = non_trivial_rows
                    obj.logger.progress("Finding peak frame for non-trivial events", i, length(non_trivial_rows));
                    
                    frame_range = start_frame(unpeaked_event_row):end_frame(unpeaked_event_row);
    
                    peak_frame(unpeaked_event_row) = obj.findPeakFrame(frame_range, pair_arr);
                end
            end

            writetable(table(event_id, start_frame, end_frame, peak_frame, type, comment),...
                target_experiment_path / "Cells/events.csv",Delimiter=',');
        end


        function peak_frame_id = findPeakFrame(obj, frame_range, defect_cell_pairs)

            % this array holds the mean areas for the cells that are within
            % the threshold geometric distance from the detect
            mean_areas = zeros(1, length(frame_range));

            for j=1:length(frame_range)
                % We iterate over the list of available frames and find the
                % frame with the maximum mean area within the threshold
                % distance
                frame_num = frame_range(j);

                % get all cells within the max threshold distance
                valid_pairs = defect_cell_pairs([defect_cell_pairs.distance] <= obj.max_graph_distance);

                % get a nice list of all the individual cells rather than
                % the pairs
                valid_elements = [valid_pairs.elements];
                % filter by frame and delete the duplicate defect cell
                valid_elements = unique(valid_elements([valid_elements.frame] == frame_num));

                % if there are enough cells to reliably find a mean, find
                % it and store that info.
                if length(valid_elements) >= obj.min_cell_threshold
                    mean_areas(j) = mean([valid_elements.area]);
                end
            end
        
        
            % To find maximum of event (frame with maximal deformation), take mean area
            % of all cells up to rank 3:
            [~, peak_frame_idx] = max(mean_areas);
            peak_frame_id = frame_range(peak_frame_idx);
        end
    end
end