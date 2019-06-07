clear all
cd('D:\Neurolab\ialdev\Ischemia YG\analysis')
protocol_path = 'D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx';
save_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';

% 77-83
t1 = 490;
Protocol = readtable(protocol_path);
id = find(Protocol.ID == t1, 1);
name = Protocol.name{id};
disp('ID ok')
%% load image data
subfolder = 'TTC_OIS_oriented';
filename = [load_folder '\' subfolder '\' num2str(t1) '_' name '.tiff'];
t = Tiff(filename,'r');
imageData = read(t);
%% plot image
clf
figure(1)
imagesc(imageData)