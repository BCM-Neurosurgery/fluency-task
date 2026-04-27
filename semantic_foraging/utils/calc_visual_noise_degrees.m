%
% compute the possible patch size in degrees that match the monitors specs
%

screenSize = [520, 330]; % mm
screenDistance = 910; % mm
screenResolution = [1920, 1200]; % pixels

% compute visual angles for this specific computer
% this is based on
% https://osdoc.cogsci.nl/3.3/visualangle/
h = screenSize(2) / 10;
d = screenDistance / 10;
r = screenResolution(2);
% compute the degree per pixel
degPerPx = rad2deg(atan2(.5 * h, d)) / (.5 * r);


for noisePatchDeg = 0.1:0.01:1
    % compute noise patch size based on visual angle and size of the screen
    noisePatchSizePx = [round(noisePatchDeg / degPerPx), round(noisePatchDeg / degPerPx)];
    % check that the degrees match the screen dimensions
    if all(floor(screenResolution ./ noisePatchSizePx) == screenResolution ./ noisePatchSizePx)
        disp(num2str(noisePatchDeg))
        
    end
end

