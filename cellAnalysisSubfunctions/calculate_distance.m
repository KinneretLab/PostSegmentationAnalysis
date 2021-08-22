function [all_t,all_xcoor] = calculate_distance(vertices,orig,direction,faces)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

faces = faces;
% all_intersect ={};
all_t = [];
all_xcoor = [];

vert1 = vertices(faces(:,1),:);
vert2 = vertices(faces(:,2),:);
vert3 = vertices(faces(:,3),:);

for i = 1:length(orig)
 % for i = 1:1000
    this_orig  = orig(i,:);       % ray's origin
    this_dir   = direction (i,:);         % ray's direction
    
   [intersect,t,u,v,xcoor] = TriangleRayIntersection(this_orig, this_dir, vert1, vert2, vert3);
%    all_intersect(i) = find(intersect);
    all_t(i,:) = mean(t(find(intersect)));
    all_xcoor(i,:) = mean(xcoor(find(intersect)));
    if mod(i,1000)== 0
     i
    end
     
end

end

