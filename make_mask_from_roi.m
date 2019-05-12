function mask=make_mask_from_roi(roi_struct,orig_image_size)

mask = zeros(orig_image_size);

if isfield(roi_struct,'mnCoordinates')
    num_selections = 1;
    sels(1).rows_vector = roi_struct.mnCoordinates(:,2);
    sels(1).cols_vector = roi_struct.mnCoordinates(:,1);
else
    selections_start_inds  = [1; find(roi_struct.vfShapes(1:end-4)==1 & roi_struct.vfShapes(4:end-1)==4 & roi_struct.vfShapes(5:end)==0)+4];
    num_selections = length(selections_start_inds);
    
    for selctr = 1:num_selections
        if selctr < num_selections
            curcoords = roi_struct.vfShapes(selections_start_inds(selctr):selections_start_inds(selctr+1)-1);
        else
            curcoords = roi_struct.vfShapes(selections_start_inds(selctr):end);
        end
        sels(selctr).cols_vector = curcoords(2:3:end);
        sels(selctr).rows_vector = curcoords(3:3:end);
    end
end

for selctr = 1:num_selections
    
     BW = poly2mask( sels(selctr).cols_vector,sels(selctr).rows_vector, orig_image_size(1), orig_image_size(2));
     mask(BW==1)=1;   
end


%-------------------------%

function side_out = interp_outliers(side_in)

side_out=side_in;
orig_x = 1:length(side_in);
smth_dif = abs(side_in(:)-smooth(side_in(:)));
index_to_int= find(smth_dif>std(smth_dif)*4);
if isempty(index_to_int)
    return
end
x_fip = setdiff(orig_x,index_to_int);
y_fip = side_in(x_fip);
int_y = interp1(x_fip,y_fip,index_to_int,'linear','extrap');

side_out(index_to_int) = int_y;

function [rows_in_roi,cur_left,cur_right] = interp_missing(rows_in_roi,cur_left,cur_right)

int_missing = setdiff(min(rows_in_roi):max(rows_in_roi),rows_in_roi);
if isempty(int_missing)
    return
end

int_left  = interp1(rows_in_roi,cur_left,int_missing,'linear');
int_right = interp1(rows_in_roi,cur_right,int_missing,'linear');

allmat = [[rows_in_roi(:);int_missing(:)] [cur_left(:);int_left(:)] [cur_right(:);int_right(:)]];
allmat = sortrows(allmat);

rows_in_roi = allmat(:,1);
cur_left    = allmat(:,2);
cur_right   = allmat(:,3);









