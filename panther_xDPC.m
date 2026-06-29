function panther_xDPC_PK(varargin)
% Generate different iDPC contrasts for Panter 4-quadrants, parallax corrected
% Written by Shahar Seifer & Peter Kirchweger, Elbaum lab, Weizmann Insititute of Science
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

casenovector=[1 2 3];
%fprintf(fid, 'BF disk is going out to the : %s\n\n\n', bf_disk_str);


for caseno=casenovector
    if bf_disk_str == "BF_Inner"
        lastno_iDPC=1;
    elseif bf_disk_str == "DF_Inner"
        lastno_iDPC=2;
    elseif bf_disk_str == "DF_Outer"
        lastno_iDPC=3;
    else
        lastno_iDPC=3;
    end
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
            newFilename11=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_piDPC1.mrc'));
            newFilename12=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_piDPC1_high.mrc'));
            newFilename13=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_piDPC1_low.mrc'));
            newFilename3=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_pBF.mrc'));
            newFilenameX=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_DPCx.mrc'));
            newFilenameY=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_DPCy.mrc'));
            newFilename4=fullfile(work_directory, strrep(workfile,'1_tilt000.mrc','_sBF.mrc'));
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
    if shift_log == -1
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
        sum_noshifted(:,:,tiltno)=(img1(9:end-8,9:end-8)+img2(9:end-8,9:end-8)+img3(9:end-8,9:end-8)+img4(9:end-8,9:end-8))/4;
        
        if caseno<=lastno_iDPC
        
          %Here it is worthwhile to generate different iDPC contrasts
                
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
      
        end %if caseno<=lastno_iDPC

    
    end %for tiltno
      
    fclose(shift_log);
      
      
    if caseno<=lastno_iDPC
         if false
            newmRCImage = MRCImage;%Instentiate MRCImage object
            newmRCImage = setFilename(newmRCImage, newFilenameX);  % Set the output filename
            newmRCImage = setVolume(newmRCImage, tiltCOMx); %enter to newmRCImage, do statistics, and fill many details to the header
            setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
            save(newmRCImage, newFilenameX);
            fprintf(fid, '\nI have written the DPCx file: %s\n', newFilenameX)
            close(newmRCImage);
            
            newmRCImage = MRCImage;%Instentiate MRCImage object
            newmRCImage = setFilename(newmRCImage, newFilenameY);  % Set the output filename
            newmRCImage = setVolume(newmRCImage, tiltCOMy); %enter to newmRCImage, do statistics, and fill many details to the header
            setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
            save(newmRCImage, newFilenameY);
            fprintf(fid, 'I have written the DPCy file: %s\n', newFilenameY)
            close(newmRCImage);
    end
        newmRCImage = MRCImage;%Instentiate MRCImage object
            newmRCImage = setFilename(newmRCImage, newFilename);  % Set the output filename
            newmRCImage = setVolume(newmRCImage, iDPCtilt); %enter to newmRCImage, do statistics, and fill many details to the header
            setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
            save(newmRCImage, newFilename);
            fprintf(fid, '\nI have written the iDPC file: %s\n', newFilename)
            close(newmRCImage);
    
            newmRCImage = MRCImage;%Instentiate MRCImage object
            newmRCImage = setFilename(newmRCImage, newFilename1);
            newmRCImage = setVolume(newmRCImage, iDPC1tilt); %enter to newmRCImage, do statistics, and fill many details to the header
            setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
            save(newmRCImage, newFilename1);
            fprintf(fid, 'I have written the iDPC1 file: %s\n', newFilename1)
            close(newmRCImage);
        
        
        newmRCImage = MRCImage;%Instentiate MRCImage object
        newmRCImage = setFilename(newmRCImage, newFilename11);
        newmRCImage = setVolume(newmRCImage, iDPC11tilt); %enter to newmRCImage, do statistics, and fill many details to the header
        setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
        save(newmRCImage, newFilename11);
        fprintf(fid, 'I have written the unfiltered piDPC file: %s\n', newFilename11)
        close(newmRCImage);
        
        if false
            newmRCImage = MRCImage;%Instentiate MRCImage object
            newmRCImage = setFilename(newmRCImage, newFilename12);
            newmRCImage = setVolume(newmRCImage, iDPC12tilt); %enter to newmRCImage, do statistics, and fill many details to the header
            setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
            save(newmRCImage, newFilename12);
            fprintf(fid, 'I have written the filtered piDPC using a high number (300) file: %s\n', newFilename12)
            close(newmRCImage);
    
            newmRCImage = MRCImage;%Instentiate MRCImage object
            newmRCImage = setFilename(newmRCImage, newFilename13);
            newmRCImage = setVolume(newmRCImage, iDPC13tilt); %enter to newmRCImage, do statistics, and fill many details to the header
            setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
            save(newmRCImage, newFilename13);
            fprintf(fid, 'I have written the filtered piDPC using a low number (50)  file: %s\n', newFilename13)
            close(newmRCImage);
        end
            newmRCImage = MRCImage;%Instentiate MRCImage object
            newmRCImage = setFilename(newmRCImage, newFilename2);
            newmRCImage = setVolume(newmRCImage, iDPC2tilt); %enter to newmRCImage, do statistics, and fill many details to the header
            setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
            save(newmRCImage, newFilename2);
            fprintf(fid, 'I have written the iDPC2 file: %s\n', newFilename2)
            close(newmRCImage);
        
        
        newmRCImage = MRCImage;%Instentiate MRCImage object
        newmRCImage = setFilename(newmRCImage, newFilename3);
        newmRCImage = setVolume(newmRCImage, sum_deshifted); %enter to newmRCImage, do statistics, and fill many details to the header
        setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
        save(newmRCImage, newFilename3);
        fprintf(fid, 'I have written the deshifted_SUM file: %s\n', newFilename3)
        close(newmRCImage);
      
    end %if caseno<=lastno_iDPC
    
    
    newmRCImage = MRCImage;%Instentiate MRCImage object
    newmRCImage = setFilename(newmRCImage, newFilename4);
    newmRCImage = setVolume(newmRCImage, sum_noshifted); %enter to newmRCImage, do statistics, and fill many details to the header
    setPixelSize(newmRCImage, sizeXangstrom, sizeYangstrom, sizeYangstrom);
    save(newmRCImage, newFilename4);
    fprintf(fid, 'I have written the plain_SUM file: %s\n', newFilename4)
    close(newmRCImage);
    
        
end %for caseno

seg_sub_folder = fullfile(work_directory, 'Segments');
if ~isfolder(seg_sub_folder)
    mkdir(seg_sub_folder); 
end %for making the Segments folder
movefile(fullfile(work_directory,'*tilt*.mrc'), seg_sub_folder);
end


%Written by Shahar Seifer, 2021, Elbaum lab, Weizmann Institute of Science
function [r1,r2,r3,r4]=deshift(im1,im2,im3,im4)
    shift_limit=50;
    do_filt=1;
    r21=r_mn(im2,im1,shift_limit,do_filt);
    r12=-r21;
    r31=r_mn(im3,im1,shift_limit,do_filt);
    r13=-r31;
    r41=r_mn(im4,im1,shift_limit,do_filt);
    r14=-r41;
    r32=r_mn(im3,im2,shift_limit,do_filt);
    r23=-r32;
    r42=r_mn(im4,im2,shift_limit,do_filt);
    r24=-r42;
    r43=r_mn(im4,im3,shift_limit,do_filt);
    r34=-r43;
    A=r21+r31+r41;
    B=r12+r32+r42;
    C=r13+r23+r43;
    D=r14+r24+r34;
    Mfull=[3 -1 -1 -1; -1 3 -1 -1; -1 -1 3 -1; -1 -1 -1 3];
    Mpart=[3 -1 -1; -1 3 -1; -1 -1 3];
    invM=pinv(Mfull); %Moore-Penrose pseudoinverse, effectively 
    rx=invM*[A(2) B(2) C(2) D(2)]';
    ry=invM*[A(1) B(1) C(1) D(1)]';
    zx=Mfull*rx;
    zy=Mfull*ry;
    err1=sqrt(abs(zx(1)-A(2))^2+abs(zy(1)-A(1))^2);
    err2=sqrt(abs(zx(2)-B(2))^2+abs(zy(2)-B(1))^2);
    err3=sqrt(abs(zx(3)-C(2))^2+abs(zy(3)-C(1))^2);
    err4=sqrt(abs(zx(4)-D(2))^2+abs(zy(4)-D(1))^2);
    %disp(sprintf('errors: %g,%g,%g,%g',err1,err2,err3,err4));%very low so removed
    disp(sprintf('Shifts r21=%g',r21));
    r1=[rx(1) ry(1)];
    r2=[rx(2) ry(2)];
    r3=[rx(3) ry(3)];
    r4=[rx(4) ry(4)];
    
end
%####################################################
function r_mn=r_mn(Imagem,Imagen,shift_limit,do_filt)
    if do_filt==1
        Imagem=imgaussfilt(Imagem-imgaussfilt(Imagem,30),3);
        Imagen=imgaussfilt(Imagen-imgaussfilt(Imagen,30),3);
    end

    figure(2);
    subplot(1,2,1);
    balanced_imshow(Imagem);
    subplot(1,2,2);
    balanced_imshow(Imagen);
    tempx=floor(0.3*size(Imagem,1));  % x are the row number, y is the col number (as observed with balanced_imshow). The rows progress along the first ordinate in Imagem/n.
    tempy=floor(0.3*size(Imagem,2));
    tempux=size(Imagem,1)-tempx;%floor(0.85*size(Imagem,1));
    tempuy=size(Imagem,2)-tempy;%floor(0.7*size(Imagem,2));
    view_in=Imagem(tempx:tempux,tempy:tempuy);
    correlationOutput = normxcorr2(view_in,Imagen);
    [maxCorrValue, maxIndex] = max(abs(correlationOutput(:)));
    [xpeak, ypeak] = ind2sub(size(correlationOutput),maxIndex(1));%find(correlationOutput==max(correlationOutput(:)));  xpeak is the row number
    yoffset = ypeak-tempuy;
    xoffset = xpeak-tempux;
    if abs(yoffset)>shift_limit || abs(xoffset)>shift_limit
        correlationOutput = normxcorr2(imgaussfilt(view_in,10),imgaussfilt(Imagen,10));
        [maxCorrValue, maxIndex] = max(abs(correlationOutput(:)));
        [xpeak, ypeak] = ind2sub(size(correlationOutput),maxIndex(1));%find(correlationOutput==max(correlationOutput(:)));
        yoffset = ypeak-tempuy;
        xoffset = xpeak-tempux;
        if abs(yoffset)>shift_limit || abs(xoffset)>shift_limit
            r_mn=[0 0];
        else
            r_mn=[xoffset yoffset];
        end
        disp('Only rough shift estimate')
        return;
    end
    %refine to subpixel
    sample16=correlationOutput(xpeak-7:xpeak+8,ypeak-7:ypeak+8);
    Intsample16=fftInterpolate(sample16,[512 512]);
    [maxCorrValue2, maxIndex2] = max(abs(Intsample16(:)));
    [xpeak2, ypeak2] = ind2sub(size(Intsample16),maxIndex2(1));%find(Intsample16==max(Intsample16(:)));
    yoffset2=yoffset+(ypeak2-256+30)/32;
    xoffset2=xoffset+(xpeak2-256+31)/32;
    r_mn=[xoffset2 yoffset2];
end

%Function to show images after automatic white balance
%Written by Shahar Seifer, Weizmann Institute of Science
%input: img- matrix of pixel values
%output: true if successful, false otherwise
function OK=balanced_imshow(img)
    Nshades=1024;
    mapvector=linspace(0,1,Nshades)';
    cmap=zeros(Nshades,3);
    for loop=1:3
        cmap(:,loop)=mapvector;
    end
    try
        showpic2=balance(img,Nshades);
        OK=imshow(showpic2',cmap); %Here is the built in function to show images in Matlab
    catch
        OK=imshow(img);
    end

    function normpic2=balance(normpic,Nshades)    
        [BinValues,BinEdges]=histcounts(normpic,Nshades);
        NumBins=length(BinValues);    
        sumH=sum(BinValues);
        temp=0;
        lowedge=BinEdges(NumBins);
        for n=1:NumBins-1
            temp=temp+BinValues(n);
            if temp>0.005*sumH
                lowedge=BinEdges(n);
            break;
            end
        end
        temp=0;
        highedge=BinEdges(1);
        for n2=NumBins:-1:2
            temp=temp+BinValues(n2);
            if temp>0.005*sumH
                highedge=BinEdges(n2);
            break;
            end
        end
        normpic(normpic>highedge)=highedge; %remove white dots
        normpic(normpic<lowedge)=lowedge; %remove black dots
        normpic2=((double(normpic)-lowedge)*Nshades)/double(highedge-lowedge);
    end 
end    


%Uses function fftInterpolate by Matthias Christian Schabel
% Interpolate N-D array with arbitrary mixture of upsampling and downsampling
%   using Fourier interpolation. Downsampling symmetrically truncates outer 
%   portions of k-space. Upsampling uses zero-filling.
%
%   Usage : out = fftInterpolate(in,newsz)
%
%       out   : output N-dimensional data with size(out) == newsz
%
%       in    : input N-dimensional data
%       newsz : desired interpolated size of output data
%
%   Example :
%
%       fftInterpolate(phantom(32),[24 40]) interpolates a 32x32 image to 24x40         
% 
%   Copyright 2008 Matthias Christian Schabel (matthias @ stanfordalumni . org)
%   University of Utah Department of Radiology
%   Utah Center for Advanced Imaging Research
%   729 Arapeen Drive
%   Salt Lake City, UT 84108-1218
%   
%   2010/12/10 MCS - fixed and simplified
%Cite As
%Matthias Schabel (2021). N-dimensional Fourier interpolation (https://www.mathworks.com/matlabcentral/fileexchange/22665-n-dimensional-fourier-interpolation), MATLAB Central File Exchange. 
function out = fftInterpolate(in,newsz)
sz = size(in);
nd = ndims(in);
% no interpolation
if (newsz == sz) out = in; return; end
% negative or zero scaling factor is meaningless
if (any(newsz <= 0)) error('fftInterpolate :: bad size'); end
% do it in one fell swoop
fac = prod(newsz./sz);
f = find(newsz > sz);
center = floor(sz/2)+1;
lo = floor(center-newsz/2);
hi = lo+newsz-1;
lo(f) = 1;
hi(f) = sz(f);
rng = [lo; hi]';
inft = subRange(fftshift(fftn(in)),rng);
out = zeros(newsz);
sz = size(inft);
% downscaling
centerd = floor(newsz/2);
lod = ceil(centerd-newsz/2)+1;
hid = lod+newsz-1;
% upscaling
centeru = floor(newsz/2)+1+mod(newsz,2);%+odd(newsz) replaced with mod
lou = ceil(centeru-sz/2);
hiu = lou+sz-1;
lo = lod;
hi = hid;
% merge down and upscaling to get final range
lo(f) = lou(f);
hi(f) = hiu(f);
rng = [lo; hi]';
out = fac*ifftn(fftshift(assignSubRange(out,rng,inft)));
% eliminate residual complex values if input array is real
if (isreal(in))
    out = real(out);
end
return;
end
function subData = subRange(data,rng)
if (isempty(rng)) 
    subData = data; 
    return; 
end
sz = size(data);
dim = length(sz);
lo = rng(:,1)';
hi = rng(:,2)';
if (length(lo) ~= dim || length(hi) ~= dim)
    error('subRange :: dimension mismatch');
end
% replace zeros with lower/upper limit 
for i=1:dim
    if (lo(i) == 0) lo(i) = 1; end
    if (hi(i) == 0) hi(i) = sz(i); end
end
if (any(lo<1) || any(hi > sz))
    error('subRange :: sub-range out of bounds');
end
switch (dim)
    case 1,  subData = data(lo(1):hi(1)); 
    case 2,  subData = data(lo(1):hi(1),...
                           lo(2):hi(2)); 
    case 3,  subData = data(lo(1):hi(1),...
                           lo(2):hi(2),...
                           lo(3):hi(3)); 
    case 4,  subData = data(lo(1):hi(1),...
                           lo(2):hi(2),...
                           lo(3):hi(3),...
                           lo(4):hi(4)); 
    case 5,  subData = data(lo(1):hi(1),...
                           lo(2):hi(2),...[]
                           lo(3):hi(3),...
                           lo(4):hi(4),...
                           lo(5):hi(5)); 
    otherwise
            % generate string and use eval
            str = 'subData = data(';
            for i=1:dim
                str = [str 'lo(' num2str(i) '):hi(' num2str(i) ')'];
                if (i~=dim)
                    str = [str ','];
                else
                    str = [str ');'];
                end
            end
            eval(str);
end
        
return;
end
function out = assignSubRange(out,rng,in)
if (isempty(rng)) return; end
sz = size(out);
dim = length(sz);
lo = rng(:,1)';
hi = rng(:,2)';
if (length(lo) ~= dim || length(hi) ~= dim)
    error('assignSubRange :: dimension mismatch');
end
% replace zeros with lower/upper limit 
for i=1:dim
    if (lo(i) == 0) lo(i) = 1; end
    if (hi(i) == 0) hi(i) = sz(i); end
end
if (any(lo<1) | any(hi > sz))
    error('assignSubRange :: sub-range out of bounds');
end
if (size(in) ~= (hi-lo+1))
    error('assignSubRange :: input data size mismatch');
end
switch (dim)
    case 1,  out(lo(1):hi(1)) = in; 
    case 2,  out(lo(1):hi(1),...
                 lo(2):hi(2)) = in; 
    case 3,  out(lo(1):hi(1),...
                 lo(2):hi(2),...
                 lo(3):hi(3)) = in; 
    case 4,  out(lo(1):hi(1),...
                 lo(2):hi(2),...
                 lo(3):hi(3),...
                 lo(4):hi(4)) = in; 
    case 5,  out(lo(1):hi(1),...
                 lo(2):hi(2),...
                 lo(3):hi(3),...
                 lo(4):hi(4),...
                 lo(5):hi(5)) = in; 
    otherwise
            % generate string and use eval
            str = 'out(';
            for i=1:dim
                str = [str 'lo(' num2str(i) '):hi(' num2str(i) ')'];
                if (i~=dim)
                    str = [str ','];
                else
                    str = [str ') = in;'];
                end
            end
            eval(str);
end
return;
end


