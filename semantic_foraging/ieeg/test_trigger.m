% INIT PP
%create an instance of the io64 object
ioObj = io64;
%
% initialize the interface to the inpoutx64 system driver
status = io64(ioObj);
%
% if status = 0, you are now ready to write and read to a hardware port
% let's try sending the value=1 to the parallel printer's output port (LPT1)
address = hex2dec('3EFC');          %standard LPT1 output port address

data_out=255;                                 %sample data value


io64(ioObj,address,data_out);   %output command



% now, let's read that value back into MATLAB
data_in=io64(ioObj,address);
pause(2) % 100 ms 
io64(ioObj,address,0); 

%% close PP
clear all
clear mex
clear io64
