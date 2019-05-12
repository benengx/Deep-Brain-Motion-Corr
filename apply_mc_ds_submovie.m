function patch_mc=apply_mc_ds_submovie(ImageStack,first_i_vec,first_j_vec,threshold_before_ds,ds_win,roi_size,ds_i_vec,ds_j_vec,row_roi_start_vec,col_roi_start_vec,imsize_extract2,max_shift)

big_stack_mc = apply_mc2(ImageStack,first_i_vec,first_j_vec);

if ~isempty(threshold_before_ds)
    big_stack_mc(big_stack_mc<threshold_before_ds)=threshold_before_ds;
    big_stack_mc=big_stack_mc-threshold_before_ds;
end

[big_stack_mc_ds,~] = ds_mean(big_stack_mc,ds_win);

[row_roi_start_vec_ds,~]     = ds_mean(row_roi_start_vec,ds_win,2);
[col_roi_start_vec_ds,~]     = ds_mean(col_roi_start_vec,ds_win,2);

imsize_extract2_2 = imsize_extract2+2*max_shift;

patch_mc=make_centered_movie(big_stack_mc_ds,roi_size,round(row_roi_start_vec_ds)-ds_i_vec,round(col_roi_start_vec_ds)-ds_j_vec,imsize_extract2_2);









