
function [dsmov,dsind_cell] = ds_mean(mov,win,dim)
if nargin<3
    dim=3;
end

inds_vec = 1:win:size(mov,dim);

switch dim
    case 3
        dsmov =zeros(size(mov,1),size(mov,2),length(inds_vec),'single');
        for i=1:length(inds_vec)
            dsind_cell{i} = inds_vec(i):min([inds_vec(i)+win-1 size(mov,dim)]);
            dsmov(:,:,i)  = mean(mov(:,:,dsind_cell{i}),3);
        end
    case 2
        dsmov =zeros(size(mov,1),length(inds_vec),'single');
        for i=1:length(inds_vec)
            dsind_cell{i} = inds_vec(i):min([inds_vec(i)+win-1 size(mov,dim)]);
            dsmov(:,i)  = mean(mov(:,dsind_cell{i}),2);
        end
    case 1
        dsmov =zeros(length(inds_vec),size(mov,2),'single');
        for i=1:length(inds_vec)
            dsind_cell{i} = inds_vec(i):min([inds_vec(i)+win-1 size(mov,dim)]);
            dsmov(i,:)  = mean(mov(dsind_cell{i},:),1);
        end
end





