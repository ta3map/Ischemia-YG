%% Cell's data comparation

clear all
Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');


% save directory
save_folder = 'D:\Neurolab\Ischemia YG\Sweeps';
% load directory
load_folder = 'D:\Neurolab\Ischemia YG\Sweeps';

%Cell's data comparation
% load all CBL results
%%
t1list = Protocol.ID(Protocol.CDS_cell_stepData_Available==1)'; % ID's with available data
clear CBLs
i = 0;

 %CBLs(numel(t1list))=struct('OGDTime',[],'washTime',[]);
 i = 0
for t1 = t1list
   i = i+1;
   id = find(Protocol.ID == t1, 1);
   name = Protocol.name{id};
   %% load CBL (cell base line)
   subfolder = 'CBL';
   filename = [num2str(t1) '_' subfolder '_' name];
   CBLs(i) = load([ load_folder '\' subfolder '\' filename], 'CBL', 'CBLTime', 'CBLStep', 'filtSize', 'cftn')
end
% adding times
i = 0;
for t1 = t1list
    id = find(Protocol.ID == t1, 1);
    i = i+1
CBLs(i).OGDTime = Protocol.OGDTime(id);
CBLs(i).washTime = Protocol.washTime(id);
end

%% sort results by OGD durations
OGD_durations = [CBLs.washTime] - [CBLs.OGDTime];
% sort indexes:
[~,OgdSortidx] = sort(OGD_durations);
 t1listOGDSorted = t1list(OgdSortidx);
    
    clf
    hold on
    i = 0;
for t1 = t1listOGDSorted
    i = i+1;
    id = find(Protocol.ID == t1, 1);
    CBLTimeMnts = CBLs(i).CBLTime/60e3/CBLs(i).cftn;
    CBL = CBLs(i).CBL;
    OGDTime = Protocol.OGDTime(id);
    
    plot(CBLTimeMnts - OGDTime, CBL, 'color', [0.3 0.3 0.1])
end
