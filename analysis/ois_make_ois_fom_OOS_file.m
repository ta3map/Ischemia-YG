clear all
cd('D:\Neurolab\ialdev\Ischemia YG\analysis')
protocol_path = 'D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx';
save_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';

% 77-83
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

%% make OIS with probes
n_probes = 2;% number of probes
[ios_frame, baseframe, SignalsIOS, Time, pos] = ois_make_ois(v_data, v_t, protocol_path, t1, n_probes, save_folder);

%% plot OIS
interested_probe = 1;
Ylim =[-30 30]
ois_plot_ois(protocol_path, t1, SignalsIOS, Time, Ylim, n_probes, ios_frame, pos, interested_probe)
%% save all about OIS
subfolder = 'ios_trace';
save([save_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.mat'], 'protocol_path', 't1', 'SignalsIOS', 'Time', 'Ylim', 'n_probes', 'ios_frame', 'pos', 'baseframe');
subfolder = 'ios_image';
saveas(figure(1),[save_folder '\' subfolder '\' num2str(t1) '_' subfolder '_' name '.jpg']);
disp('OIS trace saved')