%% load abf
clear all

Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');
t1 = 470;
filepath = Protocol.ABFFile{find(Protocol.ID == t1, 1)};
name = Protocol.name{find(Protocol.ID == t1, 1)};

% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Sweeps';

[data, si, hd]=abfload(filepath);
cftn=round(1e3/si);
data_time = 1:size(data,1);
%% detect step start points inside small part (datin)

ist = 1e6;
ind = 2e6;
ch = 4;
datin = data(ist:ind, ch);
trigDatinTime = find(diff(datin)>2.5);
trigOffDatinTime = find(diff(datin)<-1.5);
trigOffDatinTime(trigOffDatinTime<trigDatinTime(1)) = [];
trigDatinTime(trigDatinTime>trigOffDatinTime(end)) = [];

trigDatinTime(diff(trigDatinTime) < 90e3) = [];
trigOffDatinTime(diff(trigOffDatinTime) < 90e3) = [];

clf
hold on
plot(datin)
plot(diff(datin))
Lines(trigDatinTime);
Lines(trigOffDatinTime, [], 'b');
%% detect first stimuli trigger time (in datin)
cellDatin = data(ist:ind, 1);
LFPDatin = data(ist:ind, 3);
[~,FirstStimuliDatinTriggerTime] = max(LFPDatin);
FirstStimuliTriggerTime = ist + FirstStimuliDatinTriggerTime;% <<<<<< this

[~, closestDatinTrigTime] = min(abs(trigDatinTime-FirstStimuliDatinTriggerTime));
triggeringStartDatin = trigDatinTime(closestDatinTrigTime);

clf
hold on
plot(cellDatin)
plot(LFPDatin)
Lines(FirstStimuliDatinTriggerTime);
Lines(triggeringStartDatin, [], 'b');

StimulAfterStep = FirstStimuliDatinTriggerTime - triggeringStartDatin;





%% STEP-TRIGGER
%% - STT (step triggering times)

trigInterval = median(diff(trigDatinTime));% alternative way to detect trigger interval
stepInterval = median(trigOffDatinTime - trigDatinTime)% alternative way to detect step interval

stepInterval = 4000;
trigSearchWindow = 0.5e3;

trigInterval = 99988.555;
STT = ist+trigDatinTime(1):trigInterval:size(data,1)-trigInterval
trigs_num = numel(STT);
data_time = 1:size(data,1);

ist = 1e6;%size(data,1)-trigInterval*2
ind = 2e6;%size(data,1)

% refine position

ch = 2;
trigSearchWindow = 0.5e3;
for n = 1:trigs_num
    peak_strt =  STT(n) - trigSearchWindow;
    peak_end = STT(n) + trigSearchWindow;
    peak_part = diff(data(peak_strt : peak_end , ch));
    [~, peak_ind]  = max(peak_part);
    STT(n) = round(peak_strt + peak_ind-1);
end

% plot data and triggering times at the end

inst = size(data, 1) - stepInterval*200;

clf
hold on
plot(data_time(inst:end), data(inst:end,2))
Lines(STT(STT>inst));
%% save STT
subfolder = 'STT';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'STT', 'stepInterval', 'trigInterval', 'cftn')

%% - CDS (Cell-data-sweeps)

dataEndTime = (data_time(end)/60e3)/cftn;
afterTrigger =  stepInterval;%500*cftn;
beforeTriggerStart = 2*cftn;

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
%% compare cell data sweeps
mddlinx = round(size(CDS,2)/2);
clf
hold on
plot(CDS(:, 5))
plot(CDS(:, mddlinx))
plot(CDS(:, end))
%% save CDS, step-trigger period, times, graph
subfolder = 'CDS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'CDS', 'STT', 'stepInterval', 'trigInterval', 'cftn')

%% - RM (membrane resistanse)
afterTrigger = stepInterval;
beforeTriggerStart = 2*cftn;


CellStepVoltages = [];
CellStepCurrents = [];
celldata = [];
stepdata = [];
for n=1:trigs_num
    ch = 1;
    celldata(:, n) = data(STT(n) : STT(n) + afterTrigger, ch) - median(data(STT(n) - beforeTriggerStart: STT(n) , ch));
    %celldata(:, n) = medfilt1(celldata(:, n), 100);
    ch = 2;
    stepdata(:, n) = data(STT(n) : STT(n) + afterTrigger, ch) - median(data(STT(n) - beforeTriggerStart: STT(n) , ch));
CellStepVoltages(n) = median(celldata(:, n));
CellStepCurrents(n) = median(stepdata(:, n));
end

RM = ((1e-3*CellStepVoltages)./(1e-12*CellStepCurrents))*1e-6;% tranform into Ohm, and after to MOhm
RM = medfilt1(RM, 4);
RM_time = STT/cftn/60e3;

clf
hold off
plot(CellStepVoltages)
plot(CellStepCurrents)
plot(RM_time, RM)
ylabel('RM, Mohm')

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
xlim([0 RM_time(end)])
%% check RM median of cell potential and step current data
n = 657;
clf
subplot(121)
title('voltage cell response')
ylabel('mV')
hold on
plot(celldata(:,n))
plot([1 stepInterval], [CellStepVoltages(n) CellStepVoltages(n)], 'linewidth', 2)
subplot(122)
title('current step')
ylabel('pA')
hold on
plot(stepdata(:,n))
plot([1 stepInterval], [CellStepCurrents(n) CellStepCurrents(n)], 'linewidth', 2)
%% save RM, voltage, current, step-trigger period, times, graph
subfolder = 'RM';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'RM','RM_time','CellStepVoltages','CellStepCurrents','STT', 'stepInterval', 'trigInterval', 'cftn')
subfolder = [subfolder '_images'];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

%% - RT (tissue resistanse)
afterTrigger = stepInterval;
beforeTriggerStart = 2*cftn;


LFPStepVoltages = [];
LFPStepCurrents = [];
lfpCurrentdata = [];
stepdata = [];
for n=1:trigs_num
    ch = 3;% pA
    lfpCurrentdata(:, n) = data(STT(n) : STT(n) + afterTrigger, ch) - median(data(STT(n) - beforeTriggerStart: STT(n) , ch));
    %celldata(:, n) = medfilt1(celldata(:, n), 100);
    ch = 4;% mV
    fieldStepVoltageData(:, n) = data(STT(n) : STT(n) + afterTrigger, ch) - median(data(STT(n) - beforeTriggerStart: STT(n) , ch));
LFPStepCurrents(n) = median(lfpCurrentdata(:, n));
LFPStepVoltages(n) = median(fieldStepVoltageData(:, n));
end

RT = ((1e-3*LFPStepVoltages)./(1e-12*LFPStepCurrents))*1e-6;% MOhm
RT = medfilt1(RT, 4);
RT_time = STT/cftn/60e3;

clf
hold off
plot(LFPStepVoltages)
plot(LFPStepCurrents)
plot(RT_time,RT)
ylabel('RT, MOhm')

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = (hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
xlabel('Time, minutes')
xlim([0 RT_time(end)])
%% check RT median of LF potential and LF step current data
n = 870;
clf
subplot(121)
title('current (LFP) response')
ylabel('pA')
hold on
plot(lfpCurrentdata(:,n))
plot([1 stepInterval], [LFPStepCurrents(n) LFPStepCurrents(n)], 'linewidth', 2)
ylim([0 700])
subplot(122)
title('voltage step')
ylabel('mV')
hold on
plot(fieldStepVoltageData(:,n))
plot([1 stepInterval], [LFPStepVoltages(n) LFPStepVoltages(n)], 'linewidth', 2)
ylim([0 10])
%% save voltage, current and RT data, step-trigger period, times, graph
subfolder = 'RT';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'RT','RT_time','LFPStepVoltages','LFPStepCurrents','STT', 'stepInterval', 'trigInterval', 'cftn')
subfolder = [subfolder '_images'];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

%% - [NSS, FSS, FSA] Step-spike parameters
% NSS - number of spikes in sweep
% FSS - first spike slope
% FSA - first spike amplitude
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

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
xlabel('Time, minutes')
xlim([0 STT(end)/cftn/60e3])

legend('number of spikes', 'first spike slope', 'first spike amplitude','first spike volue','first spike half width' )
%% save  [NSS, FSS, FSA] and graph
subfolder = 'NSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'NSS','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'FSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSS','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'FSA';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSA','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'NSS, FSS, FSA images';
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])







%% STIMULI
%% - ST (stimuli times)
StimuliTriggerPeriod = trigInterval*4;
StimuliTriggerPeriod = 3.9995e+05;

ST = FirstStimuliTriggerTime:StimuliTriggerPeriod:size(data,1)-StimuliTriggerPeriod;

for n = 1:numel(ST)
    [~, closestTrigInx] = min(abs(ST(n) - STT))
    ST(n) = STT(closestTrigInx) + StimulAfterStep;
end

% plot data and triggering times at the end

inst = size(data, 1) - stepInterval*400;
clf
hold on
plot(data_time(inst:end), data(inst:end,3))
Lines(ST(ST>inst));
%% save ST
subfolder = 'ST';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'ST', 'StimuliTriggerPeriod', 'cftn')

%% - LSS (LFP stimuli sweeps)

Stimuli_num = numel(ST);% number of stimuls
beforeTrigger = 1*cftn;
afterTrigger =  trigInterval - StimulAfterStep;%500*cftn;
baselineStart = 3*cftn;
baselineEnd = 1*cftn;

ch = 3;
LSS_baseline = [];
LSS = [];
for n=1:Stimuli_num
LSS_baseline(n) = median(  data(ST(n) - baselineStart: ST(n) - baselineEnd , ch)  );
LSS(:, n) = data(ST(n)-beforeTrigger : ST(n) + afterTrigger, ch) - LSS_baseline(n);
end   

figure(1)
clf

imst = 1;
imnd = stepInterval/4;%cftn*70;
imagesc(LSS(1:imnd, :))
colormap(jet)
caxis([-1 1]*50)

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/cftn;
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60, 3), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
%% compare LFP stimuli sweeps
mddlinx = round(size(LSS,2)/2);
imnd = 100;

clf
hold on
plot(LSS(1:imnd, 1))
plot(LSS(1:imnd, mddlinx))
plot(LSS(1:imnd, end))
ylim([-100 300])
%%  save LSS, stimuli period, times
subfolder = 'LSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'LSS', 'Stimuli_num','beforeTrigger','afterTrigger','baselineStart','baselineEnd','LSS_baseline','imst','imnd','ST','StimuliTriggerPeriod', 'cftn')
subfolder = [subfolder '_images'];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

%% - AVSR (afferent value stimuli responce)
imst = 30;
imnd = 40;
AVSR = -median(LSS(imst:imnd, :));
AVSR(AVSR<0) = [];
AVSR_times = (1:numel(AVSR))/3;

figure(1)
clf, hold on
title({name 'Response to stimuli'}, 'Interpreter','none')
%title({'ID:', num2str(t1_list) 'Response to stimuli'}, 'Interpreter','none')
plot(AVSR_times, AVSR, 'ko', 'linewidth', 2)
xlabel('Time, min')
ylabel('LFP, pA')
xlim([0 AVSR_times(end)]);
ylims = ylim;

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60;
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end

%plot(Cor_ans_times, data_stimuli_baselines)
%% save AVSR, times and graph
subfolder = 'AVSR';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'AVSR','AVSR_times','Stimuli_num','imst','imnd','ST','StimuliTriggerPeriod', 'cftn')
subfolder = [subfolder '_images'];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

%% - CSS (cell stimuli sweeps)

Stimuli_num = numel(ST);% number of stimuls
beforeTrigger = 1*cftn;
afterTrigger =  trigInterval - StimulAfterStep;%500*cftn;
baselineStart = 3*cftn;
baselineEnd = 1*cftn;

ch = 1;
LSS_baseline = [];
CSS = [];
for n=1:Stimuli_num
LSS_baseline(:, n) = median(  data(ST(n) - beforeTriggerStart: ST(n) - baselineEnd , ch)  );
CSS(:, n) = data(ST(n)-beforeTrigger : ST(n) + afterTrigger, ch);% - data_stimuli_baselines(:, n);
end   

figure(1)
clf

imst = 1;
imnd = 5e3;%cftn*70;

imagesc(CSS(1:imnd, :))
colormap(jet)
caxis([-1 1]*50)

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/cftn;
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60, 3), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
%% compare cell stimuli sweeps
mddlinx = round(size(LSS,2)/2);
imnd = 5e3;

clf
hold on
plot(CSS(1:imnd, 1))
plot(CSS(1:imnd, mddlinx))
plot(CSS(1:imnd, end))
%ylim([-100 300])
%% save CSS, stimuli period, times, graph
subfolder = 'CSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'CSS','Stimuli_num','imst','imnd','ST','StimuliTriggerPeriod', 'cftn')
subfolder = [subfolder '_images'];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

%% - [S_NSS, S_FSS, S_FSA] - Stimuli-spike parameters
%     S_NSS - number of pikes after trigger 
%     S_FSS - first spike slope
%     S_FSA - first spike after trigger
%     S_FSHW - first spike half-width
beforeTrigger = 2*cftn;

[S_NSS, S_FSS, S_FSA, S_FSOP, S_FSHW, S_FSV] = spikeResponseAnalys(CSS(beforeTrigger:end, :), cftn);

%S_FSV(S_FSV == 0) = nan;

clf
hold on
plot(ST/cftn/60e3, S_NSS)
plot(ST/cftn/60e3, S_FSS)
plot(ST/cftn/60e3, S_FSA)
plot(ST/cftn/60e3, S_FSV)
plot(ST/cftn/60e3, S_FSHW)

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = (hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
xlabel('Time, minutes')
xlim([0 STT(end)/cftn/60e3])

legend('number of spikes', 'first spike slope', 'first spike amplitude','first spike volue','first spike half width' )
%% save  [S_NSS, S_FSS, S_FSA] and graph
subfolder = 'S_NSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'NSS','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'S_FSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSS','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'S_FSA';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'FSA','STT', 'stepInterval', 'trigInterval', 'cftn')

subfolder = 'S_NSS, S_FSS, S_FSA images';
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])


%% TESTING CDS, CSS

clt = (1:numel(CSS(beforeTrigger:beforeTrigger+3e3, 1)))/cftn
%%
clf
hold on
for n = 1:size(CSS, 2)


plot(clt, CSS(beforeTrigger:beforeTrigger+3e3, n))


end

ylim([-70 10])
%%
figure(2)
clf
hold on
for n = 1:size(CDS, 2)
plot(CDS(:,n))
end

ylim([-70 10])
%% new protocol loading

% load abf
clear all

Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');
t1 = 469;
filepath = Protocol.ABFFile{find(Protocol.ID == t1, 1)};

[data, si, hd]=abfload(filepath);
cftn=round(1e3/si);
