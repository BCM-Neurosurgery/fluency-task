function [edfFile] = eye_startRecording(opt, ptb, iRun, iBlock)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % opening a new file
    % edfFile should be no more than 8 characters long
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % run number _ block number
    edfFile = sprintf('r%d_b%d.edf', iRun, iBlock); %data dump for eyetracking data for a subject
    Eyelink('Openfile', edfFile);
    
    % Sending a 'TRIALID' message to mark the start of a trial in Data
    % Viewer.  This is different than the start of recording message
    % START that is logged when the trial recording begins. The viewer
    % will not parse any messages, events, or samples, that exist in
    % the data file prior to this message.
    Eyelink('Message', 'run %d block %d', iRun, iBlock);
    % This supplies the title at the bottom of the eyetracker display
    Eyelink('command', 'record_status_message "Block %d/%d"', iBlock, opt.nBlocks);
        
    [winWidth, winHeight] = WindowSize(ptb.window);
    
    Eyelink('Command', 'clear_screen %d', 0);
    % draw fixation on host PC
    Eyelink('command', 'draw_cross %d %d 15', winWidth/2,winHeight/2);
    
    % also start eye-tracking
    %recordingStartTime=GetSecs(); % we use this to get the queued data
    Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.05);
    
    eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
    assert(eye_used == opt.eyeUsed) 
    
    % mark zero-plot time in data file
    % Eyelink('Message', 'SYNCTIME');
    %stopkey=KbName('space'); %do we need a stopkey?
    
    % check if is recording
    err=Eyelink('CheckRecording');
    if(err~=0)
        err
        error('checkrecording problem')
    end
end 