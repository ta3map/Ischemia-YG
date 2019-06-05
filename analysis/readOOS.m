function [v_data, v_time] = readOOS(fname, imSize, dt)

% Function to parse Gainutdinov's OOS file (*.oos) 
% [v_data, v_time] = readOOS(fname, imSize, dt)
% v_data - X,Y,1,i
% v_time - time in seconds
% fname - file path 
% imSize - image size, for example 348x260 pixels
% dt - time differense between frames, for example 2.5 seconds

% size of file in bytes
s=dir(fname);
fileSize=s.bytes;

tSize = 8;% extra size at end of frame (something from LabView I guess)

fileStep = imSize(1)*imSize(2)*2+tSize;%

% number of frames(steps)
steps = fileSize/fileStep-1;

% opening OOS file
fileID = fopen(fname, 'r', 'b');  
% collecting data
v_data = [];
for index = 1:steps
fseek(fileID,4+index*fileStep,'bof'); %this should look for the first data point in the file
position = ftell(fileID); %this should report the current index 
data = fread(fileID, imSize, 'uint16', 0); % data frame
v_data(:,:,1,index) = data';
end
fclose(fileID)

% output format like readIOS function
v_data = uint16(v_data);
v_time(:,1) = (1:steps)*dt;
end