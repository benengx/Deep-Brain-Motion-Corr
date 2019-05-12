function [disp_cell_summed,ImageStack_mc2]=drift_correct_demons(ImageStack,filename,max_num_iterations,gaussian_params,max_frames_template,saveflag)
if nargin<2
    filename=[];
end
if nargin<3
    max_num_iterations=20;
end
if nargin<4
    gaussian_params=[20 4];
end
if nargin<5
    max_frames_template=size(ImageStack,3)-1;
end
if nargin<6
    saveflag=1;
end

if isempty(max_frames_template)
    max_frames_template=size(ImageStack,3)-1;    
end


ImageStack_mc2=ImageStack;
for i=1:size(ImageStack,3)
    disp_cell_summed{i} = zeros(size(ImageStack,1),size(ImageStack,2),2);
end
prev_mean_corr = 0;
prev_sem_corr = 0;
for j=1:max_num_iterations
    disp(['Now processing iteration ',num2str(j),' of a max of ',num2str(max_num_iterations),' . Processing ',num2str(size(ImageStack,3)),' files : '])
    tic
    cur_template = single(median(ImageStack_mc2(:,:,1:max_frames_template),3));
    cur_template_orig_vec = cur_template(:);
    cur_template =cur_template /mean(cur_template (:));
    cur_template =cur_template .*localnormalize(cur_template+1e-50 ,gaussian_params(1),gaussian_params(2));
    cur_template (isnan(cur_template ))=0;
    cur_template_vec=cur_template(:);
    for i=1:size(ImageStack,3)
        curimage=single(ImageStack_mc2(:,:,i));
        curimage=curimage/mean(curimage(:));
        curimage=curimage.*localnormalize(curimage+1e-50,gaussian_params(1),gaussian_params(2));
        curimage(isnan(curimage))=0;
        [D,Ar] = my_imregdemons(curimage,cur_template,[32 16 8 4],'AccumulatedFieldSmoothing',2.5,'PyramidLevels',4);
        ImageStack_mc2(:,:,i) = imwarp(ImageStack_mc2(:,:,i),D,'Interp','linear');
        temp_frame = ImageStack_mc2(:,:,i);
        cur_corr(i) = corr(cur_template_vec,single(Ar(:)));
        cur_corr_orig(i) = corr(cur_template_orig_vec,single(temp_frame(:)));
        disp_cell{j,i} = D;
        disp_cell_summed{i} = disp_cell_summed{i} + disp_cell{j,i}; 
        fprintf([num2str(i),' '])
    end
    avg_corr = mean(cur_corr);
    sem_corr = std(cur_corr)/sqrt(size(ImageStack,3));
    avg_corr_orig = mean(cur_corr_orig);
    sem_corr_orig = std(cur_corr_orig)/sqrt(size(ImageStack,3));
    disp(' ')
    disp(['Finished iteration ',num2str(j),' in ',num2str(toc),' seconds. Avg. corr. : ',num2str(avg_corr),'+-',num2str(sem_corr),' Avg. corr. orig. : ',num2str(avg_corr_orig),'+-',num2str(sem_corr_orig)]) 
    if avg_corr_orig< prev_mean_corr+prev_sem_corr
        break
    end
    prev_mean_corr=avg_corr_orig;
    prev_sem_corr=sem_corr_orig;
end
if ~isempty(filename) && saveflag
    saveastiff(ImageStack_mc2,filename);
end
