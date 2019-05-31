%% LFP's afferent volue, second part response comparison

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
   subfolder = 'AVSR2';
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

AVSR2_control = [];% AVSR2 at control time
AVSR2_BSD = [];% AVSR2 before SD
AVSR2_ASD = [];% AVSR2 after SD

i = 0;
for t1 = [Results.id]
    id = find(Protocol.ID == t1, 1);
    i = i+1;
% repacking from imput
washTime(i) = Results(i).washTime;
OGDTime(i) = Results(i).OGDTime;
SDTime(i) = Results(i).SDTime;

AVSR2 = Results(i).AVSR2;
AVSR2_times = Results(i).AVSR2_times';

AVSR2_control(i) = median(AVSR2(AVSR2_times < OGDTime(i)));
AVSR2_BSD(i) = median(AVSR2(AVSR2_times >= OGDTime(i) & AVSR2_times < SDTime(i)));     
AVSR2_ASD(i) = median(AVSR2(AVSR2_times >= SDTime(i)));  
end


Relat_AVSR2_before_SD = ((AVSR2_BSD - AVSR2_control)./AVSR2_control)*100;
Relat_AVSR2_after_SD = ((AVSR2_ASD - AVSR2_control)./AVSR2_control)*100;

before_SD_M = median(Relat_AVSR2_before_SD);
after_SD_M = median(Relat_AVSR2_after_SD);
g1g2g3_after = quantile(Relat_AVSR2_after_SD,3)

%% Significance
t = 1
sign_data_1 = Relat_AVSR2_before_SD;
sign_data_2 = Relat_AVSR2_after_SD;
p = signrank(sign_data_1,sign_data_2);
significant = p < 0.05;
test(t).sign_data_2 = sign_data_2;
test(t).sign_data_1 = sign_data_1;
test(t).p = p;
test(t).significant = significant;

%% graph
% compare control OGD and SD level 
Param_Time = zeros(numel([Results.id]),1);
linewidth = 1.5;

f = figure(1);
f.Position = [18  96  450  670];

clf
axes('Position',[0.1,0.1,0.85,0.825])
hold on
plot(Param_Time, Relat_AVSR2_before_SD, 'bo', 'linewidth', linewidth)
plot(Param_Time + 1, Relat_AVSR2_after_SD, 'ro', 'linewidth', linewidth)

plot([0 1], [before_SD_M after_SD_M], 'ko--', 'linewidth', linewidth)

set(gca,'XTickLabel',{...
    '-',...
    ['before SD'],...
    'SD',...
    ['after SD'],...
    '+'})


xlim([-0.5 1.5])
%ylim([-inf max(Relat_AVSR2_before_SD)*1.2])

title(['relative afferent value responce (AVR)',{},['% before and after SD, n = ' num2str(numel([Results.id]))]])
ylabel('')
%% BOXPLOT
f = figure(1);
f.Position = [18  96  450  670];
clf
boxplot([Relat_AVSR2_before_SD Relat_AVSR2_after_SD], [Param_Time; Param_Time+1])
set(gca,'XTickLabel',{...
    ['before SD'],...
    ['after SD']})
title(['relative afferent value responce (AVSR2)',{},['% before and after SD, n = ' num2str(numel([Results.id]))], ['significance p value = ' num2str(p, 1)]])
ylabel('%')
%% save AVSR2_comp

save_folder = 'D:\Neurolab\ialdev\Ischemia YG\Results';
subfolder = 'AVSR2_comp';
filename = subfolder;%[num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);
