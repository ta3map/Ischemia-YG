%% Dashboard

clear all
cd('D:\Neurolab\ialdev\Ischemia YG\analysis')
protocol_path = 'D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx';
save_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
Protocol = readtable(protocol_path);

%% SELECT DATA BY TYPE
t1_list = [549 551 552 554]

% types
types = [];
types(1).type = 'control';
types(2).type = 'OGD';
types(3).type = 'after_OGD_L4';
types(4).type = 'after_OGD_hippocampus';

%% Count

groups(1).Min_age = 1;
groups(1).Max_age = 10;

groups(2).Min_age = 10;
groups(2).Max_age = 20;

group = 2;
% sort by age
Min_age = groups(group).Min_age;
Max_age = groups(group).Max_age;
[t1_list_sorted_by_age, meanAge] = spikeSortByAge(Min_age, Max_age, t1_list, Protocol);

[types] = spikeCountStatistics(types, t1_list_sorted_by_age, Protocol, load_folder)

%% PLOT
meanColor = 'r';
all_pointsColor = 'k'

f = figure(1)
f.Position = [10  64  666  700];
clf, hold on

ax = gca;
xlim([0 size(types, 2)+1])
ax.XTick = 1:size(types, 2);
for number_of_type = 1:size(types, 2)
    number_Xpos = number_of_type+zeros(numel([types(number_of_type).all_NSS]), 1)';
    plot(number_Xpos, [types(number_of_type).all_NSS], 'o', 'color', all_pointsColor, 'linewidth', 1);% all points
    scatter(number_of_type, [types(number_of_type).mean_NumberOfSpikes], 80, 'filled', 'MarkerFaceColor', meanColor, 'linewidth', 1);% mean
    ax.XTickLabel(number_of_type) = {strrep(types(number_of_type).type, '_', ' ')};
end

%ax.XTickLabel(1) = {' '};
%ax.XTickLabel(end) = {' '};
ax.XTickLabelRotation = 70;

ylabel('N'), set(get(gca,'ylabel'),'rotation',0)
legend('NSS for one cell', 'mean NSS', 'Location','north','Orientation','horizontal')
title(['Age P' num2str(meanAge, 2) '; Number of Spikes per step (NSS)'])
%% PLOT #2
f = figure(1)
f.Position = [10  64  666  700];
clf, hold on
subs = size(types, 2);


for number_of_type = 1:subs
subplot(subs,1,number_of_type)
hisdata = (types(number_of_type).all_NSS);
h = histogram(hisdata)
h.NumBins = numel(hisdata);
bar(sort(hisdata))
%xlim([0 max(hisdata)])
title(types(number_of_type).type, 'interpreter', 'none', 'FontWeight','bold', 'HorizontalAlignment', 'center')
ylabel('NSS','FontSize',12,'FontWeight','bold','Color','k'), set(get(gca,'ylabel'),'rotation',90)
end
xlabel('','FontSize',12,'FontWeight','bold','Color','k')


subplot(subs,1,1)
title({['Age P' num2str(meanAge, 2) '; Average Number of Spikes per step (NSS)']; types(1).type}, 'HorizontalAlignment', 'center')
%text( , )
%% SAVE PLOT

save_folder = 'D:\Neurolab\ialdev\Ischemia YG\Results';
subfolder = 'spikeDashboard_P17_P5_comparison';
filename = ['Age P' num2str(meanAge, 2) ' ' subfolder];

save([save_folder '\' subfolder '\' filename '.mat'])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);


