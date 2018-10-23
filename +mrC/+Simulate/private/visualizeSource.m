function visualizeSource(signal,surfData,SR,spec)
    % This function is just to visuaize the signal 
    if ~exist('spec','var'), spec = 1;end
  
    faces = surfData.triangles'+1;
    vertices = surfData.vertices([1 3 2],:)';vertices(:,3)=200-vertices(:,3);
    ROI = 200;
    SavePath = 'C:\Users\Elhamkhanom\Desktop\';
    Hem = 'B';

    
    if spec ==1
        fpsignal = fft(signal,SR*2);
        ASD = abs(fpsignal(1:round(SR),:));
        %ASD = ASD./(max(ASD(:)));
        ASD = ASD./0.038;
        ASD = min(ASD,1);
        data = ASD(1:50,:);
    else
        datap = zeros(size(signal));datan = datap;data = datan;
        datap(signal>=0) = signal(signal>=0);
        datap = datap./max(datap(:));
        datan(signal<=0) = signal(signal<=0);
        datan = datan./abs(min(datan(:)));
        data(signal>=0) = datap(signal>=0);
        data(signal<=0) = datan(signal<=0);
    end
    for i = 1:round(990)
        f = i%*2;
        if spec==1
            % Surface plot of signal at a specific frequency
            Data = data(f,:);
            Data = ((Data).^1)*63;
            cmap = jmaColors('seedcortex');%jmaColors('Nebraska');
            %jet(round(max(Data(:)))+1);%hot(round(max(Data(:)))+1);
            Colors = cmap(round(Data)+1,:);
        else
            Data = (data(f,:)+1)*31+1;
            cmap = jmaColors('coolhotcortex');
            Colors = cmap(round(Data),:);
        end
        
        
        
        switch Hem
            case 'L'
                Faces = faces(1:(size(faces,1))/2,:);
            case 'R'
                Faces = faces(((size(faces,1))/2)+1:end,:);
            case 'B'
                Faces = faces;
        end
        Brain{i} =figure;
        % Brain surface
        patch('faces',Faces,'vertices',vertices,'edgecolor','none','facecolor','interp','facevertexcdata',Colors,...
             'Diffusestrength',.45,'AmbientStrength',.3,'specularstrength',.1,'FaceAlpha',.95);

        
        shading interp
        lightangle(50,120)
        lightangle(50,0)
        view(90,0)
        axis  off vis3d equal
        %text(190,100,180,['Frequency: ' num2str((f-1)/2) ' (Hz)'])
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.2, 0.24, .45, 0.65]);
        im{i} = getframe(Brain{i});
        close; 
    end
    
    %% create the video writer
 writerObj = VideoWriter(fullfile(SavePath,['signal-slow5.mp4']),'MPEG-4');
 writerObj.FrameRate =10;
 writerObj.Quality = 100;
 % open the video writer
 open(writerObj);

 % write the frames to the video
 for u=1:length(im)
     %frame = im2frame(im{u});
     writeVideo(writerObj, im{u});
 end

 % close the writer object
 close(writerObj);
    

end