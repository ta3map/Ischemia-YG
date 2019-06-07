clear all
cd('D:\Neurolab\ialdev\Ischemia YG\analysis')
protocol_path = 'D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx';
save_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';

t1 = 488;
Protocol = readtable(protocol_path);
id = find(Protocol.ID == t1, 1);
name = Protocol.name{id};
disp('ID ok')
%% Load OIS data
oos_file = Protocol.IOSFile{id};

imSize = [348 260]% image size
dt = 2.5;% seconds between frames

[v_data, v_t] = readOOS(oos_file, imSize, dt);

%% load TTC image data
subfolder = 'TTC_OIS_oriented';
filename = [load_folder '\' subfolder '\' num2str(t1) '_' name '.tiff'];
t = Tiff(filename,'r');
TTCimageData = read(t);
disp('TTC image data loaded')

%% line probe
figure(1)
clf
imagesc(TTCimageData)

M = imfreehand(gca, 'Closed', 0)

P0 = M.getPosition;

%% TTC pixels at probe

ttc_pixels = [];
for pixel_numper = 1:size(P0, 1)
    Xs = int16(P0(pixel_numper,2));
    Ys = int16(P0(pixel_numper,1));
    ttc_pixels(pixel_numper, 1, :) = TTCimageData(Xs,Ys,:);
end
% convert to HSV 
hsv_ttc_pixels = rgb2hsv(ttc_pixels);
h_ttc = [];
h_ttc(:,1) = hsv_ttc_pixels(:,1,2);

figure(2)
clf
plot(smooth(h_ttc,3))

%% OIS pixels at probe

sizeCoef = size(v_data, 1)/size(TTCimageData,1);

basePixels = [];
for v_time_point = 1:100
    for pixel_numper = 1:size(P0, 1)
        Xs = int16(P0(pixel_numper,2)*sizeCoef);
        Ys = int16(P0(pixel_numper,1)*sizeCoef);
        basePixels(pixel_numper, v_time_point, :) = v_data(Xs,Ys,1,v_time_point);
    end
end
basePixels = mean(basePixels, 2);

ois_pixels = [];
relative_OIS_Pixels = [];
for v_time_point = 1:numel(v_t)
    for pixel_numper = 1:size(P0, 1)
        Xs = int16(P0(pixel_numper,2)*sizeCoef);
        Ys = int16(P0(pixel_numper,1)*sizeCoef);
        ois_pixels(pixel_numper, v_time_point, :) = v_data(Xs,Ys,1,v_time_point);
        relative_OIS_Pixels(pixel_numper, v_time_point, :) = 100*((ois_pixels(pixel_numper, v_time_point, :) - basePixels(pixel_numper))./basePixels(pixel_numper));
    end
end

%% OIS all data surface
smoothed_relative_OIS = imgaussfilt(relative_OIS_Pixels',[16 1]);

figure(2)
clf
subplot(211)
surface(smoothed_relative_OIS, 'edgecolor','none')
colormap gray

subplot(212)
plot(h_ttc)
xlim([0 numel(h_ttc)])

%% load OIS trace data
subfolder = 'ios_trace';
load([load_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.mat']);

%% compare TTC and OIS traces at sertain time
t_strt = 550;
t_end = 600;
Ylim =[-10 40]
interested_probe = 1;



t_strt_min = v_t(t_strt)/60;
t_end_min = v_t(t_end)/60;
OGD_time_min = 0;
time_text = ['from ' num2str(t_strt_min - OGD_time_min, 3) ' to ' num2str(t_end_min - OGD_time_min, 2) ' minutes, line probe']
mean_relative_OOS = mean(smoothed_relative_OIS(t_strt:t_end,:));

f = figure(2);
f.Position = [10  0  960  1040];
clf
% OIS part
D=axes;
set(D, 'Visible', 'on','position',[.565 .65 0.4 0.3]);
hold on
xlabel('Time, min')
ylabel('OIS, %')
ylim([min(SignalsIOS(n_probes,:)) max(SignalsIOS(n_probes,:))])
ylim(Ylim)
for n = 1:n_probes
smSignalsIOS(n,:) = smooth(SignalsIOS(n,:),3)
end
xlim([0 Time(end)])
h = plot(Time,smSignalsIOS)
set(h(interested_probe),'linewidth',2);
Lines(t_strt_min, [], 'b', '--')
Lines(t_end_min, [], 'b', '--')
title('OIS at probes')


E=axes;
set(E, 'Visible', 'off','position',[.01 .01 0.515 0.5]);
hold on
imshow(TTCimageData)
line(P0(:,1),P0(:,2), 'linewidth', 1, 'color', 'g')
arrow( P0(end - 1,:) , P0(end,:), 6, 20, 'color', 'g','linewidth', 1)


% TTC part
A=axes;
set(A, 'Visible', 'off','position',[.01 .5 0.5 0.5]);
hold on
imshow(ios_frame)
caxis([-40 40])
for n = 1:n_probes
rectangle('Position',pos(n,:), 'EdgeColor', 'green')
text(pos(n,1)+3,pos(n,2)+6,[num2str(n)], 'color', 'green')
end

axis off

B=axes;
set(B, 'Visible', 'on','position',[.565 .35 0.4 0.2]);
plot(mean_relative_OOS, 'linewidth', 1, 'color', 'k')
xlim([0 numel(h_ttc)])
ylabel(['OIS, % ' ])
title(time_text)

C=axes;
set(C, 'Visible', 'on','position',[.565 .1 0.4 0.2]);
plot(h_ttc*100, 'linewidth', 1, 'color', 'k')
xlim([0 numel(h_ttc)])
ylabel('TTC saturation, %')

%% save all about TTC and OIS comparison
subfolder = 'TTC_OIS_comparison_image';
saveas(figure(2),[save_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.jpg']);
