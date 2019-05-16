
% load abf
clear all

Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');
t1 = 462;
filepath = Protocol.ABFFile{find(Protocol.ID == t1, 1)};
name = Protocol.name{find(Protocol.ID == t1, 1)};

% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Traces';

% get header
[~, ~,hd]=abfload(filepath, 'start', 1, 'stop', 2);
% load ONLY cell data
[data, si, hd]=abfload(filepath,'channels', hd.recChNames(1));
cftn=round(1e3/si);
data_time = 1:size(data,1);

%% - CBL (baseline for cell data)

CBLStep = 99988.555;
filtSize = 5;
CBL = smooth(medfilt1(data(1:CBLStep:end,1), filtSize), filtSize);
CBLTime = (0:numel(CBL)-1)*CBLStep;
CBL(1:10)= median(CBL(10:19));
CBL(end-20:end)= median(CBL(end-40:end-20));


figure(1)
clf
axis([],'position', [0.1 0.1 0.9 0.9])
hold on
title([num2str(t1) '_cell_baseline_(CBL)_' name], 'Interpreter', 'none')

plot(CBLTime/cftn/60e3, data(1:CBLStep:end,1))
plot(CBLTime/cftn/60e3, CBL, 'color', 'r', 'linewidth', 3)
xlim([0 size(data,1)/60e3/cftn])
legend('downsampled cell data', 'baseline - median and gauss filter')

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = (hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8);

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60, 3), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
xlabel('Time, min')
ylabel('Amplitude, mV')

ax2 = axes('Position',[0.6 0.2 0.28 0.1]);
hold on
title('first seconds')
plot((1:1e6)/1e3/cftn, data(1:1e6, 1), 'color', 'g')
ylim(Ylim)
set(gca,'Color','none')
xlabel('Time, sec')
ylabel('Amplitude, mV')
%% save CBL, graph
subfolder = 'CBL';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'CBL', 'CBLTime', 'CBLStep', 'filtSize', 'cftn')
%save graph
subfolder = [subfolder '_images'];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])
disp([subfolder ' saved']);
%% detect step start points inside small part (datin)
ist = 1;
ind = 1e6;

cellDatin = data(ist:ind,1);

DiffCellDatin = diff(cellDatin);
MedianCellDatin = medfilt1(cellDatin, 3e3);
DiffMedianCellDatin = diff(MedianCellDatin);

trigDatinTime = find(DiffMedianCellDatin>0.2);
trigOffDatinTime = find(DiffMedianCellDatin<-0.1);

trigDatinTime(diff(trigDatinTime) < 90e3) = [];
trigOffDatinTime(diff(trigOffDatinTime) < 90e3) = [];

clf
hold on
plot(cellDatin)
%plot(DiffCellDatin)
plot(MedianCellDatin)
plot(DiffMedianCellDatin)
Lines(trigDatinTime);
Lines(trigOffDatinTime, [], 'b');
%% - STT (step triggering times)

STT = [];

datinSize = ind-ist+1;
numOfDatins = round(size(data,1)/datinSize);
persents = 0;
for i = 1:numOfDatins-2
    
    if persents ~= round(((i+1)/numOfDatins)*100)
        persents = round(((i+1)/numOfDatins)*100);
    disp([num2str(persents) '%'])
    end
ist = i*datinSize;
ind = i*datinSize + datinSize;

cellDatin = data(ist:ind,1);

DiffCellDatin = diff(cellDatin);
MedianCellDatin = medfilt1(cellDatin, 3e3);
DiffMedianCellDatin = diff(MedianCellDatin);

trigDatinTime = find(DiffMedianCellDatin>0.2);
trigOffDatinTime = find(DiffMedianCellDatin<-0.1);

trigDatinTime(diff(trigDatinTime) < 90e3) = [];
trigOffDatinTime(diff(trigOffDatinTime) < 90e3) = [];

STT = [STT; trigDatinTime+ist];
end

disp('STT compleded')

diffSTT = diff(STT);
trigInterval = median(diffSTT);

clf
hold on
plot(diff(STT))
plot([1 size(STT,1)],[trigInterval trigInterval])


% STT - correction
STT(diffSTT<trigInterval*(1-0.15)) = [];
%% Check STT at the end
inst = size(data, 1) - trigInterval*20;
clf
hold on
plot(data_time(inst:end), data(inst:end,1))
Lines(STT(STT>inst));
%% - CDS (Cell-data-sweeps)
stepInterval = 4000;
dataEndTime = (data_time(end)/60e3)/cftn;
afterTrigger =  stepInterval;%500*cftn;
beforeTriggerStart = 2*cftn;
trigs_num = numel(STT);

ch = 1;
CDS = [];
CDS_baseline = [];
for n=1:trigs_num
    CDS_baseline(:, n) =  median(data(STT(n) - beforeTriggerStart: STT(n) , ch));
    CDS(:, n) = data(STT(n) : STT(n) + afterTrigger, ch);
end   
%
figure(1)
clf
subplot(211)
imst = 1;
%imnd = stepInterval;%cftn*70;
imagesc(CDS(imst:end, :))
colormap(jet)
caxis([-200 200])

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = 4*(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/cftn);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60, 3), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end

% compare cell data sweeps

someinx = 1

subplot(223)
hold on
plot(CDS(:, :))
plot(CDS(:, someinx), 'color', 'k', 'linewidth', 3)

subplot(211)
hold on
plot(someinx,[1] , 'V', 'color', 'k', 'linewidth', 3);

subplot(224)
plot(data(STT(someinx)-stepInterval:STT(someinx)+stepInterval,1))
Lines(stepInterval);
%% delete suspicious sweep
CDS(:, someinx) = [];
STT(someinx) = [];
%% CDS-end mefdiltration

MedCDSend = medfilt1(CDS(end, :), 6);

clf
hold on
plot(STT,CDS(end, :), 'color', 'k', 'linewidth', 3)
plot(STT,MedCDSend, 'color', 'b', 'linewidth', 2)
%Lines(STT(CDS(end, :)<-50));

badSTT = abs(CDS(end, :) - MedCDSend) > 10;
Lines(STT(badSTT));

legend('CDS-end', 'median CDS-end', 'bad CDS-end')
% save medfiltDataTime, medfiltData
%% delete bad STT
STT(badSTT) = [];
CDS(:, badSTT == 1) = [];
%% re-check CDS
figure(1)
clf
subplot(211)
imst = 1;
%imnd = stepInterval;%cftn*70;
imagesc(CDS(imst:end, :))
colormap(jet)
caxis([-200 200])

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = 4*(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/cftn);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60, 3), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end

% compare cell data sweeps

someinx = 1

subplot(223)
hold on
plot(CDS(:, :))
plot(CDS(:, someinx), 'color', 'k', 'linewidth', 3)

subplot(211)
hold on
plot(someinx,[1] , 'V', 'color', 'k', 'linewidth', 3);

subplot(224)
plot(data(STT(someinx)-stepInterval:STT(someinx)+stepInterval,1))
Lines(stepInterval);
%% save CDS
subfolder = 'CDS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'CDS', 'STT', 'stepInterval', 'trigInterval', 'cftn')
disp([subfolder ' saved']);

%% LOAD saved CDS data

Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');
for t1 = [450 451 452 453 454 455 456 457 458 459 460 461 462 469 470]
filepath = Protocol.ABFFile{find(Protocol.ID == t1, 1)};
name = Protocol.name{find(Protocol.ID == t1, 1)};

% load directory
load_folder = 'D:\Neurolab\Ischemia YG\Traces';

subfolder = 'CDS';
filename = [num2str(t1) '_' subfolder '_' name];
load([load_folder '\' subfolder '\' filename], 'CDS', 'STT', 'stepInterval', 'trigInterval', 'cftn')
disp([subfolder ' loaded']);

% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Traces';

% get header
[~, ~,hd]=abfload(filepath, 'start', 1, 'stop', 2);
%% - [NSS,...] Step-spike parameters
% NSS - number of spikes in sweep
% FSS - first spike slope
% FSA - first spike amplitude
% FSHW - first spike half-width
% FSV - first spike value
% FSOP - First Spike Onset Point

cd('D:\Neurolab\Ischemia\step and stimuli response analysis')
[NSS, FSS, FSA, FSOP, FSHW, FSV] = spikeResponseAnalys(CDS, cftn);

clf
hold on
plot(STT/cftn/60e3, NSS)
plot(STT/cftn/60e3, FSS)
plot(STT/cftn/60e3, FSA)
plot(STT/cftn/60e3, FSV)
plot(STT/cftn/60e3, FSHW)

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = (hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8);

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
xlabel('Time, minutes')
xlim([0 STT(end)/cftn/60e3])

legend('number of spikes', 'first spike slope', 'first spike amplitude','first spike volue','first spike half width' )
%% save  [NSS,...] and graph
subfolder = 'NSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'NSS','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'FSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSS','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'FSA';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSA','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'FSV';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSV','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'FSHW';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSHW','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'NSS, FSS, FSA images';
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);

end