%% LFP's avverent volue response comparison

% LOADING

clear all
Protocol = readtable('D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');
%
t1list = Protocol.ID(Protocol.LSS==1)'; % ID's with available data
clear Results
clear Sds

 i = 0;
for t1 = t1list
   i = i+1;
   id = find(Protocol.ID == t1, 1);
   name = Protocol.name{id};
   %% load parameter
   load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
   subfolder = 'AVP';
   filename = [num2str(t1) '_' subfolder '_' name '.mat'];
   filepath = [ load_folder '\' subfolder '\' filename];
   Results(i) = load([ load_folder '\' subfolder '\' filename])
   %% load SD times
   load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
   subfolder = 'SD';
   filename = [num2str(t1) '_' subfolder '_' name '.mat'];
   filepath = [ load_folder '\' subfolder '\' filename];
   if exist(filepath) == 2
   SDs(i) = load([ load_folder '\' subfolder '\' filename])
   end
end

% adding parameters from protocol
i = 0;
for t1 = t1list
    id = find(Protocol.ID == t1, 1);
    i = i+1;
Results(i).OGDTime = Protocol.OGDTime(id);
Results(i).washTime = Protocol.washTime(id);
Results(i).age = Protocol.age(id);
Results(i).SDTime = Protocol.SDTime(id);
Results(i).WASD = Results(i).washTime - Results(i).SDTime;
Results(i).id = t1;

end

%% ANALYSING

% exclude data wthout SD

Results(isnan([Results.SDTime])) = [];

% repacking data for condition cheking
washTime = [];
OGDTime = [];
SDTime = [];

AVP_control = [];% AVP at control time
AVP_BSD = [];% AVP before SD
AVP_ASD = [];% AVP after SD

i = 0;
for t1 = [Results.id]
    id = find(Protocol.ID == t1, 1);
    i = i+1;
% repacking from imput
washTime(i) = Results(i).washTime;
OGDTime(i) = Results(i).OGDTime;
SDTime(i) = Results(i).SDTime;

AVP = Results(i).AVP;
AVP_times = Results(i).AVP_times';

AVP_control(i) = median(AVP(AVP_times < OGDTime(i)));
AVP_BSD(i) = median(AVP(AVP_times >= OGDTime(i) & AVP_times < SDTime(i)));     
AVP_ASD(i) = median(AVP(AVP_times >= SDTime(i)));  
end


Relat_AVP_before_SD = ((AVP_BSD - AVP_control)./AVP_control)*100;
Relat_AVP_after_SD = ((AVP_ASD - AVP_control)./AVP_control)*100;

before_SD_M = median(Relat_AVP_before_SD);

after_SD_M = median(Relat_AVP_after_SD);

%% graph
% compare control OGD and SD level 
Param_Time = zeros(numel([Results.id]),1);
linewidth = 1.5;

f = figure(1);
f.Position = [18  96  450  670];

clf
axes('Position',[0.1,0.1,0.85,0.825])
hold on
plot(Param_Time, Relat_AVP_before_SD, 'bo', 'linewidth', linewidth)
plot(Param_Time + 1, Relat_AVP_after_SD, 'ro', 'linewidth', linewidth)

plot([0 1], [before_SD_M after_SD_M], 'ko--', 'linewidth', linewidth)
set(gca,'XTickLabel',{...
    '-',...
    ['before SD'],...
    'SD',...
    ['after SD'],...
    '+'})

xlim([-0.5 1.5])
%ylim([-inf max(Relat_AVP_before_SD)*1.2])

title(['relative afferent value responce (AVR)',{},['% before and after SD, n = ' num2str(numel([Results.id]))]])
ylabel('')

%% save AV_comp

save_folder = 'D:\Neurolab\ialdev\Ischemia YG\Results';
subfolder = 'AV_comp';
filename = subfolder;%[num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);
