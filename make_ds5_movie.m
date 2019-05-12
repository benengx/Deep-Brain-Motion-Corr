function make_ds5_movie(output_folder,patch_ctr)
if nargin<2
    patch_ctr=[];
end

if isunix
    slashind = '/';
else
    slashind = '\';
end

ds5_foldername = [output_folder,'ds5_files',slashind];
if ~exist(ds5_foldername )
    mkdir(ds5_foldername )
end

tiffilename  = ['mc_image_stack_full_patch_',num2str(patch_ctr),'.tif']; % if movie is not divided into parts
if ~exist([output_folder,tiffilename],'file')
    tiffilename  = ['mc_image_stack_full_patch_',num2str(patch_ctr),'_part1.tif']; % if movie is divided into parts, do only first part
end

new_tiffilename = [tiffilename(1:end-4),'_ds5.tif'];
if exist([ds5_foldername,new_tiffilename],'file')    % movie has already been done. skipping.
    return
end

Im1 = loadTiffStack_single([output_folder,tiffilename]);
Im_ds5=movingmean(Im1,5,3);   % average of 5 frames
Im_ds5 = Im_ds5(:,:,3:5:end);
new_tiffilename = [tiffilename(1:end-4),'_ds5.tif'];

saveastiff(Im_ds5,[ds5_foldername,new_tiffilename])




