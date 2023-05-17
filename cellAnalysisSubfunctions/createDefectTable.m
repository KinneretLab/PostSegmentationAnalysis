function [] = createDefectTable(mainDir,segDir,cellDir,frameList,useCenter)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
         dirDataDefect=[mainDir,'\Dynamic_Analysis\Defects'];
         mkdir([mainDir,'\Dynamic_Analysis\']);
         mkdir(dirDataDefect);
         dirLocalOP = [mainDir,'\Orientation_Analysis\LocalOP']; % masked local order parameter field
         cd([mainDir,'\Orientation_Analysis']); load('resultsGroundTruth');
         
         cd(segDir); fileNames=dir ('*.tif*');
         sortedFileNames = natsortfiles({fileNames.name});
         
         defectCount = 0;
         frame = {};
         x_pos = {};
         y_pos = {};
         type = {};
         defect_id = {};
         
         
         if isempty(frameList)
             frames = 1:length(sortedFileNames);
         else
             frames = frameList;
         end
         
         % Extract defect data from GTL format (manual marking)
         for k=frames  % loop on all frames
             display(['Reading data for frame ',num2str(k)])
             thisFile=sortedFileNames{k}; % find this frame's file name
             endName=strfind(thisFile,'.');
             thisFileImNameBase = thisFile (1:endName-1); %without the .filetype
             extractAllDefects(k, dirLocalOP, thisFileImNameBase,gTruth,dirDataDefect,useCenter);
             load([dirDataDefect,'\',thisFileImNameBase,'.mat']);
             % Separate 'defect' into two lines and assign frame
             for m = 1:length(defect)
                 defectCount = defectCount+1;
                 frame{defectCount,1} = k;
                 x_pos{defectCount,1} = defect(m).position(1);
                 y_pos{defectCount,1} = defect(m).position(2);
                 type{defectCount,1} = defect(m).type;
                 defect_id{defectCount,1} = defect(m).ID;
             end
         end
         defects = table(frame, x_pos, y_pos, type, defect_id);
         clear('frame', 'x_pos', 'y_pos', 'type', 'defect_id');
         cd(cellDir); writetable(defects,'defects.csv')
end

