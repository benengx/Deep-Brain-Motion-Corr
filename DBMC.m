%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    Ben Engelhard, Princeton University (2019).
%
%    This program is provided free without any warranty; you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 as published by the Free Software Foundation.
%    If this code is used, please cite: B Engelhard et al. Specialized coding of sensory, motor, and cognitive variables in midbrain dopamine neurons. Nature, 2019.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% DBMC.m
%%%
%%% Description: Run motion correction code on a series of tiff files, while accounting for slow drift and fast jitter.
%
% arguments: input_folder     - Folder where the raw tiff files are located. The code assumes that all tiff files in the folder belong to the same recording session and are 
%                               in the order of their name sorting.
%            output_folder    - Folder where the corrected movies will be saved (and also all auxiliary files produced during the motion correction).
%            have_red_channel - '1' if the red channel was recorded (assumed to be every second frame in all video files), else '0'. 
%            use_red_channel  - '1' if we wish to use the red channel (every second frame) for motion correction, else '0'. 
%


function DBMC(input_folder,output_folder,have_red_channel,use_red_channel)

if nargin<3
    have_red_channel=0;
end
if nargin<4
    use_red_channel=0;
end


% get correct output_folder
slashind = '\';
if isunix
    slashind ='/';
end
if ~strcmp(input_folder(end),slashind)
    input_folder=[input_folder,slashind];
end
if ~strcmp(output_folder(end),slashind)
    output_folder=[output_folder,slashind];
end

if use_red_channel
    disp('Using red channel for motion correction')
else
    disp('Using green channel for motion correction')
end

% do translation only first and save the shifts and a file of template images
if use_red_channel
    file_to_check = [output_folder,'template_mov_green.tif'];
else
    file_to_check = [output_folder,'template_mov.tif'];    
end
if ~exist(file_to_check,'file')
    disp('Running translation-only correction on all files.....')
    run_first_rigid_mc(input_folder,output_folder,have_red_channel,use_red_channel);
else
    disp('translation-only correction already performed , skipping...')
end

%get sharper movie templates for subsequent demons registration
if ~exist([output_folder,'templates_mov_sharp.tif'],'file')
    disp('Loading all files, correcting and pre-processing to get a sharper template movie.....')
    
    make_sharp_template(input_folder,output_folder,have_red_channel,use_red_channel);

    %finished processing all sharp templates    
    sharptemplate_folder = [output_folder,'sharptemplates',slashind];

    for file_ctr = 1:length(dir([input_folder,'*.tif']))
        curt = load([sharptemplate_folder,'template_',num2str(file_ctr)]);
        templates_mov_uncor(:,:,file_ctr) = curt.cur_template;
    end
    
    % motion correcting sharper templates and saving
    
    [total_i_vec,total_j_vec,~,~,~,templates_mov_corrc] = mc_rigid...
        (templates_mov_uncor,1,10,30,0.2,1,1);
    saveastiff(templates_mov_uncor,[output_folder,'templates_mov_uncor_sharp.tif']);
    saveastiff(templates_mov_corrc,[output_folder,'templates_mov_sharp.tif']);
    
else
    disp('Sharp template movie exists, skipping pre-processing.....')
end

% non-rigid registration of the template with demons
demons_filename = [output_folder,'template_mov_demons.tif'];
if ~exist([output_folder,'demons_disp_cell.mat'],'file')
    disp('Performing demons registration on the templates.....')
    disp('Now doing demons registration on the templates')
    ImageStack_templates = loadTiffStack_single([output_folder,'templates_mov_sharp.tif']);
    disp_cell_summed=drift_correct_demons(ImageStack_templates,demons_filename,20,[20 4]);
    save([output_folder,'demons_disp_cell.mat'],'disp_cell_summed')
else
    disp('Demons registration exists, skipping.....')    
end

%check patch file
patches_file= [output_folder,'patches.zip'];
if ~exist(patches_file,'file')
    error(['Please make ROIs for the patches in imagej and save them in ',patches_file,' They should be based on the first frame of ',file_to_check])
else
    disp('patches file exists, skipping.....')    
end

patches_folder = [output_folder,'patches_folder',slashind];

if ~exist(patches_folder,'dir')
    mkdir( output_folder,'patches_folder');
end

unzip(patches_file,patches_folder);


%% now work on individual patchs
disp('Now starting work on individual Patches.....')
patcheslist = dir([patches_folder,'*.roi']);
num_patches = length(patcheslist);
parfor i=1:num_patches
    patch_file = [patches_folder,patcheslist(i).name];
    process_patch(input_folder,output_folder,patch_file,i,have_red_channel,use_red_channel);
    
end
disp('Finished all patches')

%%





