function [NSS] = spikeLoadAdditionalData(t1, additional_id, AdditionalProtocol, load_folder, subfolder, type_comment)
% load selected file
            
            row_number = find(AdditionalProtocol.ID == additional_id, 1);
            name = AdditionalProtocol.name{row_number};
            
            load([load_folder '\' subfolder '\' type_comment '\parameters\' num2str(t1) '_' num2str(additional_id) '_' type_comment '_response_parameters' '_' name '.mat'], 'NSS');
            disp(['loaded ' name])
            
end