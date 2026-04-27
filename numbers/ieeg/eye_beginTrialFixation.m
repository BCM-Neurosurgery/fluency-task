%
% checks whether the eye position is in the fixation window to allow trial
% to start
%

function eye_beginTrialFixation(eye, ptb, opt, texture)
%% communicate with the eye tracker and set some parameters
% get the size of the window screen
[winWidth, winHeight] = WindowSize(ptb.window);

% define fixation window. /2 here is because the fixation window size will
% be centered
fixationWindow = [-ptb.fixWinSizePx(1) -ptb.fixWinSizePx(2) ptb.fixWinSizePx(1) ptb.fixWinSizePx(2)] / 2;
fixationWindow = fix(CenterRect(fixationWindow, ptb.window_rect));

% now set up eyetracker
if Eyelink('IsConnected')~=1 && ~eye.dummymode
    cleanup;
    return;
end


Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, winWidth-1, winHeight-1);
Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, winWidth-1, winHeight-1);

[v,vs] = Eyelink('GetTrackerVersion');
vsn = regexp(vs,'\d','match');

if v ==3 && str2double(vsn{1}) == 4 % if EL 1000 and tracker version 4.xx    
    % remote mode possible add HTARGET ( head target)
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
    % set link data (used for gaze cursor)
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT,HTARGET');
else
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
    % set link data (used for gaze cursor)
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
end


% if ~eye.dummymode
%     % Hide the mouse cursor and setup the eye calibration window
%     Screen('HideCursorHelper', ptb.window);
% end

% STEP 7.1
% Sending a 'TRIALID' message to mark the start of a trial in Data
% Viewer.  This is different than the start of recording message
% START that is logged when the trial recording begins. The viewer
% will not parse any messages, events, or samples, that exist in
% the data file prior to this message.
Eyelink('Message', 'TRIAL starts');
% This supplies the title at the bottom of the eyetracker display
Eyelink('Command', 'set_idle_mode');
% clear tracker display and draw box at center
Eyelink('Command', 'clear_screen %d', 0);
% draw fixation and fixation window shapes on host PC
Eyelink('command', 'draw_cross %d %d 15', winWidth/2,winHeight/2);
Eyelink('command', 'draw_box %d %d %d %d 15', ...
    fixationWindow(1), fixationWindow(2), fixationWindow(3), fixationWindow(4));

Eyelink('Command', 'set_idle_mode');
WaitSecs(0.05);
Eyelink('StartRecording');

% now check that this is the eye we selected
eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
% returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
if eye_used ~= opt.eyeUsed
    Eyelink('StopRecording');
    assert(eye_used == opt.eyeUsed, 'recording from a different eye than specified')
end

if any(opt.eyeUsed == [0 1])
    % +1 as we're accessing MATLAB array
    eye_used=eye_used+1;
end

%% start checking the eye position
% if the subject doesnot fixate, the trial never starts

% draw noise pattern, only if passed on to the function
% ie. only during the main task
if ~all(size(texture)==0)
    Screen('DrawTexture', ptb.window, texture);
end
% draw fixation cross
%DrawFormattedText(ptb.window, 'x', 'center', 'center', opt.colors.red);
Screen('FillOval', ptb.window, opt.colors.red, ...
    [ptb.x_center-ptb.fixDotSizePx/2 ptb.y_center-ptb.fixDotSizePx/2 ...
     ptb.x_center+ptb.fixDotSizePx/2 ptb.y_center+ptb.fixDotSizePx/2], [])

        % photodiode set to black
ptb_drawDiode(ptb, false, [0,0,0]);
Screen('Flip', ptb.window); %re-flip to show what you have drawn

% record a few samples before we actually start displaying
% otherwise you may lose a few msec of data

% so that mx and my are defined beforehand
mx = 99999;
my = 99999;
WaitSecs(0.05);
firstFixation = false;
startCheck = GetSecs(); 
while true 
    
    if eye.dummymode==0
        error=Eyelink('CheckRecording');
        if(error~=0)
            break;
        end
        
        % if a new sample is recorded
        if Eyelink( 'NewFloatSampleAvailable') > 0
            
            % get the sample in the form of an event structure
            evt = Eyelink( 'NewestFloatSample');
            
            % if we do, get current gaze position from sample
            x = evt.gx(eye_used); 
            y = evt.gy(eye_used);
            
            % do we have valid data and is the pupil visible?
            if x~=eye.el.MISSING_DATA && y~=eye.el.MISSING_DATA %&& evt.pa(eye_used+1)>0 % this is because we are trying out with a mouse
                mx=x;
                my=y;
            end
        end
        
    else
        % Query current mouse cursor position (our "pseudo-eyetracker") -
        % (mx,my) is our gaze position.
        %[mx, my]=GetMouse(window); %#ok<*NASGU>
    end
    
    infix = 0;
    % check position of the eye
    if infixationWindow(mx,my)
        if firstFixation == false
            % ensure that the subject if fixating for a given length 
            % of time, reset if they move out of the fixation window
            startFixation = GetSecs(); 
            firstFixation = true;
        end
        Eyelink('Message', 'Fixation Start');
        Eyelink('command', 'record_status_message "Fixation start"');
        Eyelink('command', 'record_status_message "X/Y %d/%d"', fix(mx),fix(my));
        %Beeper(eye.el.calibration_success_beep(1),eye.el.calibration_success_beep(2),eye.el.calibration_success_beep(3));
        infix = 1;
    else
        infix=0;
        firstFixation = false;
    end

    
    if  infix==1 && GetSecs()-startFixation > opt.fixationTime
        % if the participant has looked inside the fixation window for the
        % expected duration
        WaitSecs(0.05);
        Eyelink('StopRecording');
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.05);
        disp('proper fixation');
        Eyelink('Command', 'clear_screen %d', 0);
        return; %% return to main experiment
   
    elseif GetSecs()-startCheck > opt.maxFixationTime
        % if the participant has been trying to start the trial for more
        % than 15 s, it is likely that there is some problem with the eye
        % tracker. here we can start the trial manually 
        sprintf('press %s to force trial start', opt.waitKey)
        [keyIsDown,secs,keyCode] = KbCheck; %#ok<*ASGLU>
        % if stopkey was pressed, stop display
        if keyCode(opt.waitKey)
            sprintf('Stopkey pressed, starting trial manually\n');
            Eyelink('Message', 'Key pressed, forcing trial start');
            return;
        end
    
    end
    
end

    function fix = infixationWindow(mx,my)
        % determine if gx and gy are within fixation window
        fix = mx > fixationWindow(1) &&  mx <  fixationWindow(3) && ...
            my > fixationWindow(2) && my < fixationWindow(4) ;
    end

end