function [ios_frame, baseframe, SignalsIOS, Time, pos] = ois_make_ois(v_data, v_t,protocol_path, t1, n_probes, save_folder)
Protocol = readtable(protocol_path);
id = find(Protocol.ID == t1, 1);
name = Protocol.name{id};

%% making baseframe and taking probes
baseframe = mean(squeeze(v_data(:,:,:,1:100)),3);
sigmac = 2;
baseframe = imgaussfilt(baseframe, sigmac);

figure(2)
clf
colormap(gray)
imagesc((baseframe))
imagesc((v_data(:,:,1, 1)));

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
imagesc(frame);
st = 15;


for n = 1:n_probes
    probe = round(ginput(1))
    pos(n,:) = [ probe(1)-st/2 probe(2)-st/2 st st];
    x_point(n) = probe(1);
    y_point(n) = probe(2);
    rectangle('Position',pos(n,:), 'EdgeColor', 'green')
    text(pos(n,1)+3,pos(n,2)+6,[num2str(n)], 'color', 'green')
end
%% making OIS video
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
ios_frame = 100*((frame - baseframe)./baseframe);

clf
hold on
colormap(gray)
A=axes;
set(A, 'Visible', 'off','position',[.0 .0 1 1]);
imshow((ios_frame));
axis off
caxis([-40 40])

text(10, 10, [num2str(m)], 'Color', 'r', 'FontSize',12 );
%text(70, 10, ['frame x' num2str(eachframe)], 'Color', 'r', 'FontSize',12 );
text(10, 30, [num2str(round((m/24)*60))], 'Color', 'r', 'FontSize',12 );
text(70, 30, ['sec'], 'Color', 'r', 'FontSize',12 );
text(10, 60, [num2str(m/24,3)], 'Color', 'g', 'FontSize',14 );
text(60, 60, ['min'], 'Color', 'g', 'FontSize',14 );

for n = 1:n_probes
rectangle('Position',pos(n,:), 'EdgeColor', 'green')
text(pos(n,1)+3,pos(n,2)+6,[num2str(n)], 'color', 'green')
ios_yinxes(n,:) = round(y_point(n)-st/2 : y_point(n)+st/2);
ios_xinxes(n,:) = round(x_point(n)-st/2 : x_point(n)+st/2);
SignalsIOS(n,i) = mean(mean(ios_frame(ios_yinxes(n),ios_xinxes(n))));
end

pause(0.01)
shot = getframe;
step(mov, shot.cdata);
end
release(mov);

Time = (1:numel(SignalsIOS(n,:)))/24
end