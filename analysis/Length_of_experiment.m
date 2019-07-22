clear all

cd('D:\Neurolab\ialdev\Ischemia\analysis')
protocol_path = 'D:\Neurolab\ialdev\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx';
save_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
load_folder = 'D:\Neurolab\Data\Ischemia YG\Traces';
Protocol = readtable(protocol_path);

t1_list = [450 451 452 453 454 455 468 469 470 471]

i = 0;
for t1 = t1_list
i = i+1;

id = find(Protocol.ID == t1, 1);
name = Protocol.name{id};

%%
filepath = Protocol.ABFFile{id};
% reading header
[~, ~, hd]=abfload(filepath, 'stop',1);

cftn=round(1e3/hd.si);
experiment_length = (hd.recTime(2) - hd.recTime(1))/60;

Length(i) = experiment_length;
end

table(t1_list', Length')


%%

t1_list = [477 478 479 480 481 482 483]

i = 0;
Length = [];
imSize = [348 260];
dt = 2.5;

for t1 = t1_list
    
i = i+1;

id = find(Protocol.ID == t1, 1);
name = Protocol.name{id};
v_path = Protocol.IOSFile{id};
% size of file in bytes
s=dir(v_path);
fileSize=s.bytes;

tSize = 8;% extra size at end of frame (something from LabView I guess)


fileStep = imSize(1)*imSize(2)*2+tSize;%

% number of frames(steps)
steps = fileSize/fileStep-1;

Length(i) = (steps*dt)/60;
end

table(t1_list', Length')