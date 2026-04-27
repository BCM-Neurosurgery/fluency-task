function texture = make_noise_texture(ptb, ~)
% make_noise_texture  Generate a fresh random visual-noise PTB texture.
%
% Tiles the screen with square patches of uniform random grayscale, each
% patch cfg.noise_patch_deg visual degrees wide (same method as Sahan 2022).
% Mean luminance matches the background (128).

W  = ptb.screen_resolution(1);
H  = ptb.screen_resolution(2);
sz = ptb.patchSizePx;

nX = ceil(W / sz);
nY = ceil(H / sz);

% Each tile gets a random value 0-255; kron expands to pixel resolution
grid = randi(256, nY, nX) - 1;          % 0-255 values
img  = kron(grid, ones(sz, sz));         % tile to pixel scale
img  = uint8(img(1:H, 1:W));            % crop to exact screen dimensions

texture = Screen('MakeTexture', ptb.window, img);

end
