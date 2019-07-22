% CELL'S LIFE TEST

clear all
t1 = 552% main ID
additional_id = 23 % additional experiment's ID

%% Load datas
cd('D:\Neurolab\ialdev\Ischemia YG\analysis')
protocol_path = 'D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx';
save_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
Protocol = readtable(protocol_path);
row_number1 = find(Protocol.ID == t1, 1);
name = Protocol.name{row_number1};

% open additional protocol
additional_protocol_filepath = Protocol.type_comment{row_number1}

AdditionalProtocol =  readtable(additional_protocol_filepath);

% read abf data file

row_number = find(AdditionalProtocol.ID == additional_id, 1);
name = AdditionalProtocol.name{row_number};
filepath = AdditionalProtocol.ABFFile{row_number};
% reading header
[~, ~, hd]=abfload(filepath, 'stop',1);
% name of interested channel
cftn=round(1e3/hd.si);

ch = 1;
chName = hd.recChNames(ch);
[Voltage_data, si, hd]=abfload(filepath, 'channels', chName);
Voltage_data=squeeze(Voltage_data);


ch = 2;
chName = hd.recChNames(ch);
[Current_data, si, hd]=abfload(filepath, 'channels', chName);
Current_data = squeeze(Current_data);
operated_current = Current_data(0.5e4, :);

figure(1)
clf
plot(Current_data)

%% plot

f = figure(1);
f.Position = [10  64  666  700];
clf
hold on
AzaManyCh(Voltage_data)%plot(Voltage_data)
ax = gca;
ydiap = (max(ax.YTick) - min(ax.YTick)) / (max(operated_current)-min(operated_current));
ax.YTickLabel = round(ax.YTick / ydiap + min(operated_current));
ax.XTickLabel = ax.XTick/cftn;
xlabel('Time (ms)')
ylabel('Current (pA)')

type_comment = AdditionalProtocol.type_comment{row_number};
titletext = [type_comment '_responses' ' (' num2str(additional_id) '_' num2str(t1) ')']
title(titletext, 'interpreter', 'none')

subfolder = 'additional_cells_experiments';
saveas(figure(1),[save_folder '\' subfolder '\' type_comment '\' num2str(t1) '_' num2str(additional_id) '_' type_comment '_responses' '_' name '.jpg']);
disp('saved')

%% count spike parameters

Voltage_data_CDS_format = Voltage_data(0.4e4:0.9e4, :);
% number of spikes, threshold for current, volue, slope, half-width, fire period, 
[NSS, FSS, FSA, FSOP, FSHW, FSV] = spikeResponseAnalys(Voltage_data_CDS_format, cftn);

ThesholdForCurrent = operated_current(find(NSS~=0,1));

spikePlotResponses(NSS, FSS, FSA, FSOP, FSHW, FSV, operated_current, t1, ['additional_experiment - ' name], cftn, hd)
subplot(411)
titletext = [type_comment '_response_parameters' ' (' num2str(t1) '_' num2str(additional_id) ')']
title(titletext, 'interpreter', 'none')

%% SAVE EVERYTHING

commentary = { 'NSS - number of spikes in sweep',...
'FSS - first spike slope',...
'FSA - first spike amplitude',...
'FSV - first spike volue',...
'FSOP - First Spike Onset Point',...
'FSHW - First Spike half width'};



subfolder = 'additional_cells_experiments';
save([save_folder '\' subfolder '\' type_comment '\parameters\' num2str(t1) '_' num2str(additional_id) '_' type_comment '_response_parameters' '_' name '.mat']);

subfolder = 'additional_cells_experiments';
saveas(figure(1),[save_folder '\' subfolder '\' type_comment '\parameters\' num2str(t1) '_' num2str(additional_id) '_' type_comment '_response_parameters' '_' name '.jpg']);
disp('saved')
