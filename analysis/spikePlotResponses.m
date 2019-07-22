function spikePlotResponses(NSS, FSS, FSA, FSOP, FSHW, FSV, operated_current, t1, name, cftn, hd)
f = figure(1);
f.Position = [10  64  666  700];

clf
hold on
subplot(411), bar(operated_current, NSS), title([[num2str(t1) '_' name],{},'number of spikes'], 'interpreter', 'none'), ylabel('n')
subplot(412), bar(operated_current, FSS), title('first spike''s slope'), ylabel('slope, mV/ms')
subplot(413), bar(operated_current, FSV), title('first spike''s volue'), ylabel('mV')
subplot(414), bar(operated_current, FSHW/cftn), title('first spike''s half-width'), ylabel('ms')
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
%xlim([0 operated_current(end)/cftn/60e3])


end

xlabel('Current, pA')

end