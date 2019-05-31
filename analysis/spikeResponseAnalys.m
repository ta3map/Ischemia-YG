function [NSS, FSS, FSA, FSOP, FSHW, FSV] = spikeResponseAnalys(CDS, cftn)
global firstSpikeData firstSpikePeakPoint
% analysing CDS (cell data sweeps) spike parameters

% incoming data:
% cftn, data's time  conversion coefficient from points to milliseconds
% CDS

NSS = [];% number of spikes in sweep
FSS = [];% first spike slope
FSA = [];% first spike amplitude
FSV = [];% first spike volue
FSOP = [];% First Spike Onset Point
FSHW = [];% First Spike half width

i = 0;
for n = 1:size(CDS, 2)
 
stpRespSegment = CDS(:, n);% sweep with response
%% looking for SPIKES
SignalIn = smooth(stpRespSegment,6);% smoothing signal / сглаживаем сигнал против шума
MinPeakDistance = 100;
MinPeakProminence = 8;
[pks,locs] = findpeaks(SignalIn,'MinPeakProminence',MinPeakProminence, 'minpeakdistance',MinPeakDistance);% finding peaks with spike parameters / находим пики спайков
NumberOfSpikes = numel(pks);

plotting = 0;   
if plotting
clf, hold on
plot(stpRespSegment)
plot(SignalIn)
plot(locs,pks,'o')
end
%%
if NumberOfSpikes > 0
%% plot spikes by peak

SpikeData = [];

for s = 1:numel(locs)
    
    afterSpike = locs(s) + MinPeakDistance;
    afterSpike(afterSpike>size(stpRespSegment,1)) = size(stpRespSegment,1);
    beforeSpike = locs(s) - MinPeakDistance;
    beforeSpike(beforeSpike<1) = 1;
SpikeData(s).data = SignalIn(beforeSpike:afterSpike);
SpikeData(s).locs = locs(s) - beforeSpike;
end

i = i+1;
if i == 1
    WFSD.data = SpikeData(1).data';% very first spike data
    WFSD.locs = SpikeData(1).locs;% very first spike data
end

firstSpikeData = SpikeData(1).data';
firstSpikePeakPoint = SpikeData(1).locs;

plotting = 0;
if plotting
clf
hold on
%plot(firstSpikeData)
for s = 1:numel(locs)
    plot(SpikeData(s).data)
end
end
%% set peak onset by thresholding signal speed

firstSpikeDataTime = (1:numel(firstSpikeData))/cftn;
ThrFS = 10;% threshold for first spike signal speed in mV
DiffFirstSpike = cftn*smooth([0 diff(firstSpikeData)],6)';% signal speed mV/ms
FirstSpkOnsetPoint = find(DiffFirstSpike > ThrFS, 1);% first point that reach the threshold is onset

if not(isempty(FirstSpkOnsetPoint))
FirstSpikeAmpl = firstSpikeData(firstSpikePeakPoint) - firstSpikeData(FirstSpkOnsetPoint);% size of the signal from peak to the onset point
[FirstSpikeSlope, SlopeTime] = max(DiffFirstSpike);
FirstSpikeVolue = firstSpikeData(firstSpikePeakPoint);
HalfThreshold = firstSpikeData(FirstSpkOnsetPoint) + FirstSpikeAmpl/2;
halfPoint1 = find(firstSpikeData(FirstSpkOnsetPoint:firstSpikePeakPoint) >= HalfThreshold, 1) + FirstSpkOnsetPoint-1;
halfPoint2 = find(firstSpikeData(firstSpikePeakPoint:end) <= HalfThreshold, 1) + firstSpikePeakPoint-1;
FirstSpikeHalfWidth = halfPoint2 - halfPoint1;
else
    FirstSpikeAmpl = [];
    FirstSpikeHalfWidth = [];
end

if isempty(FirstSpikeAmpl)
FirstSpikeAmpl = nan;
FirstSpkOnsetPoint = nan;
FirstSpikeVolue = nan;
FirstSpikeSlope = nan;
NumberOfSpikes = nan;

end

if isempty(FirstSpikeHalfWidth)
FirstSpikeHalfWidth = nan;
end

plotting = 0;
if plotting
clf
hold on
plot(firstSpikeDataTime,DiffFirstSpike, '--')
plot(firstSpikeDataTime,firstSpikeData, 'k')
plot(FirstSpkOnsetPoint/cftn, firstSpikeData(FirstSpkOnsetPoint), '+', 'color',  'red', 'markersize', 10, 'linewidth', 2)
plot((MinPeakDistance+1)/cftn, firstSpikeData(MinPeakDistance+1), '+', 'color',  'red', 'markersize', 10, 'linewidth', 2)
plot(SlopeTime/cftn, DiffFirstSpike(SlopeTime), '+', 'color',  'red', 'markersize', 10, 'linewidth', 2)
text((MinPeakDistance+6)/cftn,DiffFirstSpike(MinPeakDistance+1),['Amplitude ' num2str(FirstSpikeAmpl, 3) ' mV'] )
text((SlopeTime+6)/cftn,DiffFirstSpike(SlopeTime),['Slope ' num2str(FirstSpikeSlope, 3) ' mV/ms'] )
xlim([0 MinPeakDistance*2/cftn])
legend('speed, mV/ms', 'cell spike signal, mV')
xlabel('Time, ms')
ylabel('Amplitude, mV')

end
else
    FirstSpikeSlope = nan;
    FirstSpikeAmpl = nan;
    FirstSpkOnsetPoint = nan;
    FirstSpikeVolue = nan;
    FirstSpikeHalfWidth = nan;
end

NSS(n) = NumberOfSpikes;
FSS(n) = FirstSpikeSlope;
FSA(n) = FirstSpikeAmpl;
FSV(n) = FirstSpikeVolue;
FSOP(n) = FirstSpkOnsetPoint;
FSHW(n) = FirstSpikeHalfWidth;
end
%%
plotting = 0;
if plotting
clf
hold on
plot(NSS)
plot(FSS)
plot(FSA)
legend('number of spikes', 'first spike slope', 'first spike amplitude')
end

end