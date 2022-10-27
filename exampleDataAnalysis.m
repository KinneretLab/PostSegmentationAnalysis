% example - we want to plot the mean area of the cells per frame

% load the code you want to use (this library) using this line of code
addpath('classDefinitions');

% load a movie you are intrested in. In our case, we are loading the defect library
% we save the movie in variable "movie", which we will use later.
movie = Experiment.load('Z:\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\2020_09_01_18hr_set1\Cells');

% get the target objects we want to plot - in this case, we want to plot an aspect of all the cells in the movie
target_cells = movie.cells;

f = PlotBuilder() ...            % create a plot builder - this object is responsible for defining a new plot
      .xFunction("frame") ...    % set the X axis to show the frame of each cell - this is used to also group all the cells
      .yFunction("area") ...     % set the Y axis to show the area of each cell - behind the scenes, this averages the area of cells with the same frame.
      .addData(target_cells) ... % choose the cells you want to plot in a graph. Without this, it would be an empty plot!
      .draw;                     % apply all the configurations to make a plot, and save the result (the MATLAB figure) in variable "f"

% with f saved, you can use it to do other things, like saving the figure as an image.

% as an aside, you can do all of these steps in one line of code!