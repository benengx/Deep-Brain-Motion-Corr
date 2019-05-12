function make_sharp_template(input_folder,output_folder,have_red_channel,use_red_channel)

if have_red_channel
    if use_red_channel
        frames_to_take = 2;
    else
        frames_to_take = 1;
    end
else
    frames_to_take = 0;
end

if isunix
    slashind = '/';
else
    slashind = '\';
end

sharptemplate_folder = [output_folder,'sharptemplates',slashind];

tiflist = dir([input_folder,'*.tif']);
tiflist_cell = cell(1,length(tiflist));
for i=1:length(tiflist)
    tiflist_cell{i} = tiflist(i).name;
end
tiflist_cell=sort(tiflist_cell);
for i=1:length(tiflist_cell)
    tiflist_full{i}= [input_folder,tiflist_cell{i}];
end

load([output_folder,'final_xy_shifts.mat'],'XX_cell','YY_cell')

if ~exist(sharptemplate_folder ,'dir')
    mkdir(sharptemplate_folder )
end


for i=1:length(tiflist_cell)
    tic
    disp(['applying pre-procesing to get sharper templates : file ',num2str(i)])
    cur_savefilename=[sharptemplate_folder,'template_',num2str(i),'.mat'];
    if exist(cur_savefilename,'file')
        continue
    end
    
    ImageStack = loadTiffStack_single(tiflist_full{i},frames_to_take);
    ImageStack_mc=apply_mc(ImageStack,YY_cell{i},XX_cell{i});
    ImageStack_mc2=ImageStack_mc>prctile(ImageStack_mc(1:99:end),90);
    ff2=std(log(ImageStack_mc2+1),[],3)/max(max(std(log(ImageStack_mc2+1),[],3)))*255;
    cur_template = single(ff2);
    save(cur_savefilename,'cur_template')
    
    disp(['Done file ',num2str(i),' of ',num2str(length(tiflist_full)),' in ',num2str(toc),' sec.'])
    
end



