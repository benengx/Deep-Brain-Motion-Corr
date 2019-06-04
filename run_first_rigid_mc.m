function run_first_rigid_mc(input_folder,output_folder,have_red_channel,use_red_channel)

if have_red_channel
    if use_red_channel
        frames_to_take = 2;
    else
        frames_to_take = 1;
    end
else
    frames_to_take = 0;
end

tiflist = dir([input_folder,'*.tif']);
tiflist_cell = cell(1,length(tiflist));
XX_cell = cell(1,length(tiflist));
YY_cell = cell(1,length(tiflist));
for i=1:length(tiflist)
    tiflist_cell{i} = tiflist(i).name;
end
tiflist_cell=sort(tiflist_cell);
for i=1:length(tiflist_cell)
    tiflist_full{i}= [input_folder,tiflist_cell{i}];
end

%first motion correct each file separately
for i=1:length(tiflist_full)
    stack=loadTiffStack_single(tiflist_full{i},frames_to_take);
    [total_i_vec,total_j_vec,template] = mc_rigid...
        (stack,50,10,30,1,0,1,-1,1);
    
    XX_cell{i} = total_j_vec;
    YY_cell{i} = total_i_vec;
    
    if i==1
       template_file = zeros([size(template) length(tiflist_full)],'single');        
    end
    template_file(:,:,i) = template;    
end

saveastiff(template_file,[output_folder,'template_mov_uncor.tif']);
%now motion correct the templates and add the shifts to the separate file shifts obtained earlier.

    [i_vec_templates,j_vec_templates,~,~,~,templates_stack_mc] = mc_rigid...
        (template_file,size(template_file,3),10,30,1,0,1,-1,1);

for i=1:length(XX_cell)
    XX_cell{i} = XX_cell{i} + j_vec_templates(i);
    YY_cell{i} = YY_cell{i} + i_vec_templates(i);
    
end

save([output_folder,'final_xy_shifts.mat'],'XX_cell','YY_cell')
saveastiff(templates_stack_mc,[output_folder,'template_mov.tif']);

% if we are using the red channel, then also make a frames file for the
% green channel
if have_red_channel && use_red_channel
    templates_green = zeros(size(templates_stack_mc));
    for i=1:length(tiflist_full)
        stack=loadTiffStack_single(tiflist_full{i},1);
        mc_stack = apply_mc(stack,YY_cell{i},XX_cell{i});
        templates_green(:,:,i)=get_med_of_avg_template(mc_stack,50);        
    end
    saveastiff(templates_green,[output_folder,'template_mov_green.tif']);
end

