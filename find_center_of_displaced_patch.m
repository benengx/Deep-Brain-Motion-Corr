% We have an patch that was computed on an image warped with a displacement field D. we want to find the center of the patch on the original image,
% assuming the pixels of the patch moved "together" and the original patch has the same size. this function returns the center of that "original" patch.

function centpatchd = find_center_of_displaced_patch(patch_coordinates,patch_h,patch_w,D)

v1 = patch_coordinates(1);
h1 = patch_coordinates(2);
v2 = patch_h+v1-1;
h2 = patch_w+h1-1;

[mov_h,mov_w] = size(D(:,:,1));

[x_mesh,y_mesh]=meshgrid(1:mov_w,1:mov_h);

D_add = -D+cat(3,x_mesh,y_mesh);
D_add_vec = [reshape(D_add(:,:,1),numel(D_add(:,:,1)),1) reshape(D_add(:,:,2),numel(D_add(:,:,2)),1)];

inds_in_patch = find(D_add_vec(:,1)>=h1 & D_add_vec(:,1)<=h2 & D_add_vec(:,2)>=v1 & D_add_vec(:,2)<v2);

original_xy_vec = [reshape(x_mesh,numel(x_mesh),1) reshape(y_mesh,numel(y_mesh),1)];

centpatchd = mean(original_xy_vec(inds_in_patch,:));








