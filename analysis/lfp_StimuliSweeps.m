% LOAD DATA
filepath = Protocol.ABFFile{find(Protocol.ID == t1, 1)};
% get header
[~, ~,hd]=abfload(filepath, 'start', 1, 'stop', 2);
% load ONLY LFP data (at channel 3)
[data, si, hd]=abfload(filepath,'channels', hd.recChNames(3));
cftn=round(1e3/si);
data_time = 1:size(data,1);

%% 1- LBL (baseline for LFP data)

LBLStep = 99972;
filtSize = 5;
LBL = smooth(medfilt1(data(1:LBLStep:end,1), filtSize), filtSize);
LBLTime = (0:numel(LBL)-1)*LBLStep;
LBL(1:10)= median(LBL(10:19));
LBL(end-20:end)= median(LBL(end-40:end-20));


figure(1)
clf
axis([],'position', [0.1 0.1 0.9 0.9])
hold on
title([num2str(t1) '_LFP_baseline_(LBL)_' name], 'Interpreter', 'none')

plot(LBLTime/cftn/60e3, data(1:LBLStep:end,1))
plot(LBLTime/cftn/60e3, LBL, 'color', 'r', 'linewidth', 3)
xlim([0 size(data,1)/60e3/cftn])
legend('downsampled LFP data', 'baseline - median and gauss filter')

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
ylabel('Amplitude, pA')

ax2 = axes('Position',[0.6 0.2 0.28 0.1]);
hold on
title('first seconds')
plot((1:1e6)/1e3/cftn, data(1:1e6, 1), 'color', 'g')
ylim(Ylim)
set(gca,'Color','none')
xlabel('Time, sec')
ylabel('Amplitude, pA')
%% save LBL, graph

subfolder = 'LBL';
makeIfnotExists([save_folder '\' subfolder '\'])
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'LBL', 'LBLTime', 'LBLStep', 'filtSize', 'cftn')
%save graph
subfolder = [subfolder '_images'];
makeIfnotExists([save_folder '\' subfolder '\'])
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])
disp([subfolder ' saved']);
%% 2- detect step start points inside small part (datin)
ist = 3.998e5;
ind = ist + 3e6;

LFPDatin = data(ist:ind,1);

DiffLFPDatin = diff(LFPDatin);

DiffTreshold = 1e3;
trigDatinTime = find(DiffLFPDatin<-DiffTreshold);
trigOffDatinTime = find(DiffLFPDatin>DiffTreshold);
maxTrigDistance = 4e5*0.9;% 90% of 20 seconds
trigDatinTime(diff(trigDatinTime) < maxTrigDistance) = [];
trigOffDatinTime(diff(trigOffDatinTime) < maxTrigDistance) = [];

clf
hold on
plot(LFPDatin)
plot(DiffLFPDatin)
%plot(MedianLFPDatin)
plot(DiffLFPDatin)
Lines(trigDatinTime);
Lines(trigOffDatinTime, [], 'b');
%% 3- ST (stimuli times)

ST = [];

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

LFPDatin = data(ist:ind,1);

DiffLFPDatin = diff(LFPDatin);

DiffTreshold = 1e3;
trigDatinTime = find(DiffLFPDatin<-DiffTreshold);
trigOffDatinTime = find(DiffLFPDatin>DiffTreshold);
maxTrigDistance = 4e5*0.9;% 90% of 20 seconds
trigDatinTime(diff(trigDatinTime) < maxTrigDistance) = [];
trigOffDatinTime(diff(trigOffDatinTime) < maxTrigDistance) = [];

ST = [ST; trigDatinTime+ist];
end

disp('ST compleded')

diffST = diff(ST);
StimuliTriggerPeriod = median(diffST);

clf
hold on
plot(diff(ST))
plot([1 size(ST,1)],[StimuliTriggerPeriod StimuliTriggerPeriod])


% ST - correction
ST(diffST<StimuliTriggerPeriod*(1-0.15)) = [];
%% Check ST at the end
inst = size(data, 1) - StimuliTriggerPeriod*20;
clf
hold on
plot(data_time(inst:end), data(inst:end,1))
Lines(ST(ST>inst));
%% -- save ST
subfolder = 'ST';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'ST','StimuliTriggerPeriod', 'cftn')
%% 4- LSS  (LFP stimuli sweeps)
MaxEdge = 400;
stepInterval = 2000;
dataEndTime = (data_time(end)/60e3)/cftn;
afterTrigger =  stepInterval;%500*cftn;
baselineStart = 20*cftn;
baselineEnd = 10*cftn;
Stimuli_num = numel(ST);

ch = 1;
LSS = [];
LSS_baseline = [];
for n=1:Stimuli_num
    LSS_baseline(:, n) =  median(data(ST(n) - baselineStart: ST(n) - baselineEnd, ch));
    LSS(:, n) = data(ST(n) : ST(n) + afterTrigger, ch) - LSS_baseline(:, n);
end 
%% stabilised LSS
AbsoluteLSS_threshold = 150;
medfiltValue = 10;
LSS = StabilizedLSS(LSS, AbsoluteLSS_threshold, medfiltValue);
%% plot LSS
figure(1)
clf
subplot(211)
imst = 1;
%imnd = stepInterval;%cftn*70;
imagesc(LSS(imst:end, :))
colormap(jet)
caxis([-1 1]*MaxEdge/1e1)

% tagging image
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = (hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/cftn);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60, 3), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end

% compare LFP sweeps

someinx = 1

%1
subplot(211)
hold on
plot(someinx,[1] , 'V', 'color', 'k', 'linewidth', 3);
%2
subplot(223)
hold on
plot(LSS(:, :))
plot(LSS(:, someinx), 'color', 'k', 'linewidth', 3)
xlim([0 100])
ylim([-1 1]*MaxEdge)
%3
subplot(224)
plot(data(ST(someinx)-stepInterval:ST(someinx)+stepInterval,1) - LSS_baseline(:, someinx))
Lines(stepInterval);
xlim([stepInterval stepInterval + 100])
ylim([-1 1]*MaxEdge)
%% delete suspicious sweep
%someinx = 137
LSS(:, someinx) = [];
ST(someinx) = [];
%% LSS-end mefdiltration

MedLSSend = medfilt1(LSS(end, :), 6);

clf
hold on
plot(ST,LSS(end, :), 'color', 'k', 'linewidth', 3)
plot(ST,MedLSSend, 'color', 'b', 'linewidth', 2)
%Lines(ST(LSS(end, :)<-50));

badST = abs(LSS(end, :) - MedLSSend) > 10;
Lines(ST(badST));

legend('LSS-end', 'median LSS-end', 'bad LSS-end')
% save medfiltDataTime, medfiltData
%% delete bad ST
ST(badST) = [];
LSS(:, badST == 1) = [];
%% -- save LSS
subfolder = 'LSS';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'LSS', 'Stimuli_num','afterTrigger','baselineStart','baselineEnd','LSS_baseline','ST','StimuliTriggerPeriod', 'cftn')
subfolder = [subfolder '_images'];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])
%% 5- AVSR (afferent value stimuli responce)
ch = 3;

someinx = 1;
imst = 18;
imnd = 30;

Pimst = 7;
Pimnd = 100;

figure(1)
clf 
% - AVSR (afferent value stimuli responce), AVP (afferent value power)
%imst = 8;
%imnd = 18;
AVSR = -median(LSS(imst:imnd, :));
%AVSR(AVSR<0) = [];
AVSR_times = ST/cftn/60e3;%(1:numel(AVSR))/3;
% second response if any
AVSR2 = max(LSS(Pimst:Pimnd, :));
AVSR2_times = ST/cftn/60e3;

%Pimst = 7;
%Pimnd = 70;
AVP = 1e-1*   (1/cftn) *      (1/(Pimnd-Pimst))*(sum(abs(LSS(Pimst:Pimnd, :)).^2));
AVP_times = ST/cftn/60e3;
%http://edu.alnam.ru/book_m_coi1.php?id=18

%subplot(121)
hold on
title({name 'Response to stimuli'}, 'Interpreter','none')
%title({'ID:', num2str(t1_list) 'Response to stimuli'}, 'Interpreter','none')
plot(AVSR2_times, AVSR2, 'ko', 'linewidth', 2)

xlabel('Time, min')
ylabel(['Amplitude, ' hd.recChUnits{ch}])
xlim([0 AVSR2_times(end)]);
ylims = ylim;
%% AVP

hold on
title('afferent value pover (AVP)')
plot(AVP_times, AVP, 'ro', 'linewidth', 2)
xlim([0 AVP_times(end)]);
ylims = ylim;

% tagging image
for i = 1:2
    subplot(1,2,i)
Ylim = ylim;
tag_y = Ylim(2) - 0.05*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60;
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], 'k','--', 'Linewidth', 0.8)

tagtext = [ hd.tags(1,active_tag).comment, {}, num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60), 'min'];

text(tag_x+1, tag_y,tagtext, 'color', 'k');
end
end



ax2 = axes('Position',[0.468 0.08 0.1 0.1]);

plot(LSS(:, :))

ylim([-1 1]*MaxEdge)
xlim([0 100])
Ylim = ylim;

text(Pimnd-8,Ylim(1),'AVP zone', 'color', 'r')
Lines(Pimst, [], 'r','--');
Lines(Pimnd, [], 'r','--');
text(imst+2,Ylim(2),'AVSR zone', 'color', 'b')
Lines(imst, [], 'b','--');
Lines(imnd, [], 'b','--');

xlabel(['tics'])
ylabel(['pA'])




%legend('afferent value stimuli responce, pA (AVSR)')
%% 6- save AVSR2

subfolder = 'AVSR2';
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'AVSR2','AVSR2_times','Stimuli_num','imst','imnd','ST','StimuliTriggerPeriod', 'cftn')

subfolder = ['AVSR2_images'];

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])
%% -- save AVP
subfolder = 'AVP';
makeIfnotExists([save_folder '\' subfolder '\'])
filename = [num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'AVP','AVP_times','Stimuli_num','Pimst','Pimnd','ST','StimuliTriggerPeriod', 'cftn')

subfolder = ['AVSR_AVP_images'];

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])