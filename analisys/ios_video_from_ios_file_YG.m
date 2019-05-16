
clear all

Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');
% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Traces';
eachframe = 5;
s = 1;%save

for t1 = [470]
    id = find(Protocol.ID == t1, 1);
    name = Protocol.name{id};
    startframe = 1e3;
v_path = Protocol.IOSFile{id};%'\\IFMB-02-024B-10\Ischemia2\IOS\2018-09-26\2018-09-26_13-46-46.ios'%
[v_data, v_t] = readIOS(v_path, 'startframe', startframe, 'eachframe', eachframe, 'Format', 'Lin', 'resize', 1);
%%
baseframe = mean(squeeze(v_data(:,:,:,1:100)),3);

%videoframes = squeeze(double(v_data(:,:,:, 1:end)));
%baseframe = mean(videoframes(:,:,1:100),3);
%baseframe = mean(videoframes(:,:,1:100),3);

sigmac = 2;
baseframe = imgaussfilt(baseframe, sigmac);


figure(2)
clf
colormap(gray)
imagesc(flipud(baseframe))
 imagesc(flipud(v_data(:,:,1, 1)));
%imagesc(flipud(videoframes(:,:,1,1, 1)));
probe = round(ginput(1))



subfolder = 'ios_video';
v_out = [save_folder  '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.mp4'];
mov = vision.VideoFileWriter('Filename', v_out, 'FileFormat', 'MPEG4');
set(mov, 'FrameRate', 30, 'AudioInputPort', false, 'VideoCompressor', 'DV Video Encoder');

clf
hold on
colormap(gray)
A=axes;
set(A, 'Visible', 'off','position',[.0 .0 1 1]);
frame = double(v_data(:,:,1,1));
imagesc(flipud(frame));
st = 15;
pos = [ probe(1)-st/2 probe(2)-st/2 st st]
rectangle('Position',pos, 'EdgeColor', 'green')
%probe = round(ginput(1))
%probe(2) = size(frame,2) - probe(2)
%st = 2;
x_point = probe(1);
y_point = probe(2);
y_point = size(frame,1) - probe(2);
%%
clear SignalIOS
persents = 0;
i = 0;
m_frames = numel(v_t);

for m = 1:m_frames

i = i+1;

if persents < round(100*m/m_frames)
persents = round(100*m/m_frames); 
disp([num2str(persents) ' %']);
end


frame = imgaussfilt(double(v_data(:,:,1,round(m))), sigmac);% 
%frame = imgaussfilt(videoframes(:,:,i), sigmac);;
ios_frame = 100*((frame - baseframe)./baseframe);

clf
hold on
colormap(gray)
A=axes;
set(A, 'Visible', 'off','position',[.0 .0 1 1]);
imshow(flipud(ios_frame));
axis off
caxis([-40 40])

text(10, 10, [num2str(m)], 'Color', 'r', 'FontSize',12 );
text(70, 10, ['frame x' num2str(eachframe)], 'Color', 'r', 'FontSize',12 );
text(10, 30, [num2str(round((m/24)*60))], 'Color', 'r', 'FontSize',12 );
text(70, 30, ['sec'], 'Color', 'r', 'FontSize',12 );
text(10, 60, [num2str(m/24,3)], 'Color', 'g', 'FontSize',14 );
text(60, 60, ['min'], 'Color', 'g', 'FontSize',14 );
rectangle('Position',pos, 'EdgeColor', 'green')
pause(0.01)

shot = getframe;
step(mov, shot.cdata);

ios_yinxes = round(y_point-st/2 : y_point+st/2);
ios_xinxes = round(x_point-st/2 : x_point+st/2);
 
SignalIOS(i) = mean(mean(ios_frame(ios_yinxes,ios_xinxes)));

end
release(mov);

Time = (1:numel(SignalIOS))/24

%% tags from lfp
%SignalIOS_2 = locdetrend(SignalIOS, 1, [1000, 10]);%medfilt1(SignalIOS,5);
%[pks,locs] = findpeaks(SignalIOS_2, 'Threshold',0.8, 'MinPeakDistance',10);

figure(1)
clf
hold on
xlabel('Time, min')
ylabel('IOS, %')
ylim([0 max(SignalIOS)])
%
load_folder = 'D:\Neurolab\Ischemia YG\Traces\lfp_trace\';

if  exist([load_folder num2str(t1) '_lfp_trace_' name '.mat']) ==2

load([load_folder num2str(t1) '_lfp_trace_' name '.mat'], 'lfp','hd');
%t_lfp = (1:numel(lfp))/60e3;
%plot(t_lfp,100*(lfp./max(lfp)))
Ylim = ylim;

lost_time = t_lfp(end) - Time(end);

tag_y = Ylim(2);
for active_tag = 1:size(hd.tags,2)
    tag_x = hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60;
    %tag_y = tag_y + 5;
Lines(tag_x);

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x, tag_y,tagtext );
end
end

plot(Time + lost_time,SignalIOS)
xlim([0 Time(end)+ lost_time])
%% save
if 1
subfolder = 'ios_trace';
save([save_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.mat'], 'Time','SignalIOS', 'x_point', 'y_point');

subfolder = 'ios_image';
saveas(figure(1),[save_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.jpg']);
end
disp('ios saved')
end

%% save blics

SignalIOS_2 = locdetrend(SignalIOS, 1, [1000, 10]);%medfilt1(SignalIOS,5);
[pks,locs] = findpeaks(SignalIOS_2, 'Threshold',0.8, 'MinPeakDistance',10);

figure(2)
clf
hold on
plot(Time,SignalIOS_2)
Lines(Time(locs))

save('D:\Neurolab\Ischemia\point_tracking\283_blics.mat', 'Time', 'SignalIOS_2', 'locs')