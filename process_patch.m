
function res=process_patch(input_folder,output_folder,patch_file,patch_ctr,have_red_channel,use_red_channel)

disp(['Now working on patch ',num2str(patch_ctr)])

max_shift = 30;

slashind = '\';
if isunix
    slashind ='/';
end

if have_red_channel
    if use_red_channel
        frames_to_take = 2;
    else
        frames_to_take = 1;
    end
else
    frames_to_take = 0;
end

tempfolder = [output_folder,'tempsaves',slashind];
if ~exist(tempfolder,'dir')
    mkdir( tempfolder);
end

%% get raw tif files
tiflist = dir([input_folder,'*.tif']);
for i=1:length(tiflist )
    tiflist_cell{i} = tiflist(i).name;
end
tiflist_cell=sort(tiflist_cell);
for i=1:length(tiflist_cell)
    tiflist_full{i}= [input_folder,tiflist_cell{i}];
end
%%


%% check if run is relevant. if not, quit
if length(dir([output_folder,'mc_image_stack_full_patch_',num2str(patch_ctr),'_*tif']))>0 || length(dir([output_folder,'mc_image_stack_full_patch_',num2str(patch_ctr),'.tif']))>0  
    disp(['patch number (',num2str(patch_ctr),') seems to have already been processed. Quitting. '])
    res =[];
    return
end
%%

%% get displacement field for each file
load([output_folder,'demons_disp_cell.mat'],'disp_cell_summed')
%%

%% get the height and width of movie
mov_h=size(disp_cell_summed{1},1);
mov_w=size(disp_cell_summed{1},2);
%%


all_patch_time=tic;
patch_struct = ReadImageJROI(patch_file);
cur_mask=make_mask_from_roi(patch_struct,[mov_h mov_w]);

cur_selection_binary = double(cur_mask>0); % masked selection of 1 neuron (full 512 by 512 image, 0 if not in patch, 1 if in patch)
[cur_patch,cur_patch_coordinates,patch_h,patch_w] = boundingRec(cur_selection_binary);


%% loop over all tiff files and extract a square patch of size imsize_extract around the patch that is shifted by the mean displacement of
%% the patch in the file according to demons and the standrad motion correction of each frame
imsize_extract = round(1.1*max([patch_h patch_w])); % size of submovie to be extracted, for now make it square
imsize_extract2=round(imsize_extract*1.2);
mov_size_lr = ceil(([imsize_extract imsize_extract]-[patch_h patch_w])/2); % size of extracted submovie beyond the patch

row_centering_vec_files = zeros(1,length(tiflist_full)); %top  indexes of centered patch
col_centering_vec_files = zeros(1,length(tiflist_full)); %left indexes of centered patch

load([output_folder,'final_xy_shifts.mat'],'XX_cell','YY_cell')

disp(['Now working on patch ',num2str(patch_ctr),' (',patch_struct.strName,')']);
disp('')
%extract a patch 1.5 the size of what we need, motion correct it and then extract
%the midddle part. 
disp('Loading templates file...')
mc_tmu = loadTiffStack_single([output_folder,'template_mov.tif']);
clear centpatchd_mat cur_centered_patch row_patch_start col_patch_start
disp('Extracting movie patch from mean demons displacement field...')
for file_ctr = 1:length(tiflist_full)
    centpatchd_mat(file_ctr,:) = find_center_of_displaced_patch(cur_patch_coordinates,patch_h,patch_w,disp_cell_summed{file_ctr});
    row_patch_start = round(centpatchd_mat(file_ctr,2)-patch_h/2);
    col_patch_start = round(centpatchd_mat(file_ctr,1)-patch_w/2);
    row_patch_start_vec(file_ctr) = row_patch_start;
    col_patch_start_vec(file_ctr) = col_patch_start;
end
disp('Motion correcting templates patch and updating patch extraction coordinates...')
[rtv_patch,ctv_patch]  =    mc_rigid_submovie_from_movie(mc_tmu,1,3,max_shift,0.2,1,1,-1,[patch_h patch_w],row_patch_start_vec,col_patch_start_vec,imsize_extract);
centpatchd_mat2=centpatchd_mat-[rtv_patch' ctv_patch'];
disp('')
disp('Start of main loop...')
start_file_ctr=1;
files_saved = dir([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_*']);
if length(files_saved)>0
    start_file_ctr=length(files_saved)+1;
    load([tempfolder,'curres_',num2str(patch_ctr)],'res');
end

threshold_before_ds = 10;
ds_win = 2;
for file_ctr = start_file_ctr:length(tiflist_full)
    
    %% load file
    tic
    clear ImageStack
    ImageStack = loadTiffStack_single(tiflist_full{file_ctr},frames_to_take);  
    disp(['Loading file ',num2str(file_ctr),' took ',num2str(toc),' seconds']);
    %%
    
    %% motion correct current movie
    ImageStack_mc=apply_mc(ImageStack,YY_cell{file_ctr},XX_cell{file_ctr}); % make sure x and y are not inverted here % it was inverted! now fixed
    %%
    
   
    %% extract movie patch
    row_patch_start = round(centpatchd_mat2(file_ctr,2)-patch_h/2);
    col_patch_start = round(centpatchd_mat2(file_ctr,1)-patch_w/2);
    %%
    
    %% now motion correct this movie patch
    mc_time=tic;
    [res_str,mc_stack_ds,dsind_cell] = motion_correct_ds_submovie(ImageStack_mc,50,3,max_shift,0.2,1,1,...
        ds_win,-1,[patch_h patch_w],row_patch_start*ones(1,size(ImageStack_mc,3)),col_patch_start*ones(1,size(ImageStack_mc,3)),imsize_extract,threshold_before_ds);
    
    disp(['Calculating and applying motion correction took ',num2str(toc(mc_time)),' seconds']);
    %%
    
    save([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_',num2str(file_ctr)],'mc_stack_ds')
    
    %save translation and centering coordinates for this file
    res.first_row_translation_vec_cell{file_ctr}   = res_str.first_i_vec;
    res.first_col_translation_vec_cell{file_ctr}   = res_str.first_j_vec;
    res.first_translation_xcorr_vec_cell{file_ctr} = res_str.first_xcorr_vec;
    res.ds_row_translation_vec_cell{file_ctr}      = res_str.ds_i_vec;
    res.ds_col_translation_vec_cell{file_ctr}      = res_str.ds_j_vec;
    res.ds_translation_xcorr_vec_cell{file_ctr}    = res_str.ds_xcorr_vec;
    res.dsind_cell_cell{file_ctr}                  = dsind_cell;
    
    res.row_patch_start_vec(file_ctr) = row_patch_start;
    res.col_patch_start_vec(file_ctr) = col_patch_start;
    res.all_templates(:,:,file_ctr) = res_str.ds_template;
    res.num_frames_file(file_ctr)   = size(mc_stack_ds,3);
    %%
    save([tempfolder,'curres_',num2str(patch_ctr)],'res')
    
end
load([tempfolder,'curres_',num2str(patch_ctr)],'res');

res.patch_size = [patch_h patch_w];
res.name     = patch_struct.strName;
res.centpatchd_mat2 = centpatchd_mat2;
res.threshold_before_ds = threshold_before_ds;
res.ds_win=ds_win;

%%now motion correct the templates and shifts movie accordingly

%%


save([output_folder,'res_mc_data_',num2str(patch_ctr),'.mat'],'res');

%save entire session
tic
max_size_file=2.7e9; %was 3.8 before
bytes_per_frame = (imsize_extract^2)*4;
bytes_per_file=bytes_per_frame*750;
max_files_frame_limit = floor((2^16-1)/750);
num_files_per_movie=min(floor(max_size_file/bytes_per_file),max_files_frame_limit);
est_num_movies = ceil(length(res.num_frames_file)/num_files_per_movie);

mc_time_template=tic;
[row_translation_templates,col_translation_templates] = mc_rigid(res.all_templates,1,10,20,0.2,1,1);

disp(['Calculating motion correction to templates took ',num2str(toc(mc_time_template)),' seconds']);

avg_frame_lim = 500;
avg_movie     = [];
prev_for_avgs = [];
total_avg_frame_ctr=1;

movie_ctr = 1;
savefile_ctr=1;
mc_save_time_template=tic;
disp(' Reloading files, applying global motion correction and saving...')
mc_image_stack_full = [];      
for file_ctr = 1:length(tiflist_full)
    disp(['Processing file ',num2str(file_ctr),' of ',num2str(length(tiflist_full))])
    if ~use_red_channel %load the file (it is already corrected green channel file
        load([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_',num2str(file_ctr)],'mc_stack_ds')
    else % the saved file is the corrected red channel file, so now we use the calculated shifts to get the corrected green channel file
            
        ImageStack = loadTiffStack_single(tiflist_full{file_ctr},min(frames_to_take,1));  
        ImageStack_mc=apply_mc(ImageStack,YY_cell{file_ctr},XX_cell{file_ctr});
        row_patch_start = round(res.centpatchd_mat2(file_ctr,2)-patch_h/2);
        col_patch_start = round(res.centpatchd_mat2(file_ctr,1)-patch_w/2);
    
        mc_stack_ds=apply_mc_ds_submovie(ImageStack_mc,res.first_row_translation_vec_cell{file_ctr} ,res.first_col_translation_vec_cell{file_ctr},res.threshold_before_ds,res.ds_win,res.patch_size,...
            res.ds_row_translation_vec_cell{file_ctr},res.ds_col_translation_vec_cell{file_ctr},row_patch_start*ones(1,size(ImageStack_mc,3)),col_patch_start*ones(1,size(ImageStack_mc,3)),imsize_extract2,max_shift);
        
    end
    cur_ones_vec = ones(1,res.num_frames_file(file_ctr));
    temp_movie =  apply_mc(single(mc_stack_ds),row_translation_templates(file_ctr)*cur_ones_vec,col_translation_templates(file_ctr)*cur_ones_vec);
    mc_image_stack_full =cat(3,mc_image_stack_full,temp_movie);

    if movie_ctr==num_files_per_movie || file_ctr==length(tiflist_full)
        mc_image_stack_full_for_avgs = cat(3,prev_for_avgs,mc_image_stack_full);
        cur_avgs_to_make = floor(size(mc_image_stack_full_for_avgs,3)/avg_frame_lim);
        avgs_ctr=0;
        for avgs_ctr=1:cur_avgs_to_make
            avg_movie(:,:,total_avg_frame_ctr) = mean(mc_image_stack_full_for_avgs(:,:,(avgs_ctr-1)*avg_frame_lim+1:avgs_ctr*avg_frame_lim),3);
            total_avg_frame_ctr=total_avg_frame_ctr+1;
        end
        prev_for_avgs=mc_image_stack_full_for_avgs(:,:,avgs_ctr*avg_frame_lim+1:end);
        if file_ctr==length(tiflist_full) && size(prev_for_avgs,3)>50
            avg_movie(:,:,total_avg_frame_ctr) = mean(prev_for_avgs,3);
        end
        
        
        mc_image_stack_full=mc_image_stack_full(max_shift+1:end-max_shift,max_shift+1:end-max_shift,:);
        if file_ctr==length(tiflist_full) && savefile_ctr==1
            saveastiff(mc_image_stack_full,[output_folder,'mc_image_stack_full_patch_',num2str(patch_ctr),'.tif']);
        else
            saveastiff(mc_image_stack_full,[output_folder,'mc_image_stack_full_patch_',num2str(patch_ctr),'_part',num2str(savefile_ctr),'.tif']);
        end
        disp(['Saved movie ',num2str(savefile_ctr),' of ',num2str(est_num_movies)])
        movie_ctr=1;
        savefile_ctr=savefile_ctr+1;
        mc_image_stack_full = [];
    else
        movie_ctr=movie_ctr+1;
    end
    
    
end

saveastiff(single(avg_movie),[output_folder,'mc_image_stack_full_patch_',num2str(patch_ctr),'_AVG_',num2str(avg_frame_lim),'.tif']);  

res.row_post_extraction_shift = row_translation_templates;
res.col_post_extraction_shift = col_translation_templates;
save([output_folder,'res_mc_data_',num2str(patch_ctr),'.mat'],'res');
disp(['Reloading files, applying global motion correction and saving took ',num2str(toc(mc_save_time_template)),' seconds']);


disp(['Entire procedure for patch ',num2str(patch_ctr),' (',patch_struct.strName,') took ',num2str(toc(all_patch_time)),' seconds']);

disp('Now saving ds5 movie...')
make_ds5_movie(output_folder,patch_ctr);
disp(['DS5 movie for patch ',num2str(patch_ctr),' (',patch_struct.strName,') took ',num2str(toc),' seconds']);













