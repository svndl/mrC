function [ input ] = AddCorr( input , subjId ,type)
    % Description:	Add ROI correlations to forward or inverse
    %
    % Syntax:	sol = mrC.AddCorr( sol , subjId , type )
    % In:
    if nargin < 3
        type = 'func';
    else
    end
    
    anatDir = getpref('mrCurrent','AnatomyFolder');
    meshDir = fullfile( anatDir, subjId, 'Standard', 'meshes' );
    if strcmp(type, 'func')
        ROIcorrFile = fullfile( meshDir, 'ROIs_correlation.mat' );
    elseif strfind(type,'wang')
        ROIcorrFile = fullfile( meshDir, 'WANG_correlation.mat' );
    else
        error(['Unknown ROI type: ',type])
    end 
    
    load(ROIcorrFile);
    
    if find( size(input) == 128) == 1
        % forward mode
        for k = 1 : length( ROIs.name )
            input( : , ROIs.ndx{ k } ) =  input( : , ROIs.ndx{ k } ) * chol( ROIs.corr{ k } )';
        end
    elseif find( size(input) == 128) == 2
        % inverse mode
        for k = 1 : length( ROIs.name )
            input( ROIs.ndx{ k } , : ) =  chol( ROIs.corr{ k } )' * input( ROIs.ndx{ k } , : );
        end
    else
        error('unexpected input dimensions!');
    end
end


    

    
