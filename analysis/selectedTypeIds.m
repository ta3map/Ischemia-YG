function [current_type_id_list] = selectedTypeIds(type_comment, t1,AdditionalProtocol, load_folder, subfolder)
current_type_id_list = [];
n = 0;
for i = 2:size(AdditionalProtocol,1)
    additional_id = AdditionalProtocol.ID(i);
    name = AdditionalProtocol.name{i};
    filepath_for_stimuli_response_results = [load_folder '\' subfolder '\' type_comment '\parameters\' num2str(t1) '_' num2str(additional_id) '_' type_comment '_response_parameters' '_' name '.mat'];
    file_exist = exist(filepath_for_stimuli_response_results);
    
if strcmp(AdditionalProtocol.type_comment{i} , type_comment) & file_exist
    n = n+1;
    current_type_id_list(n) = additional_id;
end
end
