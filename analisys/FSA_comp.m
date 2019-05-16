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
%% load parameter
   load_folder = 'D:\Neurolab\Ischemia YG\Traces';
   subfolder = 'FSA';
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

%% analysing of spikes results

WASD = [Results.WASD];%wash time after SD

%control values
washTime = [];
OGDTime = [];
SDTime = [];
ControlFSA = [];
WashFSA = [];
RestoreTime = [];
SDFSA = [];

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

FSA = Results(i).FSA;
FSA(isnan(FSA)) = 0;
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

% packing
ControlFSA(i) = mean(FSA(STT <= OGDTime(i) & STT <= OGDTime(i) + afterOGDInterval));
WashFSA(i) = mean(FSA(STT >= washTime(i) & STT <= washTime(i) + standartInterval));
SDFSA(i) = mean(FSA(STT >= SDTime(i) - standartInterval/2 & STT <= SDTime(i) + standartInterval/2));
RestoreTime(i) = mean(STT(STT >= washTime(i) & (FSA ~= 0)' )); % time when after wash spikes became normal
RestoreWashFSA(i) = mean(FSA(STT >= RestoreTime(i) & STT <= RestoreTime(i) + standartInterval));
RI(i) = RestoreTime(i) - SDTime(i);% restore interval
end
% !! replacing nan to zeros
SDFSA(isnan(SDFSA)) = 0;
WashFSA(isnan(WashFSA)) = 0;

RTASD = RestoreTime - [Results.SDTime];% restore time after SD

MControlFSA = nanmedian(ControlFSA);
MWashFSA = nanmedian(WashFSA);
MSDFSA = nanmedian(SDFSA);
MRestoreWashFSA = nanmedian(RestoreWashFSA);
MRI = nanmedian(RI);
MRIiqr = iqr(RI);
MRItext = [num2str(MRI,3) ' ' char(177) ' '  num2str(MRIiqr,3) ' (n = ' num2str(numel(RI),3) ')' ];

MSDTime = nanmedian(SDTime);
MSDTimeIqr = iqr(SDTime);
MSDTimetext = [num2str(MSDTime,3) ' ' char(177) ' '  num2str(MSDTimeIqr,3) ' (n = ' num2str(numel(SDTime),3) ')' ];

%
clf, hold on
plot(ControlFSA)
plot(WashFSA)
plot(RestoreWashFSA)
plot(SDFSA, 'o-')

% compare control SD and restored level
FSAT = (1:numel(ControlFSA))*0;
clf, hold on
plot(FSAT-1, ControlFSA, 'bo')
plot(FSAT, SDFSA, 'ro')
plot(FSAT +1 , WashFSA, 'ko')
plot(FSAT+2, RestoreWashFSA, 'ko')

plot([-1 0 1 2], [MControlFSA MSDFSA MWashFSA MRestoreWashFSA], 'g-')

ylim([0 max(ControlFSA)])
xlim([-2 3])
% compare control SD and restored level - 2
linewidth = 1.5;
clf, hold on
plot(FSAT-2, ControlFSA, 'bo', 'linewidth', linewidth)
%plot(WASD, WashFSA, 'x', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)
plot(FSAT, SDFSA, 'ro', 'linewidth', linewidth)
plot(FSAT+2, RestoreWashFSA, 'o', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)


plot([-2 0 2], [MControlFSA MSDFSA MRestoreWashFSA], 'ko--', 'linewidth', linewidth)
set(gca,'XTickLabel',{'-',['control' ' (SD -' MSDTimetext ' min)'] ...
    ,'','SD','',['restoration (SD +' MRItext ' min)'],'+'})

ylim([0 max(ControlFSA)])
xlim([-3 3])
title(['First spike''s amplitude (FSA), mV at different phases'])
ylabel('')
legend('control FSA','FSA during SD','FSA after restoration',  'median FSA')

% save FSA_comp

save_folder = 'D:\Neurolab\Ischemia YG\Results';
subfolder = 'FSA_comp';
filename = subfolder;%[num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);
%% cheking FSA
i = 1
FSA = Results(i).FSA;
FSA(isnan(FSA)) = 0;
FSA = medfilt1(FSA,3);
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

di = FSA(STT > washTime(i) & (FSA ~= 0)' );
diT = STT(STT > washTime(i) & (FSA ~= 0)' );
RestoreTime = mean(STT(STT > washTime(i) & (FSA ~= 0)' )); % time when after wash spikes became normal

clf, hold on
plot(STT, FSA)
plot(diT, di)
Lines(RestoreTime)


