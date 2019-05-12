
function make_traces(output_folder,tif_files_prefix,roi_files_cell)

single_filename = [output_folder,tif_files_prefix,'.tif'];
if exist (single_filename ,'file')
    tiflist_full{1}= single_filename;
else
    multfiles = dir([output_folder,tif_files_prefix,'_part*.tif']);
    for i=1:length(multfiles)
        tiflist_full{i}= [output_folder,tif_files_prefix,'_part',num2str(i),'.tif'];
    end
end

InfoImage=imfinfo(tiflist_full{1});
mImage=InfoImage(1).Width;
nImage=InfoImage(1).Height;

for k=1:length(roi_files_cell)
    sROI = ReadImageJROI(roi_files_cell{k});
    cur_mask_cell{k}=make_mask_from_roi(sROI,[nImage mImage])>0;
    if length(roi_files_cell)==1
        roi_name{k} = [ tif_files_prefix,'_ROI_0000-0001'];
    else
        roi_name{k} = [ tif_files_prefix,'_ROI_',sROI.strName];
    end
    
    num_pixels_in_mask(k) = sum(sum(cur_mask_cell{k}));
end

for i=1:length(tiflist_full)
    filename=tiflist_full{i};
    
    InfoImage=imfinfo(filename);
    
    NumberImages=length(InfoImage);
    for k=1:length(roi_files_cell)
        cur_trace_cell{k} = zeros(NumberImages,1);
    end
    for j=1:NumberImages
        cur_frame=imread(filename,'Index',j,'Info',InfoImage);
        for k=1:length(roi_files_cell)
            cur_trace_cell{k}(j) = sum(sum(double(cur_frame).*cur_mask_cell{k}));
        end
    end
    for k=1:length(roi_files_cell)
        traces_cell{k}{i} = cur_trace_cell{k}/num_pixels_in_mask(k);
    end
end

for k=1:length(roi_files_cell)    
    trace = traces_cell{k};
    save([output_folder,roi_name{k}],'trace')
end

