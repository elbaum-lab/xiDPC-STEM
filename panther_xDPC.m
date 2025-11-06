function panther_xDPC(varargin)
% Generate different iDPC contrasts for Panter 4-quadrants, parallax corrected
% Written by Shahar Seifer & Piter Kirchweger, Elbaum lab, Weizmann Insititute of Science
% Requires MatTomo in search path (PEET project: https://bio3d.colorado.edu/imod/matlab.html).
% Images are croped 8 pixels form each side to avoid black strips in DiDPC1

p = inputParser;
    addOptional(p, 'Chosen_Filename_first', '', @(x) ischar(x)); %full path and filename
    addOptional(p, 'work_directory', '', @(x) ischar(x)); %working Directory
    addOptional(p, 'first_tiltangle_str', '0', @(x) ischar(x));
    addOptional(p, 'last_tiltangle_str', '0', @(x) ischar(x));
    addOptional(p, 'step_tiltangle_str', '0', @(x) ischar(x));
    addOptional(p, 'thetaBF_str', '0', @(x) ischar(x));
    addOptional(p, 'lambda_str', '0', @(x) ischar(x));
    addOptional(p, 'bf_disk_str', '', @(x) ischar(x));
    %rotation_tested=false if you awnt to find the rotation by curl
    %angle_ind   rotation in degrees
    
    parse(p, varargin{:});

    Chosen_Filename_first = p.Results.Chosen_Filename_first;
    work_directory = p.Results.work_directory;
    first_tiltangle_str = p.Results.first_tiltangle_str;
    last_tiltangle_str = p.Results.last_tiltangle_str;
    step_tiltangle_str = p.Results.step_tiltangle_str;
    thetaBF_str = p.Results.thetaBF_str;
    lambda_str = p.Results.lambda_str;
    bf_disk_str = p.Results.bf_disk_str;
    
% Convert string inputs to numeric values
    first_tiltangle = str2double(first_tiltangle_str);
    last_tiltangle = str2double(last_tiltangle_str);
    step_tiltangle = str2double(step_tiltangle_str);
    thetaBF = str2double(thetaBF_str);
    lambda = str2double(lambda_str);
    angle_ind=0;

flgLoadVolume=1;  % If 1 - Load in the volume data (default: 1)
showHeader=1; %  If 1 - Print out information as the header is loaded.
fprintf('I work here: %s\n', work_directory);

%%Try to write a logfile

fid = fopen(fullfile(work_directory, 'YourLogFile.txt'), 'w');
if fid == -1
  error('Cannot open log file.');
end
fprintf(fid, '%s: %s\n\n', datestr(now, 0), '####################');
fprintf(fid, 'I will work in %s\n', work_directory);
fprintf(fid, 'I call this script: %s\n', mfilename);
fprintf(fid, 'Processing of files: %s\n', Chosen_Filename_first);
fprintf(fid, 'Negative Tilt Angle: %s\n', first_tiltangle);
fprintf(fid, 'Positive Tilt Angle: %s\n', last_tiltangle);
fprintf(fid, 'Tilt steps: %s\n', step_tiltangle);
fprintf(fid, 'Semiconvergence Angle: %s\n', thetaBF);
fprintf(fid, 'Wavelength: %s\n', lambda);

%if bf_disk_str == "BF_Inner"
%    casenovector=[1];
%elseif bf_disk_str == "DF_Inner"
%    casenovector=[2];
%elseif bf_disk_str == "DF_Outer"
%    casenovector=[3];
%end
casenovector=[1 2 3];
fprintf(fid, 'BF disk is going out to the : %s\n\n\n', bf_disk_str);


for caseno=casenovector
    for channelno=1:4
        if caseno==1
            Chosen_Filename_ch=strrep(Chosen_Filename_first,'_BF-S_Inner1_',sprintf('_BF-S_Inner%d_',channelno));
            shift_log_name="BF_Inner_shifts.log";
        elseif caseno==2
            Chosen_Filename_ch=strrep(Chosen_Filename_first,'_BF-S_Inner1_',sprintf('_DF-S_Inner%d_',channelno));
            shift_log_name="DF_Inner_shifts.log";
        elseif caseno==3
            Chosen_Filename_ch=strrep(Chosen_Filename_first,'_BF-S_Inner1_',sprintf('_DF-S_Outer%d_',channelno));
            shift_log_name="DF_Outer_shifts.log";
        end
        if channelno==1
            [~,name,ext] = fileparts(Chosen_Filename_ch);
            workfile=[name,ext];
            newFilename=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_iDPC.mrc'));
            newFilename1=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_iDPC1.mrc'));
            newFilename2=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_iDPC2.mrc'));
            newFilename11=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_piDPC1_noFilt.mrc'));
            fprintf('This is the unfiltered DiDPC1 file I will write: %s\n', newFilename11)
            newFilename12=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_piDPC1_high.mrc'));
            fprintf('This is the filtered DiDPC1 file using a high number (300) I will write: %s\n', newFilename12)
            newFilename13=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_piDPC1_low.mrc'));
            fprintf('This is the filtered DiDPC1 file using a low number (50) I will write: %s\n', newFilename13)
            newFilename3=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_deshift_SUM.mrc'));
            newFilenameX=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_DPCx.mrc'));
            newFilenameY=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_DPCy.mrc'));
            newFilename4=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_plain_SUM.mrc'));
        end
    
        ntilts=(last_tiltangle-first_tiltangle)/step_tiltangle+1;
        tiltind=0;
        tiltDict = containers.Map('KeyType', 'double', 'ValueType', 'double');
        for tiltangle=first_tiltangle:step_tiltangle:last_tiltangle
            tiltind=tiltind+1;
            
            if tiltangle==0
               Chosen_Filename= Chosen_Filename_ch;
            else
               Chosen_Filename=strrep(Chosen_Filename_ch,'_tilt000',sprintf('_tilt%03d',tiltangle));
            end
            fprintf(fid, 'Working on this file: %s\n',Chosen_Filename);
            
            mRCImage = MRCImage;%Insentiate MRCImage in mRCImage
            mRCImage = open(mRCImage, Chosen_Filename, flgLoadVolume, showHeader);
            scan = getVolume(mRCImage, [], [], []);
            nX = getNX(mRCImage);
            nY = getNY(mRCImage);
            sizeXangstrom=getCellX(mRCImage);
            sizeYangstrom=getCellY(mRCImage);
            %fprintf(fid, 'The Pixelsize is: %s A\n', sizeXangstrom)
    
            if channelno==1 && tiltangle==first_tiltangle
                tilts_channels=double(zeros(nX,nY,ntilts,4));
            end
            tilts_channels(:,:,tiltind,channelno)=scan;
            fprintf(fid, 'This is the tilt number %d for tilt angle %d. \n',tiltind,tiltangle);
            tiltDict(tiltind) = tiltangle;
        end
    end %for channelno

    vnx=1:nX;
    vny=1:nY;
    [Y, X] = meshgrid( (1:nY)-(1+nY)/2,(1:nX)-(1+nX)/2);
    [y, x] = meshgrid( 1:nY,1:nX);
    kyp=Y/(nY);
    kxp=X/(nX); 
    kpnorm2=kxp.^2+kyp.^2;
    kpnorm2(kpnorm2==0)=1e-6;
    kpnorm=sqrt(kxp.^2+kyp.^2);
    shift_log = fopen(fullfile(work_directory, shift_log_name), 'w');
    if shift_log == -1;
        error('Cannot open log file.');
    end
    fprintf(shift_log, 'tilt \t angle \t Segment 1x \tSegment 1y\t Segment 2x \tSegment 2y\t Segment 3x \tSegment 3y\t Segment 4x\tSegment 4y\n');

    for tiltno=1:ntilts
        fprintf('tiltno=%d\n',tiltno);
        %fprintf(fid, 'Working on this file: %s\n',Chosen_Filename);
        fprintf(fid, 'tiltno=%d\n',tiltno);
        img1=tilts_channels(:,:,tiltno,1);
        img2=tilts_channels(:,:,tiltno,2);
        img3=tilts_channels(:,:,tiltno,3);
        img4=tilts_channels(:,:,tiltno,4);
        %%%%%%%%%% ORDER matters %%%%%%%%%%%%%
        img_grady=(img1+img2-img3-img4);
        img_gradx=img2-img1+img3-img4;
        
        

        %        if ~rotation_tested
        %            fprintf(fid, 'Now I calculate the rotation\n')
        %            angle_vect=0:1:175;
        %            angle_curl=zeros(size(angle_vect));
        %            for angind=1:length(angle_vect)
        %                angle_ind=angle_vect(angind);
        %                comx_rot=img_gradx*cos(angle_ind*pi/180)-img_grady*sin(angle_ind*pi/180);
        %                comy_rot=+img_gradx*sin(angle_ind*pi/180)+img_grady*cos(angle_ind*pi/180);
        %                rangeofint=sqrt(X.^2+Y.^2)<1*max(abs(X(:)));
        %                [curlz,cav] = curl(comx_rot'.*rangeofint,comy_rot'.*rangeofint);
        %                %[curlz,cav] = curl(comx_rot,comy_rot);%x_mat,y_mat,
        %                angle_curl(angind)=mean(abs(curlz(:)));
        %            end
        %            figure(101)
        %            plot(angle_vect,abs(angle_curl),'-');
        %            xlabel('Angle [deg]');
        %            ylabel('mean CURL');
        %            saveas(gcf, fullfile(full_path, 'Rotation_plot.png'));
        %            angle_ind=min(angle_vect(abs(angle_curl)==min(abs(angle_curl))));
        %            disp(sprintf('Rotation angle of COM according to CURL [deg]: %d',angle_ind));
        %            fprintf(fid, 'Rotation angle of COM according to CURL [deg]: %d\n',angle_ind)
        %            
        %            rotation_tested=true;
        %        end
        fprintf(fid, 'Rotation angle of COM is [deg]: %d\n',angle_ind)
        
        temp_img_gradx=img_gradx*cos(angle_ind*pi/180)-img_grady*sin(angle_ind*pi/180);
        temp_img_grady=+img_gradx*sin(angle_ind*pi/180)+img_grady*cos(angle_ind*pi/180);
        img_gradx=temp_img_gradx;
        img_grady=temp_img_grady;

        sumval=tilts_channels(:,:,tiltno,1)+tilts_channels(:,:,tiltno,2)+tilts_channels(:,:,tiltno,3)+tilts_channels(:,:,tiltno,4);
        factor=(0.25*pi*sin(thetaBF)/lambda)/max(sumval(:));
        %iDPC=2*pi*dx_pix*intgrad2(factor.*img_grady,factor.*img_gradx);
        iDPCfft=(1/(1i*2*pi))*((kxp.*(ifftshift(fft2(fftshift(img_gradx))))+kyp.*(ifftshift(fft2(fftshift(img_grady)))).*(1-1*(abs(kpnorm2)<0.000000001))))./kpnorm2;
        iDPC=real(ifftshift(ifft2(fftshift(iDPCfft))));
    
        iDPC_LP=imgaussfilt(iDPC,50);
        iDPC_BP=iDPC-iDPC_LP;
        tiltCOMx(:,:,tiltno)=img_gradx(9:end-8,9:end-8);%/max(sumval(:));
        tiltCOMy(:,:,tiltno)=img_grady(9:end-8,9:end-8);%/max(sumval(:));
        iDPCtilt(:,:,tiltno)=iDPC_BP(9:end-8,9:end-8);
    
        [corr_offset(1,:),corr_offset(2,:),corr_offset(3,:),corr_offset(4,:)]=deshift(img1,img2,img3,img4); %regularly use deshift function , otherwise: deshift_ultramag
        shift_avg_pix=(corr_offset(1,1)-corr_offset(1,2)+corr_offset(2,1)+corr_offset(2,2)-corr_offset(3,1)+corr_offset(3,2)-corr_offset(4,1)-corr_offset(4,2))/8;
        tryshift=shift_avg_pix;
        img1_deshift=imtranslate(img1,-corr_offset(1,:));
        img2_deshift=imtranslate(img2,-corr_offset(2,:));
        img3_deshift=imtranslate(img3,-corr_offset(3,:));
        img4_deshift=imtranslate(img4,-corr_offset(4,:));
        
        if isKey(tiltDict, tiltno)
            angle = tiltDict(tiltno);
            fprintf(shift_log,'%d\t%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', tiltno,angle,corr_offset(1,1),corr_offset(1,2),corr_offset(2,1),corr_offset(2,2),corr_offset(3,1),corr_offset(3,2),corr_offset(4,1),corr_offset(4,2));
        else
            fprintf(shift_log,'%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', tiltno,corr_offset(1,1),corr_offset(1,2),corr_offset(2,1),corr_offset(2,2),corr_offset(3,1),corr_offset(3,2),corr_offset(4,1),corr_offset(4,2));
            fprintf(shift_log,"Not Working!!");
        end
        
        %%%%%%%%%% ORDER matters %%%%%%%%%%%%%
        img_grady_shifted=(img1_deshift+img2_deshift-img3_deshift-img4_deshift);
        img_gradx_shifted=img2_deshift-img1_deshift+img3_deshift-img4_deshift;

        temp_img_gradx=img_gradx_shifted*cos(angle_ind*pi/180)-img_grady_shifted*sin(angle_ind*pi/180);
        temp_img_grady=+img_gradx_shifted*sin(angle_ind*pi/180)+img_grady_shifted*cos(angle_ind*pi/180);
        img_gradx_shifted=temp_img_gradx;
        img_grady_shifted=temp_img_grady;
        
        %iDPC1=2*pi*dx_pix*intgrad2(factor.*img_grady_shifted,factor.*img_gradx_shifted);
        iDPC1fft=(1/(1i*2*pi))*((kxp.*(ifftshift(fft2(fftshift(img_gradx_shifted))))+kyp.*(ifftshift(fft2(fftshift(img_grady_shifted)))).*(1-1*(abs(kpnorm2)<0.000000001))))./kpnorm2;
        iDPC1=real(ifftshift(ifft2(fftshift(iDPC1fft))));
        iDPC1_LP=mean(iDPC1(:));
        %iDPC1_LP=imgaussfilt(iDPC1,50);
        iDPC1_BP=iDPC1-iDPC1_LP;
        iDPC1tilt(:,:,tiltno)=iDPC1_BP(9:end-8,9:end-8);
        iDPC2=iDPC-iDPC1;
        iDPC2_LP=mean(iDPC2(:));
        %iDPC2_LP=imgaussfilt(iDPC2,50);
        iDPC2_BP=iDPC2-iDPC2_LP;
        iDPC2tilt(:,:,tiltno)=iDPC2_BP(9:end-8,9:end-8);
        sum_deshifted(:,:,tiltno)=(img1_deshift(9:end-8,9:end-8)+img2_deshift(9:end-8,9:end-8)+img3_deshift(9:end-8,9:end-8)+img4_deshift(9:end-8,9:end-8))/4;
        sum_noshifted(:,:,tiltno)=(img1(9:end-8,9:end-8)+img2(9:end-8,9:end-8)+img3(9:end-8,9:end-8)+img4(9:end-8,9:end-8))/4;
    
        img1_deshift=imtranslate(img1,-corr_offset(1,:)-[1 -1]);
        img2_deshift=imtranslate(img2,-corr_offset(2,:)-[1 1]);
        img3_deshift=imtranslate(img3,-corr_offset(3,:)-[-1 1]);
        img4_deshift=imtranslate(img4,-corr_offset(4,:)-[-1 -1]);
        img_grady_shifted=(img1_deshift+img2_deshift-img3_deshift-img4_deshift);
        img_gradx_shifted=img2_deshift-img1_deshift+img3_deshift-img4_deshift;

        comx_rotj=img_gradx_shifted*cos(angle_ind*pi/180)-img_grady_shifted*sin(angle_ind*pi/180);
        comy_rotj=+img_gradx_shifted*sin(angle_ind*pi/180)+img_grady_shifted*cos(angle_ind*pi/180);
        img_gradx_shifted=comx_rotj;
        img_grady_shifted=comy_rotj;
        
        %iDPC11=2*pi*dx_pix*intgrad2(factor.*img_grady_shifted,factor.*img_gradx_shifted);
        iDPC11fft=(1/(1i*2*pi))*((kxp.*(ifftshift(fft2(fftshift(img_gradx_shifted))))+kyp.*(ifftshift(fft2(fftshift(img_grady_shifted)))).*(1-1*(abs(kpnorm2)<0.000000001))))./kpnorm2;
        iDPC11=real(ifftshift(ifft2(fftshift(iDPC11fft))));
        
        DiDPC1=iDPC1-iDPC11;
        DiDPC1_mean=mean(DiDPC1(:));
        DiDPC1_LP_low=imgaussfilt(DiDPC1,50);
        DiDPC1_LP_high=imgaussfilt(DiDPC1,300);
        DiDPC1_BP_low=imgaussfilt(DiDPC1-DiDPC1_LP_low,1);
        DiDPC1_BP_high=imgaussfilt(DiDPC1-DiDPC1_LP_high,1);
        DiDPC1_meansubt=imgaussfilt(DiDPC1-DiDPC1_mean,1);
        iDPC11tilt(:,:,tiltno)=DiDPC1_meansubt(9:end-8,9:end-8);
        iDPC12tilt(:,:,tiltno)=DiDPC1_BP_high(9:end-8,9:end-8);
        iDPC13tilt(:,:,tiltno)=DiDPC1_BP_low(9:end-8,9:end-8);
    end %for tiltno
    
    fclose(shift_log);
    newmRCImage = MRCImage;%Instentiate MRCImage object
    newmRCImage.filename=newFilenameX;
    newmRCImage = setVolume(newmRCImage, tiltCOMx); %enter to newmRCImage, do statistics, and fill many details to the header
    newmRCImage.header.cellDimensionX = sizeXangstrom;
    newmRCImage.header.cellDimensionY = sizeYangstrom;
    save(newmRCImage, newFilenameX);
    fprintf(fid, '\nI have written the DPCx file: %s\n', newFilenameX)
    close(newmRCImage);
    newmRCImage = MRCImage;%Instentiate MRCImage object
    newmRCImage.filename=newFilenameY;
    newmRCImage = setVolume(newmRCImage, tiltCOMy); %enter to newmRCImage, do statistics, and fill many details to the header
    newmRCImage.header.cellDimensionX = sizeXangstrom;
    newmRCImage.header.cellDimensionY = sizeYangstrom;
    save(newmRCImage, newFilenameY);
    fprintf(fid, 'I have written the DPCy file: %s\n', newFilenameY)
    close(newmRCImage);
    if false
        newmRCImage = MRCImage;%Instentiate MRCImage object
        newmRCImage.filename=newFilename;
        newmRCImage = setVolume(newmRCImage, iDPCtilt); %enter to newmRCImage, do statistics, and fill many details to the header
        newmRCImage.header.cellDimensionX = sizeXangstrom;
        newmRCImage.header.cellDimensionY = sizeYangstrom;
        save(newmRCImage, newFilename);
        fprintf(fid, '\nI have written the iDPC file: %s\n', newFilename)
        close(newmRCImage);

        newmRCImage = MRCImage;%Instentiate MRCImage object
        newmRCImage.filename=newFilename1;
        newmRCImage = setVolume(newmRCImage, iDPC1tilt); %enter to newmRCImage, do statistics, and fill many details to the header
        newmRCImage.header.cellDimensionX = sizeXangstrom;
        newmRCImage.header.cellDimensionY = sizeYangstrom;
        save(newmRCImage, newFilename1);
        fprintf(fid, 'I have written the iDPC1 file: %s\n', newFilename1)
        close(newmRCImage);
    end
    
    newmRCImage = MRCImage;%Instentiate MRCImage object
    newmRCImage.filename=newFilename11;
    newmRCImage = setVolume(newmRCImage, iDPC11tilt); %enter to newmRCImage, do statistics, and fill many details to the header
    newmRCImage.header.cellDimensionX = sizeXangstrom;
    newmRCImage.header.cellDimensionY = sizeYangstrom;
    save(newmRCImage, newFilename11);
    fprintf(fid, 'I have written the unfiltered piDPC file: %s\n', newFilename11)
    close(newmRCImage);
    
    if false
        newmRCImage = MRCImage;%Instentiate MRCImage object
        newmRCImage.filename=newFilename12;
        newmRCImage = setVolume(newmRCImage, iDPC12tilt); %enter to newmRCImage, do statistics, and fill many details to the header
        newmRCImage.header.cellDimensionX = sizeXangstrom;
        newmRCImage.header.cellDimensionY = sizeYangstrom;
        save(newmRCImage, newFilename12);
        fprintf(fid, 'I have written the filtered piDPC using a high number (300) file: %s\n', newFilename12)
        close(newmRCImage);

        newmRCImage = MRCImage;%Instentiate MRCImage object
        newmRCImage.filename=newFilename13;
        newmRCImage = setVolume(newmRCImage, iDPC13tilt); %enter to newmRCImage, do statistics, and fill many details to the header
        newmRCImage.header.cellDimensionX = sizeXangstrom;
        newmRCImage.header.cellDimensionY = sizeYangstrom;
        save(newmRCImage, newFilename13);
        fprintf(fid, 'I have written the filtered piDPC using a low number (50)  file: %s\n', newFilename13)
        close(newmRCImage);

        newmRCImage = MRCImage;%Instentiate MRCImage object
        newmRCImage.filename=newFilename2;
        newmRCImage = setVolume(newmRCImage, iDPC2tilt); %enter to newmRCImage, do statistics, and fill many details to the header
        newmRCImage.header.cellDimensionX = sizeXangstrom;
        newmRCImage.header.cellDimensionY = sizeYangstrom;
        save(newmRCImage, newFilename2);
        fprintf(fid, 'I have written the iDPC2 file: %s\n', newFilename2)
        close(newmRCImage);
    end
    
    newmRCImage = MRCImage;%Instentiate MRCImage object
    newmRCImage.filename=newFilename3;
    newmRCImage = setVolume(newmRCImage, sum_deshifted); %enter to newmRCImage, do statistics, and fill many details to the header
    newmRCImage.header.cellDimensionX = sizeXangstrom;
    newmRCImage.header.cellDimensionY = sizeYangstrom;
    save(newmRCImage, newFilename3);
    fprintf(fid, 'I have written the deshifted_SUM file: %s\n', newFilename3)
    close(newmRCImage);
    
    newmRCImage = MRCImage;%Instentiate MRCImage object
    newmRCImage.filename=newFilename4;
    newmRCImage = setVolume(newmRCImage, sum_noshifted); %enter to newmRCImage, do statistics, and fill many details to the header
    newmRCImage.header.cellDimensionX = sizeXangstrom;
    newmRCImage.header.cellDimensionY = sizeYangstrom;
    save(newmRCImage, newFilename4);
    fprintf(fid, 'I have written the plain_SUM file: %s\n', newFilename4)
    close(newmRCImage);
    
        
end %for caseno

seg_sub_folder = fullfile(work_directory, 'Segments');
if not(isfolder(seg_sub_folder))
    mkdir(seg_sub_folder);
    movefile(fullfile(work_directory,'*tilt*.mrc'), seg_sub_folder);
end %for making the Segments folder

end
