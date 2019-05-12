
function [res_str,mc_mc_stack_ds,dsind_cell] = motion_correct_ds_submovie(big_stack,avg_win,maxiters,max_shift,min_shift_error,verbose_flag,return_original,...
    ds_win,max_files_for_mc_template,roi_size,row_roi_start_vec,col_roi_start_vec,imsize_extract2, threshold_before_ds)

if nargin<2
    avg_win=50;
end
if nargin<3
    maxiters=10;
end
if nargin<4
    max_shift=30;
end
if nargin<5
    min_shift_error=2;
end
if nargin<6
    verbose_flag=0;
end
if nargin<7
    return_original=0;
end
if nargin<8
    ds_win=2;
end
if nargin<9
    max_files_for_mc_template=-1;
end
if nargin<14
    threshold_before_ds=[];
end

disp('Motion correcting the full movie...')
[first_i_vec,first_j_vec,first_template,first_xcorr_vec,first_iter_ctr,~] = mc_rigid_submovie_from_movie(big_stack,avg_win,maxiters,max_shift,min_shift_error,verbose_flag,...
    return_original,max_files_for_mc_template,roi_size,row_roi_start_vec,col_roi_start_vec,imsize_extract2);

big_stack_mc = apply_mc(big_stack,first_i_vec,first_j_vec);

if ~isempty(threshold_before_ds)
    big_stack_mc(big_stack_mc<threshold_before_ds)=threshold_before_ds;
    big_stack_mc=big_stack_mc-threshold_before_ds;
end

  [big_stack_mc_ds,dsind_cell] = ds_mean(big_stack_mc,ds_win); 
[row_roi_start_vec_ds,~]     = ds_mean(row_roi_start_vec,ds_win,2);
[col_roi_start_vec_ds,~]     = ds_mean(col_roi_start_vec,ds_win,2);


regular_l = size(big_stack_mc,3);
ds_l = size(big_stack_mc_ds,3);
max_files_for_mc_template_ds=-1;
if max_files_for_mc_template>0
    max_files_for_mc_template_ds = floor(max_files_for_mc_template*ds_l/regular_l);
end
avg_win2=ceil(avg_win/ds_win);

disp('Motion correcting the downsampled movie...')
[ds_i_vec,ds_j_vec,ds_template,ds_xcorr_vec,ds_iter_ctr,mc_mc_stack_ds] = mc_rigid_submovie_from_movie(big_stack_mc_ds,avg_win2,maxiters*2,max_shift,min_shift_error,verbose_flag,...
    return_original,max_files_for_mc_template_ds,roi_size,round(row_roi_start_vec_ds),round(col_roi_start_vec_ds),imsize_extract2);


res_str.first_i_vec=first_i_vec;
res_str.first_j_vec=first_j_vec;
res_str.first_template=first_template;
res_str.first_xcorr_vec=first_xcorr_vec;
res_str.first_iter_ctr=first_iter_ctr;
res_str.ds_i_vec=ds_i_vec;
res_str.ds_j_vec=ds_j_vec;
res_str.ds_template=ds_template;
res_str.ds_xcorr_vec=ds_xcorr_vec;
res_str.ds_iter_ctr=ds_iter_ctr;













