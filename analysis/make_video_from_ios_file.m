clear all

Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');

t1list = [471];
num_of_points = numel(t1list);
percents = 0;

n = 0;
for t1 = t1list
    n = n+1;
    
    id = find(Protocol.ID == t1, 1);
    name = Protocol.name{id};
    
    %ios file
    v_path = Protocol.IOSFile{id};

    if exist(v_path) == 2

        % заголовок
        ios_header = load([v_path(1:end-4) '.header.mat']);
        % желаемое разрешение 
        isoRes = [256 192]*2;
        rescoef = isoRes/ios_header.vidRes;% масштабный коэффициент (желаемое разрешение/разрешение видео)
        % частота ча
        eachframe = 5;
        [v_data, v_t] = readIOS(v_path, 'startframe', 1, 'eachframe', eachframe, 'Format', 'Lin', 'resize', rescoef);
        m_frames = size(v_data, 4);
        % make original video
        num_of_points2 = m_frames;
        percents2 = 0;
save_folder = 'D:\Neurolab\Ischemia YG\Traces\video\';
v_out = strcat(save_folder, '', num2str(t1),  '_video_', name, '.mp4');
mov = vision.VideoFileWriter('Filename', v_out, 'FileFormat', 'MPEG4');
set(mov, 'FrameRate', 30, 'AudioInputPort', false, 'VideoCompressor', 'DV Video Encoder');

for m = 1:m_frames
image_in = v_data(:,:,1,m);

if 0
n = 30*0.1;  
Idouble = im2double(image_in); 
avg = mean2(Idouble);
sigma = std2(Idouble);
low_in = avg-n*sigma;
 low_in(low_in<0)=0;    
 hight_in = avg+n*sigma;
 image_in = imadjust(image_in,[low_in hight_in],[]);
%image_in = imsharpen(image_in);
%image_in = imgaussfilt(image_in);
end

figure(2)
clf
colormap gray

A=axes;
set(A, 'Visible', 'off','position',[.0 .0 1 1]);
imshow(image_in)
axis off
caxis([0 6e3])

pause(0.01)
TimeFig = figure(2);
frame=getframe(TimeFig);
step(mov, frame.cdata)

    if percents2 ~= round(100*(m/num_of_points2))
    percents2 = round(100*(m/num_of_points2));
    disp(['making video ' num2str(percents2) '%'])
    end


    if percents ~= round(100*(n/num_of_points))
    percents = round(100*(n/num_of_points));
    disp(['total: ' num2str(percents) '%'])
    end


end

release(mov)

    end

end
    







%% watch original frame
m = 281;
image_in = v_data(:,:,1,m);
%image_in = image_in/1024*6;


if 0
 n = 23*0.1;  
 Idouble = im2double(image_in); 
 avg = mean2(Idouble);
 sigma = std2(Idouble);
 image_in = imadjust(image_in,[avg-n*sigma avg+n*sigma],[]);
end


clf
colormap gray;
%subplot(211),
imagesc(image_in);
%caxis([0 1024*6])
axis off
%%
% make trace
if m == 1
probe = round(ginput(1))
end

st = 400;
pos = [ probe(1)-st/2 probe(2)-st/2 st st];
rectangle('Position',pos, 'EdgeColor', 'green');
x_point = probe(1);
y_point = probe(2);
trace(m) = mean(mean(image_in(y_point-st/2:y_point+st/2, x_point-st/2:x_point+st/2)));

%
t_trace = (1:numel(trace))/6;
subplot(212), 
clf
hold on;
plot(t_trace, trace)
%%
title('19.10.17 colored cell image value');
y = ((trace(end)- trace(1))/2) + trace(1);
t = 5;, Lines(t);, text(t, y, 'control');
t = 5+15;, Lines(t);, text(t, y, 'OGD');
t = 5+15+15;, Lines(t);, text(t, y, 'wash');
t = 5+15+15+15;, Lines(t);, text(t, y, 'sach');
t = 5+15+15+15+15;, Lines(t);, text(t, y, 'wash');
t = m/6;, Lines(t, [], 'b');, text(t, y, 'point');

%%

writerObj = VideoWriter('myVideo.avi');
 writerObj.FrameRate = 10;
 open(writerObj);
 

for m = 1:m_frames
image_in = v_data(:,:,1,m);

n = 20*0.1;  
Idouble = im2double(image_in); 
avg = mean2(Idouble);
sigma = std2(Idouble);
image_in = imadjust(image_in,[avg-n*sigma avg+n*sigma],[]);
image_in = double(image_in);
image_in = image_in/65536;
%image_in = uint8(image_in);
frame = image_in;%im2frame();

clf, colormap gray
imagesc(image_in)
pause(0.01)

writeVideo(writerObj, frame);
end
 close(writerObj);