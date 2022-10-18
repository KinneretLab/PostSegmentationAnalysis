classdef Utilities
    %UNTITLED Summary of this class goes here
    
    methods (Static)        
        function background_image = getBackground(obj)
            background_image={};
            [file,path] = uigetfile('*.png;*.tiff;*.jpg;*.jpeg', 'Select One or More Files', ...
                'MultiSelect', 'on');
            if(isa(file,'char'))
                 fname = [path file];
                 background_image=imread(fname);
            else
                [~ ,num_of_files]=size(file);
                for i= 1:num_of_files
                    fname = [path file{i}];
                    background_image{i}=imread(fname);
                end
            end
        end
    end
end

