function [ii,jj] = get_conservative_max(curcormat,shifts_vec_i,shifts_vec_j)

rad_ccm = sqrt(repmat(shifts_vec_i',1,size(curcormat,2)).^2+repmat(shifts_vec_j,size(curcormat,1),1).^2);
[~,sind]=sort(rad_ccm(:));

ccs=curcormat(:);
ccs=ccs(sind);

cur_sem=std(ccs)/sqrt(length(ccs));
equal_peaks = ccs>(max(ccs)-cur_sem);
cur_emx = find(equal_peaks,1,'first');

[ii,jj]=ind2sub(size(curcormat),sind(cur_emx));












