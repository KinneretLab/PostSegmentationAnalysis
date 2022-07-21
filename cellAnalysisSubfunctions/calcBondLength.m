% Load defects and VMSI data

allSegsL = [];
allChordsL = [];
allDefectDist = {};

calibrationXY = 0.52;
for i=1:length(Struct)
    frameDefects = allDefects(i).defect;
    
   for j=1:length(Struct(i).Bdat )
       
       verts = Struct(i).Bdat(j).verts;
       rad = Struct(i).Bdat(j).radius;
       vertsX = [Struct(i).Vdat(verts).vertxcoord];
       vertsY = [Struct(i).Vdat(verts).vertycoord];
       chordC = [mean(vertsX),mean(vertsY)];
       chordL = sqrt((vertsX(1)-vertsX(2))^2+(vertsY(1)-vertsY(2))^2);
       segL = 2*rad*asin(chordL/(2*rad));
       
       chordLum = chordL*calibrationXY;
       segLum =  segL*calibrationXY;
       allChordsL = [allChordsL,segL];
       allSegsL = [ allSegsL,segL];
       defectDist = [];
       for k=1:size(frameDefects,2)
           defectDist(1,k) = sqrt(sum((frameDefects(k).position - [chordC(2),chordC(1)]).^2));
       end
       allDefectDist = [allDefectDist,defectDist];
   end
end
figure()
histogram(real(allSegsL(~isnan(allSegsL))))

figure()
[~,edges] = histcounts(log10(real(allSegsL(~isnan(allSegsL)))));
histogram(real(allSegsL(~isnan(allSegsL))),10.^edges)
set(gca, 'xscale','log','yscale','log')

figure()
[h,stats] = cdfplot(real(allSegsL(~isnan(allSegsL))));

figure()
cdfplot(real(allSegsL(~isnan(allSegsL))))
set(gca, 'xscale','log','yscale','log')


plot(cell2mat(allDefectDist),allSegsL,'.')
