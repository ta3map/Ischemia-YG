%% Cell's data comparation - spikes

clear all
Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');


% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Traces';


%Cell's data comparation
% load all SD results
%
t1list = Protocol.ID(Protocol.CDS==1)'; % ID's with available data
clear Results
clear Sds
i = 0;


 i = 0;
for t1 = t1list
   i = i+1;
   id = find(Protocol.ID == t1, 1);
   name = Protocol.name{id};
%% load NSS (number of spikes)
   load_folder = 'D:\Neurolab\Ischemia YG\Traces';
   subfolder = 'NSS';
   filename = [num2str(t1) '_' subfolder '_' name '.mat'];
   filepath = [ load_folder '\' subfolder '\' filename];
   Results(i) = load([ load_folder '\' subfolder '\' filename])
%% load SD times
   load_folder = 'D:\Neurolab\Ischemia YG\Traces';
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

%% analysing Number of spikes (NSS) results

WASD = [Results.WASD];%wash time after SD

%control values
washTime = [];
OGDTime = [];
SDTime = [];
ControlNSS = [];
WashNSS = [];
RestoreTime = [];
SDNSS = [];

standartInterval = 0.5;%mean([Results.OGDTime]);%minutes
afterOGDInterval = 0;%minutes

i = 0;
for t1 = t1list
    id = find(Protocol.ID == t1, 1);
    i = i+1;
% repacking from imput
washTime(i) = Results(i).washTime;
OGDTime(i) = Results(i).OGDTime;
SDTime(i) = Results(i).SDTime;

NSS = Results(i).NSS;
NSS(isnan(NSS)) = 0;
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

% packing
ControlNSS(i) = mean(NSS(STT <= OGDTime(i) & STT <= OGDTime(i) + afterOGDInterval));
WashNSS(i) = mean(NSS(STT >= washTime(i) & STT <= washTime(i) + standartInterval));
SDNSS(i) = mean(NSS(STT >= SDTime(i) - standartInterval/2 & STT <= SDTime(i) + standartInterval/2));
RestoreTime(i) = mean(STT(STT >= washTime(i) & (NSS ~= 0)' )); % time when after wash spikes became normal
RestoreWashNSS(i) = mean(NSS(STT >= RestoreTime(i) & STT <= RestoreTime(i) + standartInterval));
RI(i) = RestoreTime(i) - SDTime(i);% restore interval
end
% !! replacing nan to zeros
SDNSS(isnan(SDNSS)) = 0;
WashNSS(isnan(WashNSS)) = 0;

RTASD = RestoreTime - [Results.SDTime];% restore time after SD

MControlNSS = nanmedian(ControlNSS);
MWashNSS = nanmedian(WashNSS);
MSDNSS = nanmedian(SDNSS);
MRestoreWashNSS = nanmedian(RestoreWashNSS);
MRI = nanmedian(RI);
MRIiqr = iqr(RI);
MRItext = [num2str(MRI,3) ' ' char(177) ' '  num2str(MRIiqr,3) ' (n = ' num2str(numel(RI),3) ')' ];

MSDTime = nanmedian(SDTime);
MSDTimeIqr = iqr(SDTime);
MSDTimetext = [num2str(MSDTime,3) ' ' char(177) ' '  num2str(MSDTimeIqr,3) ' (n = ' num2str(numel(SDTime),3) ')' ];

%
clf, hold on
plot(ControlNSS)
plot(WashNSS)
plot(RestoreWashNSS)
plot(SDNSS, 'o-')

% compare control SD and restored level
NSST = (1:numel(ControlNSS))*0;
clf, hold on
plot(NSST-1, ControlNSS, 'bo')
plot(NSST, SDNSS, 'ro')
plot(NSST +1 , WashNSS, 'ko')
plot(NSST+2, RestoreWashNSS, 'ko')

plot([-1 0 1 2], [MControlNSS MSDNSS MWashNSS MRestoreWashNSS], 'g-')

ylim([0 10])
xlim([-2 3])

%% compare control SD and restored level - 2
linewidth = 1.5;
clf, hold on
plot(NSST-2, ControlNSS, 'bo', 'linewidth', linewidth)
%plot(WASD, WashNSS, 'x', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)
plot(NSST, SDNSS, 'ro', 'linewidth', linewidth)
plot(NSST+2, RestoreWashNSS, 'o', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)


plot([-2 0 2], [MControlNSS MSDNSS MRestoreWashNSS], 'ko--', 'linewidth', linewidth)
set(gca,'XTickLabel',{'-',['control' ' (SD -' MSDTimetext ' min)'] ...
    ,'','SD','',['restoration (SD +' MRItext ' min)'],'+'})

ylim([0 10])
xlim([-3 3])
title(['Number of spikes (NS) at different phases'])
ylabel('')
legend('control NS','NS during SD','NS after restoration',  'median NS')
%% save CDS_NS_comparation

save_folder = 'D:\Neurolab\Ischemia YG\Results';
subfolder = 'CDS_NS_comparation';
filename = subfolder;%[num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);
%% cheking NSS
i = 13
NSS = Results(i).NSS;
NSS(isnan(NSS)) = 0;
NSS = medfilt1(NSS,3);
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

di = NSS(STT > washTime(i) & (NSS ~= 0)' );
diT = STT(STT > washTime(i) & (NSS ~= 0)' );
RestoreTime = mean(STT(STT > washTime(i) & (NSS ~= 0)' )); % time when after wash spikes became normal

clf, hold on
plot(STT, NSS)
plot(diT, di)
Lines(RestoreTime)


