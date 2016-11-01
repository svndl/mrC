function [dataOut,dataLabels] = TextImport(datafile)
    
    % column headers of the data file
    hdrFields = {
        'iSess'         '%s\t'      0 %1
        'iCond'         '%f\t'      1 %2
        'iTrial'        '%f\t'      1 %3
        'iCh'           '%s\t'      1 %4 This becomes %f later in the function
        'iFr'           '%f\t'      1 %5
        'AF'            '%f\t'      1 %6
        'xF1'           '%f\t'      1 %7
        'xF2'           '%f\t'      1 %8
        'Harm'          '%s\t'      2 %9 
        'FK_Cond'       '%f\t'      1 %10
        'iBin'          '%f\t'      1 %11
        'SweepVal'      '%f\t'      1 %12
        'Sr'            '%f\t'      1 %13
        'Si'            '%f\t'      1 %14
        'N1r'           '%f\t'      1 %15
        'N1i'           '%f\t'      1 %16
        'N2r'           '%f\t'      1 %17
        'N2i'           '%f\t'      1 %18
        'Signal'        '%f\t'      1 %19
        'Phase'         '%f\t'      1 %20
        'Noise'         '%f\t'      1 %21
        'StdErr'        '%f\t'      1 %22
        'PVal'          '%f\t'      1 %23
        'SNR'           '%f\t'     2 %24
        'LSB'           '%f\t'     2 %25
        'RSB'           '%f\t'     2 %26
        'UserSc'        '%s\t'     2 %27
        'Thresh'        '%f\t'     2 %28
        'ThrBin'        '%f\t'     2 %29
        'Slope'         '%f\t'     2 %30
        'ThrInRange'    '%s\t'     2 %31
        'MaxSNR'        '%f\t'     2 };%32

    channelIx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x,'iCh')),hdrFields(:,1),'uni',false)));
    harmIx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x,'Harm')),hdrFields(:,1),'uni',false)));
    freqIx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x,'iFr5')),hdrFields(:,1),'uni',false)));
    
    %% OPEN DATA FILE
    fid=fopen(datafile);
    tline=fgetl(fid); % skip the header line
    dataOut=textscan(fid, [hdrFields{:,2}], 'delimiter', '\t', 'EmptyValue', nan);
    
    %% MAKE CHANNELS FLOATS
    currIndex = 1;
    % If the naming convention of the channels in the data set is 'hc%d', the
    % returned channelNameDict will be empty. Otherwise, if the naming
    % convention of the channels is something other than 'hc%d',
    % channelNameDict will not be empty and will map string names to double
    % values
    channelNameDict = containers.Map;
    for i=1:size(dataOut{1,4})
        currChanName = dataOut{1,4}{i};
        % Need to make new name for the weird channel naming
        if ~strcmp(currChanName(1:2), 'hc')
            if ~any(strcmp(keys(channelNameDict), currChanName))
                channelNameDict(currChanName) = currIndex;
                currIndex = currIndex + 1;
                chan{1,i} = channelNameDict(currChanName);
            else
                chan{1,i} = channelNameDict(currChanName);
            end
        % Otherwise, just parse channel name
        else
            chan{1,i}=sscanf(dataOut{1, 4}{i}, 'hc%d'); 
        end
    end
    dataOut{1,channelIx}=cell2mat(chan');
    dataLabels = hdrFields(:,1);
    fclose(fid);
end

