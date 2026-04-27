
function trigger_ieeg_send(trigger_value, time) 
% send trigger to the iEEG through the parallel port

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: the parallel port sends triggers coded in binary, however as of 
% 6/10/21 we can connect only one channel to the iEEG, thus is not possible
% to send all values. a temporary solution is to send only 1s and then
% retrieve the conditions afterwards. this hack is done in this function to
% not change too much in the main code
trigger_value = 255;
% here is 255 so that all channels are active and thus we can connect any
% channel to the ieeg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize parallel port

% create an instance of the io64 object
% this function is found in 'C:\Program Files\MATLAB\R2020a\toolbox\UNITN-toolbox'
ioObj = io64;

% initialize the interface to the inpoutx64 system driver
status = io64(ioObj);
% if status = 0, you are now ready to write and read to a hardware port
assert(status == 0)
% define the address of the parallel port
address = hex2dec('3EFC');          %standard LPT1 output port address

%% send the specified trigger value
io64(ioObj, address, trigger_value);   
% wait the specified time
WaitSecs(time); 

%% now, let's read that value back into MATLAB to check it matches the sent one
data_in=io64(ioObj,address);
assert(trigger_value==data_in)
%sprintf(['sent trigger value ' num2str(data_in)])

% set the trigger channels back to 0
io64(ioObj, address, 0); 


end