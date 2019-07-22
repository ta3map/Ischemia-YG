function [types] = spikeCountStatistics(types, t1_list, Protocol, load_folder)


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