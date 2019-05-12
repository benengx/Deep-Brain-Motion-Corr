function proc_mov=pre_process_stack(mov)

p1 = make_gauss_square_image(10,1);
p2 = make_gauss_square_image(20,2);

proc_mov=mov;
if numel(proc_mov)<5e6
    cur_prctile = prctile(proc_mov(:),85);
else
    cur_prctile = prctile(proc_mov(1:99:end),85);
end
proc_mov(proc_mov<cur_prctile)=0;
if numel(proc_mov)<5e6
    cur_prctile = prctile(proc_mov(:),99.9);
else
    cur_prctile = prctile(proc_mov(1:99:end),99.9);
end
proc_mov(proc_mov>cur_prctile)=cur_prctile;
proc_mov=convn(proc_mov,p2,'same');
if numel(proc_mov)<5e6
    cur_prctile = prctile(proc_mov(:),50);
else
    cur_prctile = prctile(proc_mov(1:99:end),50);
end
proc_mov(proc_mov<cur_prctile)=0;
proc_mov=convn(proc_mov,p1,'same');

