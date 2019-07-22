function [NSS] = spikeLoadOGDData(t1, Protocol, load_folder)
    subfolder = 'NSS';
    name = Protocol.name{find(Protocol.ID == t1, 1)};
    filename = [num2str(t1) '_' subfolder '_' name '.mat'];
    filepath = [load_folder '\' subfolder '\' filename];
    if exist(filepath)
        load(filepath, 'NSS','STT', 'stepInterval', 'trigInterval', 'cftn')
    else
        NSS = [];
    end
end