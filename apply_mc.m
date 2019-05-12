function mc_image_stack = apply_mc(image_stack,row_shift_vec,col_shift_vec)

mc_image_stack = zeros(size(image_stack),class(image_stack));
cur_ref2d=imref2d(size(image_stack(:,:,1)));

for i=1:size(image_stack,3)   
    if sum(abs([col_shift_vec(i) row_shift_vec(i)]-floor([col_shift_vec(i) row_shift_vec(i)])))==0 % simple move by whole pixels
        
        mc_image_stack(:,:,i)=simple_shift(image_stack(:,:,i),col_shift_vec(i),row_shift_vec(i));   
    else
        A = [ 1        0      0;
            0        1      0;
            col_shift_vec(i) row_shift_vec(i) 1 ];
        
        tform = affine2d(A);
        mc_image_stack(:,:,i) = imwarp(image_stack(:,:,i),tform, 'OutputView', cur_ref2d);
        
    end
end

function imout=simple_shift(imin,col_shift,row_shift)   

imout=circshift(circshift(imin,row_shift,1),col_shift,2);
imout(1:row_shift,:)         = 0;
imout(:,1:col_shift,:)       = 0;
imout(end+row_shift+1:end,:) = 0;
imout(:,end+col_shift+1:end) = 0;

