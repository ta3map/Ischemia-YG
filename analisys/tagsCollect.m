%% load abf
clear all

Protocol = readtable('D:\Neurolab\Ischemia YG\Protocol\IschemiaYGProtocol.xlsx');
i = 0;
for t1 = 446:470
    
filepath = Protocol.ABFFile{find(Protocol.ID == t1, 1)};

[~, ~,hd]=abfload(filepath, 'start', 1, 'stop', 2);

    
    
 tags = [];   
for active_tag = 1:size(hd.tags,2)
i = i+1;
Tags(i).id = t1;
Tags(i).values = (hd.tags(1,active_tag).timeSinceRecStart * hd.fADCSampleInterval/60);
Tags(i).names = hd.tags(1,active_tag).comment;
end
end
%% sort OGD and wash tags
i = 0;
SortedTags = [];

for n = 1:numel(Tags)
    Tags(n).OGD = isequal(Tags(n).names,'OGD                                                     ')
    Tags(n).wash = isequal(Tags(n).names,'wash                                                    ')
end

for t1 = 446:470
    i = i+1;
SortedTags(i).ID = t1;

for n = 1:numel(Tags)
    if Tags(n).id == t1
        
    if Tags(n).wash
        SortedTags(i).wash = Tags(n).values;
    end
    
    if Tags(n).OGD
        SortedTags(i).OGD = Tags(n).values;
    end    
    end
end

end