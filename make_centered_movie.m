% if row_centering_vec and col_centering_vec are scalars then do one shift for the entire movie
function centered_stack = make_centered_movie(ImageStack,roi_size,row_centering_vec,col_centering_vec,imsize)

if numel(row_centering_vec)~=numel(col_centering_vec)
    error('row and col centering vectors must be the same length')
end
    
mov_h          = size(ImageStack,1);
mov_w          = size(ImageStack,2);
cur_num_frames = size(ImageStack,3);

roi_h = roi_size(1);
roi_w = roi_size(2);

if nargin<5
    imsize = 5*max([roi_h roi_w]);
end


if numel(row_centering_vec)>1
    
    centered_stack = zeros(imsize,imsize,cur_num_frames);
    
    for i=1:cur_num_frames
        newcenter_i = row_centering_vec(i)+floor(roi_h/2);
        newcenter_j = col_centering_vec(i)+floor(roi_w/2);
        curinds_i = newcenter_i-floor(imsize/2):newcenter_i-floor(imsize/2)+imsize-1;
        curinds_j = newcenter_j-floor(imsize/2):newcenter_j-floor(imsize/2)+imsize-1;
        
        fillup = sum(curinds_i<1);
        filldown = sum(curinds_i>mov_h);
        fillleft = sum(curinds_j<1);
        fillright = sum(curinds_j>mov_w);
        
        curinds_i=curinds_i(curinds_i>0 & curinds_i<=mov_h);
        curinds_j=curinds_j(curinds_j>0 & curinds_j<=mov_w);
        
        fillleft_mat  = zeros(imsize,max(fillleft,0));                                  if ~prod(size(fillleft_mat));  fillleft_mat =[]; end;
        fillup_mat    = zeros(max(fillup,0),imsize-max(fillleft,0)-max(fillright,0));   if ~prod(size(fillup_mat));    fillup_mat   =[]; end;
        filldown_mat  = zeros(max(filldown,0),imsize-max(fillleft,0)-max(fillright,0)); if ~prod(size(filldown_mat));  filldown_mat =[]; end;
        fillright_mat = zeros(imsize,max(fillright,0));                                 if ~prod(size(fillright_mat)); fillright_mat=[]; end;
try        
        curframe = [fillleft_mat [fillup_mat; ImageStack(curinds_i,curinds_j,i); filldown_mat] fillright_mat];
catch
   disp(' ') 
end
        centered_stack(:,:,i) = curframe;
    end
    
else
        newcenter_i = row_centering_vec+floor(roi_h/2);
        newcenter_j = col_centering_vec+floor(roi_w/2);
        curinds_i = newcenter_i-floor(imsize/2):newcenter_i-floor(imsize/2)+imsize-1;
        curinds_j = newcenter_j-floor(imsize/2):newcenter_j-floor(imsize/2)+imsize-1;
        
        fillup = sum(curinds_i<1);
        filldown = sum(curinds_i>mov_h);
        fillleft = sum(curinds_j<1);
        fillright = sum(curinds_j>mov_w);
        
        curinds_i=curinds_i(curinds_i>0 & curinds_i<=mov_h);
        curinds_j=curinds_j(curinds_j>0 & curinds_j<=mov_w);
        
        fillleft_mat  = zeros(imsize,max(fillleft,0),cur_num_frames);                                  if ~prod(size(fillleft_mat));  fillleft_mat =[]; end;
        fillup_mat    = zeros(max(fillup,0),imsize-max(fillleft,0)-max(fillright,0),cur_num_frames);   if ~prod(size(fillup_mat));    fillup_mat   =[]; end;
        filldown_mat  = zeros(max(filldown,0),imsize-max(fillleft,0)-max(fillright,0),cur_num_frames); if ~prod(size(filldown_mat));  filldown_mat =[]; end;
        fillright_mat = zeros(imsize,max(fillright,0),cur_num_frames);                                 if ~prod(size(fillright_mat)); fillright_mat=[]; end;
        
        centered_stack = [fillleft_mat [fillup_mat; ImageStack(curinds_i,curinds_j,:); filldown_mat] fillright_mat];
end
