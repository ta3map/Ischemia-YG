% NLC - number of lost cells
clear all
% load comparation results

load_folder = 'D:\Neurolab\Ischemia YG\Results';
   subfolder = 'CDS_NS_comparation';
   filename = [subfolder '.mat'];
   filepath = [ load_folder '\' subfolder '\' filename];
   NSS_comp = load(filepath)
   
   subfolder = 'FSS_comp';
   filename = [subfolder '.mat'];
   filepath = [ load_folder '\' subfolder '\' filename];
   FSS_comp = load(filepath)
      
   subfolder = 'FSA_comp';
   filename = [subfolder '.mat'];
   filepath = [ load_folder '\' subfolder '\' filename];
   FSA_comp = load(filepath)
   
LostNSS =  sum(NSS_comp.RestoreWashNSS == 0 | isnan(NSS_comp.RestoreWashNSS))
LostFSS =  sum(FSS_comp.RestoreWashFSS == 0 | isnan(FSS_comp.RestoreWashFSS))
LostFSA =  sum(FSA_comp.RestoreWashFSA == 0 | isnan(FSA_comp.RestoreWashFSA))