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
   subfolder = 'FSS';
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
ControlFSS = [];
WashFSS = [];
RestoreTime = [];
SDFSS = [];
FASD = [];% first answer after SD
AASD = [];% alive till the end even after SD
FSS_FASD = [];% first FSS after SD
% end of experiment EOE
EOE_time = [];
EOE_FSS = [];

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

FSS = Results(i).FSS;
FSS(isnan(FSS)) = 0;
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

% packing
ControlFSS(i) = mean(FSS(STT <= OGDTime(i) & STT <= OGDTime(i) + afterOGDInterval));
WashFSS(i) = mean(FSS(STT >= washTime(i) & STT <= washTime(i) + standartInterval));
SDFSS(i) = mean(FSS(STT >= SDTime(i) - standartInterval/2 & STT <= SDTime(i) + standartInterval/2));
RestoreTime(i) = median(STT(STT >= washTime(i) & (FSS ~= 0)' )); % time when after wash spikes became normal
RestoreWashFSS(i) = median(FSS(STT >= RestoreTime(i) & STT <= RestoreTime(i) + standartInterval));
RI(i) = RestoreTime(i) - SDTime(i);% restore interval

% looking for first answer after SD (FASD) and cell alive even after SD
% (AASD)
if not(isnan(SDTime(i))) % if there was SD
    curFASD = find(FSS ~= 0 & (STT >= SDTime(i))',1)% (current) first answer after SD
    
    if isempty(curFASD)
        FASD(i) = nan;
        AASD(i) = 1; % alive till the end even after SD
        FSS_FASD(i)  = nan;
        STT_FASD(i) = nan;
    else
        FASD(i) = curFASD;
        AASD(i) = 0;
        FSS_FASD(i)  = FSS(FASD(i)); % first FSS after SD
        STT_FASD(i) = STT(FASD(i));% time of it
    end
   
else % if there was no SD
    FASD(i) = nan;
    AASD(i) = nan;
    FSS_FASD(i) = nan;
    STT_FASD(i) = nan;
end
    
% end of experiment EOE
EOE_time(i) = STT(end);
EOE_FSS(i) = FSS(end);

end


% count statistics:

RTASD = RestoreTime - [Results.SDTime];% restore time after SD

MControlFSS = nanmedian(ControlFSS);
MWashFSS = nanmedian(WashFSS);
MSDFSS = nanmedian(SDFSS);
MRestoreWashFSS = nanmedian(RestoreWashFSS);
MRI = nanmedian(RI);
MRIiqr = iqr(RI);
MRItext = [num2str(MRI,3) ' ' char(177) ' '  num2str(MRIiqr,3) ' (n = ' num2str(sum(not(isnan(RI))),3) ')' ];

MSDTime = nanmedian(SDTime);
MSDTimeIqr = iqr(SDTime);
MSDTimetext = [num2str(MSDTime,3) ' ' char(177) ' '  num2str(MSDTimeIqr,3) ' (n = ' num2str(numel(SDTime),3) ')' ];

MFASD = nanmedian(FSS_FASD);
MFASD_Time = nanmedian(STT_FASD - SDTime);
MFASD_Time_iqr = iqr(STT_FASD - SDTime);
MFASD_Time_text = [num2str(MFASD_Time,3) ' ' char(177) ' '  num2str(MFASD_Time_iqr,3) ' (n = ' num2str(sum(not(isnan(STT_FASD))),3) ')' ];


% experiments without SD
NoSD = sum(isnan(SDTime));
% number of lost cells
Lost = sum(EOE_FSS == 0);
% time of experiments after SD
MEOE_FSS = nanmedian(EOE_FSS(EOE_FSS ~= 0));
MEOE_time = nanmedian(EOE_time - SDTime);
MEOE_time_iqr = iqr(EOE_time - SDTime);
MEOE_time_text = [num2str(MEOE_time,3) ' ' char(177) ' '  num2str(MEOE_time_iqr,3) ' (n = ' num2str(sum(EOE_FSS ~= 0),3) ')' ];


% compare control SD and restored level
FSST = (1:numel(ControlFSS))*0;
SDFSS(SDFSS == 0) = nan;
RestoreWashFSS(RestoreWashFSS == 0) = nan;
EOE_FSS(EOE_FSS == 0) = nan;


linewidth = 1.5;

clf
axes('Position',[0.1,0.1,0.85,0.85])
hold on
plot(FSST-1, ControlFSS, 'bo', 'linewidth', linewidth)
%plot(WASD, WashFSS, 'x', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)
plot(FSST, SDFSS, 'ro', 'linewidth', linewidth)
plot(FSST+2, RestoreWashFSS, 'o', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)
plot(FSST+1, FSS_FASD, 'o', 'color',[0 0.8 0.5], 'linewidth', linewidth)
plot(FSST+3, EOE_FSS, 'o', 'linewidth', linewidth)

plot([-1 0 1 2 3], [MControlFSS MSDFSS MFASD MRestoreWashFSS MEOE_FSS], 'ko--', 'linewidth', linewidth)
set(gca,'XTickLabel',{'-',['-' MSDTimetext],...
    'SD',...
    ['SD +' MFASD_Time_text ' min'],...
    ['+' MRItext ' min'],...
    ['+' MEOE_time_text ''],...
    '+'})

ylim([0 max(ControlFSS)])
xlim([-2 4])
title(['First spike''s slope (FSS), mV/ms at different phases'])
ylabel('')
%legend('control FSS','FSS during SD','FSS after restoration', 'first FSS after SD', 'end' ,'median FSS')

axes('Position',[0.1,0.05,0.85,0.1], 'color', 'none')
set(gca,'ytick',[])
set(gca,'XTickLabel', {'', 'control', [num2str(NoSD) ' cells with no SD'], 'first FSS after SD', 'restoration (median FSS after SD)', [num2str(Lost) ' lost cells']})
xlim([-2 4])

%% save FSS_comp

save_folder = 'D:\Neurolab\Ischemia YG\Results';
subfolder = 'FSS_comp';
filename = subfolder;%[num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);
%% cheking FSS
i = 11
FSS = Results(i).FSS;
FSS(isnan(FSS)) = 0;
FSS = medfilt1(FSS,3);
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

di = FSS(STT > washTime(i) & (FSS ~= 0)' );
diT = STT(STT > washTime(i) & (FSS ~= 0)' );
RestoreTime = mean(STT(STT > washTime(i) & (FSS ~= 0)' )); % time when after wash spikes became normal

clf, hold on
plot(STT, FSS)
plot(diT, di)
Lines(RestoreTime)


