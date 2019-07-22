%% Dashboard

clear all
cd('D:\Neurolab\ialdev\Ischemia YG\analysis')
protocol_path = 'D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx';
save_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
Protocol = readtable(protocol_path);

%% SELECT DATA BY TYPE
t1_list = [549 551 553]

% types
types = [];
types(1).type = 'control';
types(2).type = 'OGD';
types(3).type = 'after_OGD_L4';
types(4).type = 'after_OGD_hippocampus';
types(5).type = 'mouse';
types(6).type = 'mouse_after_OGD';

%% Count
for number_of_type = 1:size(types, 2)
    %ADD number of type
    types(number_of_type).number_of_type = number_of_type;
    current_type_collected_data = [];    
    type_comment = types(number_of_type).type;

    n = 0;
    for t1 = t1_list
        n = n+1;
        current_type_collected_data(n).t1 = t1;
        
        % open additional protocol
        row_number1 = find(Protocol.ID == t1, 1);
        name1 = Protocol.name{row_number1};
        additional_protocol_filepath = Protocol.type_comment{row_number1};
        AdditionalProtocol =  readtable(additional_protocol_filepath);
        
        subfolder = 'additional_cells_experiments';
        
        [current_type_id_list] = selectedTypeIds(type_comment, t1, AdditionalProtocol, load_folder, subfolder);
        % ADD additional ids
        current_type_collected_data(n).additional_ids = current_type_id_list;
        
        % load selected files
        i = 0;
        NumberOfSpikes = [];
        for additional_id = current_type_id_list
            i = i+1;
            [NSS] = spikeLoadAdditionalData(t1, additional_id, AdditionalProtocol, load_folder, subfolder, type_comment);
            NumberOfSpikes(i) = nanmean(NSS);
        end
        
        
        if strcmp('OGD', type_comment)
            [NSS] = spikeLoadOGDData(t1, Protocol, load_folder);
            NumberOfSpikes = nanmean(NSS);
            disp('OGD loaded ' )
        end    
    
    
        % ADD counted data
        current_type_collected_data(n).mean_NSS = nanmean(NumberOfSpikes);
        current_type_collected_data(n).NSS = NumberOfSpikes;
    
    

    end


    types(number_of_type).data = current_type_collected_data;
    types(number_of_type).all_NSS = [types(number_of_type).data.NSS];
    types(number_of_type).mean_NumberOfSpikes = nanmean(types(number_of_type).all_NSS);

end
disp('counted')

%% PLOT
meanColor = 'r';
all_pointsColor = 'k'

f = figure(1)
f.Position = [10  64  666  700];
clf, hold on

ax = gca;
xlim([0 size(types, 2)+1])

for number_of_type = 1:size(types, 2)
    number_Xpos = number_of_type+zeros(numel([types(number_of_type).all_NSS]), 1)';
    plot(number_Xpos, [types(number_of_type).all_NSS], 'o', 'color', all_pointsColor, 'linewidth', 1);% all points
    scatter(number_of_type, [types(number_of_type).mean_NumberOfSpikes], 80, 'filled', 'MarkerFaceColor', meanColor, 'linewidth', 1);% mean
    ax.XTickLabel(number_of_type+1) = {strrep(types(number_of_type).type, '_', ' ')};
end

ax.XTickLabel(1) = {' '};
ax.XTickLabel(end) = {' '};
ax.XTickLabelRotation = 70;

ylabel('N'), set(get(gca,'ylabel'),'rotation',0)
legend('NSS for one cell', 'mean NSS', 'Location','north','Orientation','horizontal')
title('Number of Spikes per step (NSS)')

%% SAVE PLOT

save_folder = 'D:\Neurolab\ialdev\Ischemia YG\Results';
subfolder = 'spikeDashboard';
filename = subfolder;

save([save_folder '\' subfolder '\' filename])

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);