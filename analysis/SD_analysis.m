%% SD peak time on cell's data

clear all
Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');

% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Sweeps';
% load directory
load_folder = 'D:\Neurolab\Ischemia YG\Sweeps';
%%
checkWindowMnts = 8;% some time interval for automatic enhancement
OnsetThreshold = 2;% some threshold for detecting onset
% chose id
for t1 = 468
figure(1)
clf
%% load cell's baseline data

load_folder = 'D:\Neurolab\Ischemia YG\Sweeps';
id = find(Protocol.ID == t1, 1);
name ='none';

if not(isempty(id))
name = Protocol.name{id};

% load CBL (cell base line)
subfolder = 'CBL';
filename = [num2str(t1) '_' subfolder '_' name];
load([ load_folder '\' subfolder '\' filename], 'CBL', 'CBLTime', 'CBLStep', 'filtSize', 'cftn')
CBLTimeMnts = CBLTime/cftn/60e3;


clf
hold on
plot(CBLTimeMnts, CBL, 'color', [0.3 0.3 0.1])


%% add IOS data, to be sure that cell's SD was real
load_folder = 'D:\Neurolab\Ischemia YG\Traces'
% load ios trace
subfolder = 'ios_trace';
filename = [num2str(t1) '_' subfolder '_' name];

if  exist([ load_folder '\' subfolder '\' filename '.mat']) ==2
    load([ load_folder '\' subfolder '\' filename])

plot(Time, SignalIOS)
disp('IOS plotted')
else
    disp(['no IOS for such id ' num2str(t1)])
end
%% set SDT (SD time), SDV (cell's volue at SD)
[SDT, SDV] = ginput(1);

TimeIntervalOK = CBLTimeMnts>(SDT-checkWindowMnts) & CBLTimeMnts<(SDT+checkWindowMnts);
SDIntervalTime = CBLTimeMnts(TimeIntervalOK);
SDInterval = CBL(TimeIntervalOK);
else
    disp(['no such id ' num2str(t1)])
end
end


%% automatically detect SDOT (SD onset time), SDOV (SD onset value), SDBL (SD baseline)
% SD interval differential:
SDIntervalDiff = [0; diff(smooth(SDInterval,6))];
SDIntervalDiff2 = [0; diff(smooth(SDIntervalDiff,6))];

[~, SDOIntervalInx] = max(SDIntervalDiff);
SDOIntervalInx = find(SDIntervalDiff > OnsetThreshold, 1);
SDOT = SDIntervalTime(SDOIntervalInx);
SDOV = SDInterval(SDOIntervalInx);
BLwindow = 1;% minutes
SDBLOK = SDIntervalTime > (SDOT - BLwindow*2) & SDIntervalTime < (SDOT);
SDBL = median(SDInterval(SDBLOK)); % SD baseline
SDBLT = SDOT; % SD baseline time

% SDV SDT enhancement 
[SDV, SDTinx]  = max(SDInterval);% SD value
SDT = SDIntervalTime(SDTinx);% SD time

% SDA (SD amplitude)
SDA = SDV - SDBL; % mV;

% SDL (SD length), SDOFT (SD offset time)
OFthreshold = SDV - SDA*0.8; % 15 percents of SD amplitude
SDOFTinx = find(SDInterval(SDTinx:end) < OFthreshold, 1)
SDOFTinx = SDOFTinx + SDTinx-1;% SD offset index
% SDOFP (SD offset point)
SDOFP = SDIntervalTime(SDOFTinx);
SDL = SDOFP - SDBLT; 

% SDHW (SD half-width)
HWthreshold = SDV - SDA*0.5; % 50 percents of SD amplitude
SDHWendInx = find(SDInterval(SDTinx:end) < HWthreshold, 1)
SDHWendInx = SDHWendInx + SDTinx-1;% half-width index after peak
SDHWbefInx = find(SDInterval(1:SDTinx) > HWthreshold, 1)-1;% half-width index before peak
SDHW = SDIntervalTime(SDHWendInx) - SDIntervalTime(SDHWbefInx);

linewidth = 2;
clf, hold on
plot(SDIntervalTime,SDInterval, 'linewidth', linewidth)
plot(SDIntervalTime,SDIntervalDiff*10, 'linewidth', linewidth)
plot(SDIntervalTime,SDIntervalDiff2*100, 'linewidth', linewidth)
plot(SDOT, SDOV, 'ro', 'linewidth', linewidth)
plot(SDBLT, SDBL, 'ko', 'linewidth', linewidth)
plot(SDT, SDV, 'go', 'linewidth', linewidth)
text(SDT, SDV, ['       SD peak amplitude = ' num2str(SDA, 3) ' mV'], 'interpreter', 'none')

plot(SDOFP, SDInterval(SDOFTinx) , 'bo', 'linewidth', linewidth)
text(SDOFP, SDInterval(SDOFTinx) , ['       SD length = ' num2str(SDL, 3) ' min'], 'interpreter', 'none')

plot([SDIntervalTime(SDHWbefInx) SDIntervalTime(SDHWendInx)], [ SDInterval(SDHWbefInx) SDInterval(SDHWendInx)], '', 'linewidth', linewidth)
text(SDIntervalTime(SDHWendInx), SDInterval(SDHWendInx) , ['       Half-width = ' num2str(SDHW, 3) ' min'])

grid on
legend('baseline data', 'diff 1 x 10', 'diff2 x 100', 'SD onset', 'SD baseline', 'SD peak', 'SD length', 'half-width')

%% save SDA, SDV, SDT, SDBL, SDBLT, SDL, SDHW, graph

save_folder = 'D:\Neurolab\Ischemia YG\Traces';
subfolder = 'SD';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'SDA', 'SDV', 'SDT', 'SDBL', 'SDBLT', 'SDL', 'SDHW', 'checkWindowMnts', 'BLwindow', 'OnsetThreshold')

subfolder = 'SD images';
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);