%% Cell's data comparation

clear all
Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');


% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Sweeps';


%Cell's data comparation
% load all SD results
%%
t1list = Protocol.ID(Protocol.SD==1)'; % ID's with available data
clear SDs
i = 0;


 i = 0
for t1 = t1list
   i = i+1;
   id = find(Protocol.ID == t1, 1);
   name = Protocol.name{id};
   %% load CBL (cell base line)
   % load directory
   load_folder = 'D:\Neurolab\Ischemia YG\Traces';
   subfolder = 'SD';
   filename = [num2str(t1) '_' subfolder '_' name];
   SDs(i) = load([ load_folder '\' subfolder '\' filename])
end
% adding parameters from protocol
i = 0;
for t1 = t1list
    id = find(Protocol.ID == t1, 1);
    i = i+1
SDs(i).OGDTime = Protocol.OGDTime(id);
SDs(i).washTime = Protocol.washTime(id);
SDs(i).age = Protocol.age(id);
SDs(i).id = t1;
end

%% sort results by OGD durations
% add OGD duration
for i = 1:size(SDs, 2)
SDs(i).OGD_dur = SDs(i).washTime - SDs(i).OGDTime;
end
% sort by that new field
SDsorted = SortArrayofStruct( SDs, 'OGD_dur' );
SDsorted = empty2nanStruct(SDsorted);

%

for i = 1:size(SDs, 2)
SDsorted(i).SDDsAOGD = SDs(i).SDT - SDs(i).OGDTime;% SD delays after OGD start
end



clf, hold on
plot([SDsorted.OGD_dur], [SDsorted.SDA])
plot([SDsorted.OGD_dur], [SDsorted.SDDsAOGD])
plot([SDsorted.OGD_dur], [SDsorted.age])

plot([SDsorted.OGD_dur], [SDsorted.SDL], '-o')
plot([SDsorted.OGD_dur], [SDsorted.SDHW], '-o')


legend('ampl', 'SD delays after OGD start', 'age', 'SD length')

%% save SD comparation

save_folder = 'D:\Neurolab\Ischemia YG\Results';
subfolder = 'SD_comparation';
filename = subfolder;%[num2str(t1) '_' subfolder '_' name];
save([save_folder '\' subfolder '\' filename], 'SDs', 'SDsorted')

saveas(figure(1), [save_folder '\' subfolder '\' filename '.jpg'])

disp([subfolder ' saved']);