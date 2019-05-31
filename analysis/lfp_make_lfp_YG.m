function lfp_make_lfp_YG(protocol_path, t1)
%t1 = 
%protocol_path = 'D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx'
Protocol = readtable(protocol_path);
% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Traces';

%% making lfp
    id = find(Protocol.ID == t1, 1);
    name = Protocol.name{id};
    filepath = Protocol.ABFFile{id};
[data, si, hd]=abfload(filepath);
raw_frq = round(1e6/si);
lfp_frq = 1e3;
cftn=round(1e3/si);

lfp = resample(data(1:end,3) - mean(data(1:end,3)), lfp_frq , raw_frq);


t_lfp = zeros(numel(lfp),1);
t_lfp = (1:numel(lfp))/60e3;


if 1
lfp_mv = lfp*0.003;% 0.007% 0.003% 0.0009
end

if 0
lfp_mv = -resample(data(1:end,1) - mean(data(1:end,1)), lfp_frq , raw_frq);
end
%% plot lfp
figure(1)
clf
hold on
plot(t_lfp,lfp_mv)

ylims = ylim;
tag_y = ylims(2);
i = 0;
for active_tag = 1:size(hd.tags,2)
    i = i+1;
    tag_x = hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60;
    %tag_y = tag_y + 3*abs(min(lfp)/10);
Lines(tag_x);

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x, tag_y,tagtext );
TagTime(i) = tag_x;
TagText(i) = {tagtext};
end
xlim([0 t_lfp(end)])
%ylim([0,4000])
%% saving

subfolder = 'lfp_trace';
save([save_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.mat'], 'lfp','lfp_mv','t_lfp', 'hd');

subfolder = 'lfp_image';
saveas(figure(1),[save_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.jpg']);
disp('saved')


end