function CreateProject(varargin)
    % Description:	Generate sensor or source space project for use with
    %               mrC.GUI (formerly mrCurrent.m) and multiple other mrC
    %               functions.
    % 
    % Syntax:	mrC.CreateProject(<options>)
    % <options>
    %   mode - string specifying the mode ([source]/sensor)
    %    
    %   templateFolder - string specifying the template folder. 
    %                    only used for sensor projects, this can be any
    %                    headless folder.
    %                    ([/Volumes/svndl/4D2/kohler/headless99])
    opt	= ParseArgsOpt(varargin,...
            'mode'		, 'source', ...
            'templateFolder', '/Volumes/svndl/4D2/kohler/headless99'...
            );
    
    if sum(strcmp(opt.mode,{'sensor','source'}))==0
        error('mode unknown: %s',opt.mode);
    else
    end
    
    projectDir = uigetdir('/Volumes/svndl/4D2/kohler', 'Source localization project folder?');
    
    polPath{1} = '/Volumes/Denali_4D2/kohler/EEG_DATA/16_groups/Polhemus';
    sIdx = 0;
    projectDone = false;
    
    while ~projectDone
        sIdx = sIdx+1;
        if strcmp(opt.mode,'source')
            tempID = inputdlg('Subject ID?','SOURCE PROJECT',1);
        else
            tempNum = inputdlg('Subject number?','SENSOR PROJECT',1,{num2str(sIdx)});
            if ~isempty(tempNum)
                tempID = sprintf('headless%02d',str2double(tempNum{1}));
            else
                tempID = [];
            end
        end
        if ~isempty(tempID)
            %% GET INFO
            if iscell(tempID)
                tempID = tempID{:};
            else
            end
            subID{sIdx}=tempID;
            exportDir{sIdx} = uigetdir('/Volumes/Denali_4D2/kohler', 'Matlab export folder?');
            %% MAKE DIRECTORIES
            if exist([projectDir,'/',subID{sIdx}],'dir');
                rmdir([projectDir,'/',subID{sIdx}], 's');
            else
            end
            mkdir([projectDir,'/',subID{sIdx}]);
            mkdir([projectDir,'/',subID{sIdx},'/_MNE_']);
            mkdir([projectDir,'/',subID{sIdx},'/_dev_']);
            mkdir([projectDir,'/',subID{sIdx},'/_mrC_']);
            mkdir([projectDir,'/',subID{sIdx},'/Inverses']);
            mkdir([projectDir,'/',subID{sIdx},'/Polhemus']);
            mkdir([projectDir,'/',subID{sIdx},'/Exp_MATL_HCN_128_Avg']);
            %% POLHEMUS
            if strcmp(opt.mode,'source')
                [polFile{sIdx},polPath{sIdx}] = uigetfile([polPath{end},'/*.elp'],[subID{sIdx},' Polhemus file?']);
                copyfile(fullfile(polPath{sIdx},polFile{sIdx}),fullfile(projectDir,subID{sIdx},'Polhemus'));
            else
                copyfile(fullfile(opt.templateFolder,'Polhemus','UnitSphere.elp'),fullfile(projectDir,subID{sIdx},'Polhemus'));
                copyfile(fullfile(opt.templateFolder,'Inverses','Identity128.inv'),fullfile(projectDir,subID{sIdx},'Inverses'));
            end
            %% copy matlab files
            RTlist = subfiles([exportDir{sIdx},'/RTSeg*']);
            if RTlist{1}
                copyfile([exportDir{sIdx},'/RTSeg*'],[projectDir,'/',subID{sIdx},'/Exp_MATL_HCN_128_Avg']);
            else
                warning('no RTSeg files')
            end
            SSNlist = subfiles([exportDir{sIdx},'/SsnHeader*']);
            if SSNlist{1}
                copyfile([exportDir{sIdx},'/SsnHeader*'],[projectDir,'/',subID{sIdx},'/Exp_MATL_HCN_128_Avg']);
            else
                warning('no session header')
            end
            copyfile([exportDir{sIdx},'/Axx*'],[projectDir,'/',subID{sIdx},'/Exp_MATL_HCN_128_Avg']);
            %% delete trial files
            curDir = pwd;
            cd([projectDir,'/',subID{sIdx},'/Exp_MATL_HCN_128_Avg'])
            delete('*trials*');
            cd(curDir);
        else
            projectDone = true;
        end
    end
    if strcmp(opt.mode,'source')
        disp('SOURCE space project created! Proceed to generating inverses!');
    else
        disp('SENSOR space project created! Project can now be viewed using mrC.GUI!');
    end
end

