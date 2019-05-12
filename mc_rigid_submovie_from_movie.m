function [total_i_vec,total_j_vec,template,xcorr_vec,iter_ctr,mc_stack] =...
    mc_rigid_submovie_from_movie(big_stack,avg_win,maxiters,max_shift,min_shift_error,verbose_flag,return_original,max_files_for_mc_template,...
    roi_size,row_roi_start_vec,col_roi_start_vec,imsize_extract2,pre_proc_flag)

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
    max_files_for_mc_template=-1;
end
if nargin<13
    pre_proc_flag=1;
end


orig_big_stack = big_stack;
big_stack = single(big_stack);

if max_files_for_mc_template<0 || max_files_for_mc_template>size(big_stack,3)
    max_files_for_mc_template=size(big_stack,3);
end

%pre process stack
big_stack(big_stack <0)=0;
big_stack=big_stack/max(big_stack(:))*255;
if pre_proc_flag
    big_stack=pre_process_stack(big_stack); 
end
%%


mov_size_all = size(big_stack);
mov_length = mov_size_all(3);
mov_size1 = mov_size_all(1);
mov_size2 = mov_size_all(2);

total_i_vec = zeros(1,mov_length);
total_j_vec = zeros(1,mov_length );
cur_i_vec = zeros(1,mov_length);
cur_j_vec = zeros(1,mov_length );
xcorr_vec = zeros(1,mov_length );

shifts_vec_i = -max_shift:max_shift;
shifts_vec_j = -max_shift:max_shift;


imsize_extract2_2 = imsize_extract2+2*max_shift;
stack=make_centered_movie(big_stack,roi_size,row_roi_start_vec,col_roi_start_vec,imsize_extract2_2);
    
mov_small_size1 = size(stack,1);
mov_small_size2 = size(stack,2);

for iter_ctr = 1:maxiters
    tic;
    template=get_med_of_avg_template(stack(:,:,1:max_files_for_mc_template),avg_win);

    for i=1:mov_length  
        curcormat = normxcorr2(template(max_shift+1:end-max_shift,max_shift+1:end-max_shift), stack(:,:,i));     
        [szh,szw] = size(template(max_shift+1:end-max_shift,max_shift+1:end-max_shift));
        curcormat=curcormat(szh:end-szh+1,szw:end-szw+1);
        curcormat=rot90(curcormat,2);
        
        if sum(sum(abs(curcormat)))==0
            disp(['Warning: all zero image given for :mc_rigid_submovie_from_movie , frame: ',num2str(i)])
            curcormat(round(size(curcormat,1)/2),round(size(curcormat,2)/2))=0.5;
        end
        
        [ii,jj]=find(curcormat==max(curcormat(:)));
        [ii,jj] = get_conservative_max(curcormat,shifts_vec_i,shifts_vec_j);
        
        cur_i_vec(i)=shifts_vec_i(ii(1));
        cur_j_vec(i)=shifts_vec_j(jj(1));
        
        xcorr_vec(i) = curcormat(ii(1),jj(1));
        
        cur_frame=make_centered_movie(big_stack(:,:,i),roi_size,row_roi_start_vec(i)-cur_i_vec(i)-total_i_vec(i),col_roi_start_vec(i)-cur_j_vec(i)-total_j_vec(i),imsize_extract2_2);
        stack(:,:,i) = cur_frame;
        

    end
    
    total_i_vec=total_i_vec+cur_i_vec;
    total_j_vec=total_j_vec+cur_j_vec;
    
    cur_error = [mean(abs(cur_i_vec-mean(cur_i_vec))) mean(abs(cur_j_vec-mean(cur_j_vec)))];
    
    curtimesec=toc;
    if verbose_flag
        disp(['Done iteration: ',num2str(iter_ctr),' in ',num2str(curtimesec),' seconds'])
        disp(['Error: ',num2str(cur_error)])
    end
    
    if (cur_error(1)<min_shift_error && cur_error(2)<min_shift_error) 
        break
    end
end

%fix bad shifts
bad_shifts_inds = find(abs(total_i_vec)>=floor(mov_small_size1/2) | abs(total_j_vec)>=floor(mov_small_size2/2));
good_shift_inds = setdiff(1:length(total_i_vec),bad_shifts_inds);
for bsctr = 1:length(bad_shifts_inds )
    cur_shift_ind =  bad_shifts_inds(bsctr);
    next_good_shift_ind = find(good_shift_inds>cur_shift_ind ,1,'first');
    prev_good_shift_ind = find(good_shift_inds<cur_shift_ind ,1,'last');
    if isempty(next_good_shift_ind )
        total_i_vec(cur_shift_ind ) = total_i_vec(prev_good_shift_ind);
        total_j_vec(cur_shift_ind ) = total_j_vec(prev_good_shift_ind);
    elseif isempty(prev_good_shift_ind )
        total_i_vec(cur_shift_ind ) = total_i_vec(next_good_shift_ind);
        total_j_vec(cur_shift_ind ) = total_j_vec(next_good_shift_ind);
    else
        total_i_vec(cur_shift_ind ) = round(mean(total_i_vec([prev_good_shift_ind next_good_shift_ind])));
        total_j_vec(cur_shift_ind ) = round(mean(total_j_vec([prev_good_shift_ind next_good_shift_ind])));
    end
end


if return_original
    mc_stack=make_centered_movie(orig_big_stack,roi_size,row_roi_start_vec-total_i_vec,col_roi_start_vec-total_j_vec,imsize_extract2_2);
    template=get_med_of_avg_template(mc_stack,avg_win);    
else
    mc_stack=stack;
end










