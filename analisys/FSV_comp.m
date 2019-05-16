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
   subfolder = 'FSV';
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
ControlFSV = [];
WashFSV = [];
RestoreTime = [];
SDFSV = [];
FASD = [];% first answer after SD
AASD = [];% alive till the end even after SD
FSV_FASD = [];% first FSV after SD
% end of experiment EOE
EOE_time = [];
EOE_FSV = [];

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

FSV = Results(i).FSV;
FSV(isnan(FSV)) = 0;
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

% packing
ControlFSV(i) = mean(FSV(STT <= OGDTime(i) & STT <= OGDTime(i) + afterOGDInterval));
WashFSV(i) = mean(FSV(STT >= washTime(i) & STT <= washTime(i) + standartInterval));
SDFSV(i) = mean(FSV(STT >= SDTime(i) - standartInterval/2 & STT <= SDTime(i) + standartInterval/2));
RestoreTime(i) = median(STT(STT >= washTime(i) & (FSV ~= 0)' )); % time when after wash spikes became normal
RestoreWashFSV(i) = median(FSV(STT >= RestoreTime(i) & STT <= RestoreTime(i) + standartInterval));
RI(i) = RestoreTime(i) - SDTime(i);% restore interval

% looking for first answer after SD (FASD) and cell alive even after SD
% (AASD)
if not(isnan(SDTime(i))) % if there was SD
    curFASD = find(FSV ~= 0 & (STT >= SDTime(i))',1)% (current) first answer after SD
    
    if isempty(curFASD)
        FASD(i) = nan;
        AASD(i) = 1; % alive till the end even after SD
        FSV_FASD(i)  = nan;
        STT_FASD(i) = nan;
    else
        FASD(i) = curFASD;
        AASD(i) = 0;
        FSV_FASD(i)  = FSV(FASD(i)); % first FSV after SD
        STT_FASD(i) = STT(FASD(i));% time of it
    end
   
else % if there was no SD
    FASD(i) = nan;
    AASD(i) = nan;
    FSV_FASD(i) = nan;
    STT_FASD(i) = nan;
end
    
% end of experiment EOE
EOE_time(i) = STT(end);
EOE_FSV(i) = FSV(end);

end


% count statistics:

RTASD = RestoreTime - [Results.SDTime];% restore time after SD

MControlFSV = nanmedian(ControlFSV);
MWashFSV = nanmedian(WashFSV);
MSDFSV = nanmedian(SDFSV);
MRestoreWashFSV = nanmedian(RestoreWashFSV);
MRI = nanmedian(RI);
MRIiqr = iqr(RI);
MRItext = [num2str(MRI,3) ' ' char(177) ' '  num2str(MRIiqr,3) ' (n = ' num2str(sum(not(isnan(RI))),3) ')' ];

MSDTime = nanmedian(SDTime);
MSDTimeIqr = iqr(SDTime);
MSDTimetext = [num2str(MSDTime,3) ' ' char(177) ' '  num2str(MSDTimeIqr,3) ' (n = ' num2str(numel(SDTime),3) ')' ];

MFASD = nanmedian(FSV_FASD);
MFASD_Time = nanmedian(STT_FASD - SDTime);
MFASD_Time_iqr = iqr(STT_FASD - SDTime);
MFASD_Time_text = [num2str(MFASD_Time,3) ' ' char(177) ' '  num2str(MFASD_Time_iqr,3) ' (n = ' num2str(sum(not(isnan(STT_FASD))),3) ')' ];


% experiments without SD
NoSD = sum(isnan(SDTime));
% number of lost cells
Lost = sum(EOE_FSV == 0);
% time of experiments after SD
MEOE_FSV = nanmedian(EOE_FSV(EOE_FSV ~= 0));
MEOE_time = nanmedian(EOE_time - SDTime);
MEOE_time_iqr = iqr(EOE_time - SDTime);
MEOE_time_text = [num2str(MEOE_time,3) ' ' char(177) ' '  num2str(MEOE_time_iqr,3) ' (n = ' num2str(sum(EOE_FSV ~= 0),3) ')' ];

% compare control SD and restored level
FSVT = (1:numel(ControlFSV))*0;
SDFSV(SDFSV == 0) = nan;
RestoreWashFSV(RestoreWashFSV == 0) = nan;
EOE_FSV(EOE_FSV == 0) = nan;


linewidth = 1.5;

clf
axes('Position',[0.1,0.1,0.85,0.85])
hold on
plot(FSVT-1, ControlFSV, 'bo', 'linewidth', linewidth)
%plot(WASD, WashFSV, 'x', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)
plot(FSVT, SDFSV, 'ro', 'linewidth', linewidth)
plot(FSVT+2, RestoreWashFSV, 'o', 'color',[0.5 0.5 0.5], 'linewidth', linewidth)
plot(FSVT+1, FSV_FASD, 'o', 'color',[0 0.8 0.5], 'linewidth', linewidth)
plot(FSVT+3, EOE_FSV, 'o', 'linewidth', linewidth)

plot([-1 0 1 2 3], [MControlFSV MSDFSV MFASD MRestoreWashFSV MEOE_FSV], 'ko--', 'linewidth', linewidth)
set(gca,'XTickLabel',{'-',['-' MSDTimetext],...
    'SD',...
    ['SD +' MFASD_Time_text ' min'],...
    ['+' MRItext ' min'],...
    ['+' MEOE_time_text ''],...
    '+'})

ylim([-inf max(ControlFSV)*1.2])
xlim([-2 4])
title(['First spike''s value (FSV), mV at different phases'])
ylabel('')
%legend('control FSV','FSV during SD','FSV after restoration', 'first FSV after SD', 'end' ,'median FSV')

axes('Position',[0.1,0.05,0.85,0.1], 'color', 'none')
set(gca,'ytick',[])
set(gca,'XTickLabel', {'', 'control', [num2str(NoSD) ' cells with no SD'], 'first FSV after SD', 'restoration (median FSV after SD)', [num2str(Lost) ' lost cells']})
xlim([-2 4])

%% save FSV_comp

save_folder = 'D:\Neurolab\Ischemia YG\Results';
subfolder = 'FSV_comp';
filename = subfolder;%[num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);
%% cheking FSV
i = 11
FSV = Results(i).FSV;
FSV(isnan(FSV)) = 0;
FSV = medfilt1(FSV,3);
STT = Results(i).STT/Results(i).cftn/60e3;% minutes

di = FSV(STT > washTime(i) & (FSV ~= 0)' );
diT = STT(STT > washTime(i) & (FSV ~= 0)' );
RestoreTime = mean(STT(STT > washTime(i) & (FSV ~= 0)' )); % time when after wash spikes became normal

clf, hold on
plot(STT, FSV)
plot(diT, di)
Lines(RestoreTime)


