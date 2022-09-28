classdef (Abstract, HandleCompatible) FigureBuilder
    % FigureBuilder a tool used to draw figures
    %   This is the parent class to all the figures you want to build. Following are available sub-classes:
    %   ImageBuilder draws the cell graph in the XY space
    %   PlotBuilder draws the relationship between two variables, like an evolution graph, or a distribution.
    %   This is not meant to be put in an array.
    properties (Access = protected)
        title_        % string
        title_size_   % int
        title_bold_   % chararr (this is a boolean)
        title_italic_ % chararr
    end

    methods (Abstract)
        draw(obj)
        calculate(obj)
    end

    methods (Static)
        function result = optional(ret_true, ret_false, state)
            % OPTIONAL a utility function that can translate booleans to values.
            % In addition, if varargin is empty, it is treated as false.
            if size(state) == 0
                state = {true};
            end
            if state{1}
                result = ret_true;
            else
                result = ret_false;
            end
        end
    end

    methods
        function obj = FigureBuilder()
            obj.title_size_ = 12;
            obj.title_bold_ = 'normal';
            obj.title_italic_ = 'normal';
        end

        function obj = titleSize(obj, size)
            % TITLESIZE set the font size of the title.
            % Parameters:
            %   size: int
            %      the new size for the font. Default is 12.
            obj.title_size_ = size;
        end

        function obj = titleBold(obj, varargin)
            % TITLEBOLD whether the title should be bold.
            % Parameters:
            %   varargin: boolean
            %      false (default): the title has default emphasis.
            %      true  (no args): the title has bold emphasis.
            obj.title_bold_ = FigureBuilder.optional('bold', 'normal', varargin);
        end

        function obj = titleItalic(obj, varargin)
            % TITLEITALIC whether the title should be italicised.
            % Parameters:
            %   varargin: boolean
            %      false (default): the title is straight.
            %      true  (no args): the title is italicised.
            obj.title_talic_ = FigureBuilder.optional('italic', 'normal', varargin);
        end

        function obj = title(obj, text)
            % TITLE Adds a title to the figure.
            % LaTeX formatting is allowed.
            % Parameters:
            %   text: string
            %      the text to use for the title. If empty, title is
            %      cleared.
            obj.title_ = text;
        end
    end
end