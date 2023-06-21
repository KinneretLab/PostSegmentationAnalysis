classdef Experiment < handle
    % EXPERIMENT an abstract representation of an experiment, a collection of related pictures
    % This class has many large responsibilities:
    % - It computationally constructs and stores all data about the images
    %   it contains
    % - It handles filesystem access since it is the only thing aware of
    %   the file system.
    % This is the base object you start with.
    % You can get an experiment using Experiment.load(folder)
    % and from there get every other entity in the experiment with the
    % available functions.
    properties
        % An internal variable storing the absolute location of the data tables.
        % Used for file-system operations
        % type: Path
        folder_
        % An internal variable storing the absolute location of the
        % experiment height maps.
        % Used for file-system operations
        % type: string
        hm_folder_
        % An internal variable storing the data generated by the experiement.
        % not to be used externally.
        % type: Map(string -> PhysicalEntity)
        data_
        % An internal variable used to store the filesystem locations of the table files.
        % not to be used externally.
        % type: Map(string -> string)
        files_
        % Micron/pixel calibration for the experiment xy plane
        calibration_xy_
        % Micron/pixel calibration for the experiment in z axis
        calibration_z_
        % Image size in pixels, [rows,columns]
        image_size_
    end
    
    properties (Constant)
        % A static map holding all the experiment loaded by the MATLAB session.
        % not to be used externally.
        % type: Map(string -> EXPERIMENT)
       loaded_ = containers.Map 
       
       logger = Logger('Experiment');
    end
    
    methods (Static)
        % LOAD create a fresh experiment or load an existing experiment from memory.
        % Parameters:
        %   folder: string
        %      the absolute path to the folder where the data tables
        %      exist. If the folder was loaded before, the method will just
        %      retrieve it again without losing the calculations done on it
        %      previously. If it does not exist, this will construct a new
        %      experiment from scratch.
        % Return type: Experiment
        function obj = load(folder)
            folder_path = Path(folder);
            map = Experiment.loaded_;
            map_key = Experiment.toUniqueName(folder_path);
            if map.isKey(map_key)
                obj = map(map_key);
            else
                obj = Experiment(folder);
                map(map_key) = obj;
            end
        end
        
        function remove(key)
            % REMOVE Remove an experiment from the experiment index.
            % This will not lead to a deletion of the current data, but can
            % allow re-calculating the experiment data anew.
            % Not recommended unless you know what you are doing.
            % Parameters:
            %   key: string or Experiment
            %      the experiment to remove, of the name of the folder it
            %      is built on.
            if isa(key, 'Experiment')
                key = key.uniqueName;
            else
                if contains(key, '/')
                    key = Experiment.toUniqueName(key);
                end
            end
            map = Experiment.loaded_;
            map.remove(key);
        end

        function clear()
            % CLEAR Wipe all experiments from the index to completely start fresh.
            % Only reccomended if you are running out of memory for the
            % MATLAB session.
            map = Experiment.loaded_;
            map.remove(map.keys);
        end
    end
    
    methods (Static, Access = private)
        function unique_name = toUniqueName(folder_names)
            arguments
                folder_names Path
            end
            regex_result = string(regexp(folder_names.string, "\w+", 'match'));
            if length(folder_names) == 1
                unique_name = regex_result(end - 1) + '_' + regex_result(end);
            else
                unique_name = cellfun(@(result) result(end - 1) + '_' + result(end), regex_result);
            end
        end
    end
    
    methods
        function obj = Experiment(folder)
            % EXPERIMENT construct a new experiment Don't use this. Use EXPERIMENT.LOAD() instead.     
            %   folder: string
            %      the absolute path to the folder where the data tables
            %      exist.
            if nargin > 0
                obj.folder_ = Path(folder);
                obj.data_ = containers.Map();
                obj.files_ = containers.Map(cellfun(@class,{Cell, Bond, Vertex, DBond, Frame, BondPixelList, Defect}, 'UniformOutput', false), ...
                    cellfun(@(file) string(Path(folder) \ file + ".csv"), {'cells', 'bonds', 'vertices', 'directed_bonds', 'frames', 'bond_pixels','defects'}, 'UniformOutput', false));
            else
                obj.folder_ = nan;
            end
            obj.calibration_xy_ = 1; % Set calibration to default value of 1
            obj.calibration_z_ = 1; % Set calibration to default value of 1

        end

        function obj = calibrationXY(obj,calibration)
            obj.calibration_xy_ = calibration;
        end

        function obj = calibrationZ(obj,calibration)
            obj.calibration_z_ = calibration;
        end

        function obj = imageSize(obj,size)
            obj.image_size_ = size;
        end

        function obj = HMfolder(obj,folder)
            obj.hm_folder_ = folder;
        end

       function tf = eq(lhs, rhs)
            tf = reshape([lhs.folder_] == [rhs.folder_], size(lhs));
        end
        
        function result = imread(obj, path)
            % IMREAD Reads a file relative to the experiment and converts it to a MATLAB image.
            % Parameters:
            %   path: string
            %      the path relative to experiment folder to read.
            % Return type: an image matrix (int[][] or int[][][])
            if isempty(obj)
                return
            end
            if length(obj) ~= 1
                obj(1).logger.error("Load function called for an array of experiments. This is an ambiguous call. Plase iterate over the array instead.")
                return
            end
            result = imread([obj.folder_, '\', path]);
        end

        function result = dir(obj, path)
            % IMREAD Reads a file relative to the experiment and converts it to a MATLAB image.
            % Parameters:
            %   path: string
            %      the path relative to experiment folder to read.
            % Return type: dir[]
            if isempty(obj)
                return
            end
            if length(obj) ~= 1
                obj(1).logger.error("Load function called for an array of experiments. This is an ambiguous call. Plase iterate over the array instead.")
                return
            end
            result = dir(string(obj.folder_ \ path));
            result = natsortfiles(result(3:end));
        end
        
        function phys_arr = lookup(obj, clazz, varargin)
            % LOOKUP Retrieves all physical entities of the deired class from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   obj (caller):
            %      the object which requests the search.
            %   clazz: string
            %      the class name of the object type you are looking for
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: clazz[] with size (1, ?)
            
            % iterate over all experiments
            result_arr = cell(1, length(obj));
            for row = 1:length(obj)
                experiment = obj(row);
                if ~experiment.data_.isKey(clazz)
                    obj(1).logger.info("Indexing %ss for Experiment %s", clazz, experiment.folder_);
                    if experiment.files_.isKey(clazz)
                        % load the data from the apropriate table
                        lookup_table = readtable(experiment.files_(clazz),'Delimiter',',');
                        % construct the target array of classes with the
                        % apropriate data
                        result = feval(clazz, experiment, lookup_table);
                    else
                        % if this branch is activated, it implies the
                        % object is calculated from existing objects,
                        % meaning the constructuor is slightly different.
                        result = feval(clazz, experiment, varargin{:});
                        varargin(1:min(result(1).nargs, length(varargin))) = [];
                    end
                    % save into the experiment index.
                    experiment.data_(clazz) = result;
                else
                    result = experiment.data_(clazz);
                end
                % filter result and put it into result_arr
                if nargin > 2
                    result_arr{row} = result(varargin{:});
                else
                    result_arr{row} = result;
                end
            end
            % concatenate the results of all experiments into one big row.
            phys_arr = [result_arr{:}];
        end
        
        function cell_arr = cells(obj, varargin)
            % CELLS Retrieves all cells from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: CELL[] with size (1, ?)
            cell_arr = obj.lookup(class(Cell), varargin{:});
        end

        function dbond_arr = dBonds(obj, varargin)
            % DBONDS Retrieves all directed bonds from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: DBOND[] with size (1, ?)
            dbond_arr = obj.lookup(class(DBond), varargin{:});
        end
        
        function bond_arr = bonds(obj, varargin)
            % BONDS Retrieves all bonds from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BOND[] with size (1, ?)
            bond_arr = obj.lookup(class(Bond), varargin{:});
        end
        
        function vertex_arr = vertices(obj, varargin)
            % VERTICES Retrieves all vertices from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: VERTEX[] with size (1, ?)
            vertex_arr = obj.lookup(class(Vertex), varargin{:});
        end
        
        function vertex_arr = tVertices(obj, varargin)
            % TVERTICES Retrieves all true vertices from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            %   if you are contructing the array for the first time,
            %   this function will use the first parameter as the radius
            %   filter contruction parameter.
            % Return type: TRUEVERTEX[] with size (1, ?)
            vertex_arr = obj.lookup(class(TrueVertex), varargin{:});
        end
        
        function region_arr = regions(obj, varargin)
            % REGIONS Retrieves all marked regions (including masks) from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: MARKEDREGION[] with size (1, ?)
            region_arr = obj.lookup(class(MarkedRegion), varargin{:});
        end

        function frame_arr = frames(obj, varargin)
            % FRAMES Retrieves all frames from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: FRAME[] with size (1, ?)
            frame_arr = obj.lookup(class(Frame), varargin{:});
        end
        
        function bond_pixels_arr = bondPixelLists(obj, varargin)
            % BONDPIXELLISTS Retrieves all bond pixel lists from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: BONDPIXELLIST[] with size (1, ?)
            bond_pixels_arr = obj.lookup(class(BondPixelList), varargin{:});
        end
        

        function defect_arr = defects(obj, varargin)
            % DEFECTS Retrieves all defects from the experiment(s), and loads/constructs them if neccesary.
            % Additional arguments can be applied to get select slices or a
            % conditional filtering
            % for example, exp.cells([exp.cells.confidence] > 0.5) will
            % only yield cells with a confidence bigger than 0.5
            % Parameters:
            %   varargin: additional MATLAB builtin operations to apply on
            %   the result.
            % Return type: FRAME[] with size (1, ?)
            defect_arr = obj.lookup(class(Defect), varargin{:});
        end

        function frame_arr = cellPairsExp(obj)

            % Start with creating frame array for the experiment, becuase each pair list
            % is going to be a property of the relevant frame. Then find
            % pairs for each frame and save them as properties of the frame
            % array.
            frame_arr = obj.frames;
            frame_arr = frame_arr.cellPairsFrame;
        end

        function unique_name = uniqueName(obj)
            unique_name = Experiment.toUniqueName([obj.folder_]);
        end

    end
    
end