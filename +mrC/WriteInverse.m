function inverseStruct = WriteInverse( inverseMatrix,filename )
    % function inverseStruct=mrC.WriteInverse( inverseMatrix, filename )
    % Writes an inverse file in EMSE (.elp) format
    % Written by Justin Ales, latest revision 1.3 2008/06/18 17:35:06
    
    fid=fopen(filename,'wb','ieee-le');

    if (~fid)
        error('Could not open file');
    end

    [nSources nElectrodes] = size(inverseMatrix);

    header = ['454d5345\t4\t1\t5\n200000\t1000\t20020042\n1\t127\n' num2str(nSources) '\t' num2str(nElectrodes) '\n'];
    disp(header)
    sprintf(header)

    % Write the header
    fprintf(fid,header);

    % Write the data, doing explicit row wise writes, matlab default to coloumn wise.
    for iRow=1:nSources,
           fwrite(fid,inverseMatrix(iRow,:),'float64'); % Note, this also works with 'inf' bytes so we know that we are in the correct location in the file (since we can read to the end)
    end
    % new Emse has XMLie stuff at the end, 
    xmlString = ['<JMAtst>''\n''<WhoMade>MatlabMade</WhoMade>''\n''</JMAtst>'];
    fprintf(fid,xmlString);
    fclose(fid);
    inverseStruct = [];
end

