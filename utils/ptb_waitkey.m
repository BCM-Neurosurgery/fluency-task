function ptb_waitkey(ptb)
% ptb_waitkey  Block until the wait key (W) is pressed.
%
% Pressing Escape throws FluencyTask:killed so the main try-catch can
% send the appropriate Blackrock comment before closing.

while true
    [~, ~, kCode] = KbCheck(-1);
    if kCode(ptb.wait_key)
        KbReleaseWait(-1);
        return;
    end
    if kCode(ptb.esc_key)
        KbReleaseWait(-1);
        error('FluencyTask:killed', 'Task killed by experimenter (Escape).');
    end
    WaitSecs(0.005);
end

end
