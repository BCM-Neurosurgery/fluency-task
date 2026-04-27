%
% wait for the key to be pressed
%

function ptb_waitkey(opt)

disp(['\nWAITING FOR USER BUTTON PRESS (' KbName(opt.waitKey) ') ']);
wait_key = true;

while wait_key
    
    [~, ~,keyCode] = KbCheck;

    % if stopkey was pressed, stop 
    if keyCode(opt.waitKey)
        wait_key=false;
    end
end

end