classdef PresetValues %todo: maybe move becaue functionality shared with validation..
    %DROPDOWNPRESETS Summary of this class goes here
    %   Detailed explanation goes here
    
    
    
    methods (Static)
        function value = getColormaps()
            value = ["parula", "turbo", "hsv", "hot", "cool", "spring", "summer", "autumn", "winter", "gray", "bone", "copper", "pink", "lines", "jet", "colorcube", "prism", "flag"];
        end
        
        function value = getColors()
            value = ["red", "green", "blue", "cyan", "magenta", "yellow", "black", "white"];
        end
       
        function value = getMarkerShapes()
            value = ["+", "o", "*", ".", "x", "square", "diamond", "v", "^", ">", "<", "pentagram", "hexagram", "none"];
        end
    end
end

