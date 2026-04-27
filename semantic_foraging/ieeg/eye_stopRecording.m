%
% stop the recording of the eye tracker
%

function eye_stopRecording(edfFile, outFname, opt)

message = sprintf('ending recording of %s', edfFile);
Eyelink('Message', message);

%stopRecording Data
WaitSecs(0.05);
Eyelink('StopRecording');
Eyelink('CloseFile');

%transfer file to local machine
try
    fprintf('Receiving data file ''%s''\n', edfFile);
    statusA = Eyelink('ReceiveFile');
    if statusA  > 0
        fprintf('ReceiveFile status %d\n', statusA);
    end
    if 2==exist(edfFile, 'file')
        fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
    end
    
    %change filename and move to subject specific directory
    %savedFilename = [opt.subjDir stim.subid '_r' num2str(iRun) '_b' num2str(iBlock) '.edf'];
    statusB = movefile(edfFile, fullfile(opt.subjDir, 'eye', sprintf('%s_eye.edf', outFname)));
    
    if 0==statusB
        fprintf('problem removing the data file for %d,%d', blocknumber,trialnumber);
    end
    
catch rdf
    fprintf('Problem receiving data file ''%s''\n', edfFile );
    rdf;
    statusA = -1;
    statusB = -1;
    savedFilename = 'blah';
end

end
