
clear all
Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');

t1 = 463

id = find(Protocol.ID == t1, 1);
name = Protocol.name{id};
%% load

% load directory
load_folder = 'D:\Neurolab\Ischemia YG\Sweeps';

% load CDS
subfolder = 'CDS';
filename = [num2str(t1) '_' subfolder '_' name];
load([load_folder '\' subfolder '\' filename]);

% load header
filepath = Protocol.ABFFile{find(Protocol.ID == t1, 1)};
[~, ~,hd]=abfload(filepath, 'start', 1, 'stop', 2);

% SD time
SDT = Protocol.SDTime(id);
%% count spike parameters
[NSS, FSS, FSA, FSOP, FSHW, FSV] = spikeResponseAnalys(CDS, cftn);
%% plot
figure(1)
clf
hold on
subplot(411), plot(STT/cftn/60e3, NSS, 'color', 'k'), title([[num2str(t1) '_' name],{},'number of spikes'], 'interpreter', 'none'), ylabel('n')
subplot(412), plot(STT/cftn/60e3, FSS, 'color', 'k'), title('first spike''s slope'), ylabel('slope, mV/ms')
subplot(413), plot(STT/cftn/60e3, FSA, 'color', 'k'), title('first spike''s amplitude'), ylabel('mV')
subplot(414), plot(STT/cftn/60e3, FSHW/cftn, 'color', 'k'), title('first spike''s half-width'), ylabel('ms')
%plot(STT/cftn/60e3, FSV)


% tagging image
for i = 1:4
    subplot(4,1,i)
Ylim = ylim;
tag_y = Ylim(2) - 0.2*(Ylim(2) - Ylim(1));
for active_tag = 1:size(hd.tags,2)
    tag_x = (hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60);
    %tag_y = tag_y + 3*abs(min(lfp)/10);

Lines(tag_x, [], [0.5 0.5 0.8] ,'--', 'Linewidth', 0.8);
tagtimetext = num2str(hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60,3), 'min';
tagtext = [ hd.tags(1,active_tag).comment, {}];

if i ==1
text(tag_x+1, tag_y,tagtext, 'color', 'k');
end

end
xlim([0 STT(end)/cftn/60e3])

% SD tag
Lines(SDT, [], 'r' ,'--', 'Linewidth', 0.8);
tagtext = ['SD'];
if i ==1
text(SDT, tag_y-2,tagtext, 'color', 'k');
end

end



xlabel('Time, minutes')
%legend('number of spikes', 'first spike slope', 'first spike
%amplitude','first spike volue','first spike half width' )
%% save plot


% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Results';

subfolder = 'Parameters_SpikesFromStep_Image';
filename = [num2str(t1) '_' subfolder '_' name];
saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);