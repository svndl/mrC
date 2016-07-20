function NodeDemo(varargin)
    opt	= ParseArgs(varargin,...
        'figFolder'     , '/Users/kohler/Desktop/',...
        'testSub' , 'nl-0014'...
        );
    nodeNum = 20484;
    divNum = 36;
    baseNum = nodeNum/divNum;
    simData = repmat(1:baseNum,1,divNum)';
    simData = simData(randperm(nodeNum));
    mrC.WriteNiml(opt.testSub,simData,'outpath',fullfile(opt.figFolder,sprintf('%s_nodeDemo.niml.dset',opt.testSub)),'std_surf',false,'doSmooth',false,'interpolate',false);
    mrC.WriteNiml('nl-0014',simData,'outpath',fullfile(opt.figFolder,sprintf('%s_nodeDemo_interp.niml.dset',opt.testSub)),'std_surf',false,'doSmooth',false,'interpolate',true); 
end

