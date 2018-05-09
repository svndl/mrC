function visualize_noise(pink_noise, spat_dists,surfData,SR)
% This function is just to visuaize the noise 
faces = surfData.triangles'+1;
vertices = surfData.vertices([1 3 2],:)';vertices(:,3)=200-vertices(:,3);
ROI = 200;
SavePath = 'C:\Users\Elhamkhanom\Desktop\';
mrC.Simulate.VisualizeSurface(vertices,faces,SavePath,'L',spat_dists(ROI,:),ROI);

[MSCOH, f]= mscohere(pink_noise(:,200),pink_noise(:,1:1000),200,[],[],200);
dists = spat_dists(200,1:1000);
[dists2,sortind] = sort(dists);
MSCOHS = MSCOH(:,sortind);
imagesc(MSCOHS);
end