%% ECE447 Lab 2, Activity 2: listen to NOAA Weather Radio, then measure ppm
%
% Your dongle's tuner is steered by a cheap crystal oscillator, so when you
% ask it for a given centre frequency you actually get something slightly
% different. This script measures that error against a transmitter whose
% frequency really is where it claims to be -- NOAA Weather Radio -- and
% converts the error into parts per million (ppm).
%
% The script does three things, in order:
%   1) captures a few seconds of the weather station,
%   2) FM-demodulates it and PLAYS IT so you can hear you are on the station,
%   3) measures how far the carrier sits from 0 Hz and reports that in ppm.
%
% The measurement itself is just the double-sided spectrum from Activity 1:
% whatever the carrier sits away from 0 Hz IS your frequency error.
%
% HOW TO USE
%   1) Let the dongle warm up. The E4000 tuner drifts a lot for the first
%      15-20 minutes after you plug it in. Measure cold and you will measure
%      the wrong number.
%   2) Run with ppm_applied = 0 and note the ppm the script prints.
%   3) Put that number into ppm_applied and run again. The carrier should
%      move to (nearly) 0 Hz. If it moved the WRONG way, flip the sign.
%
% NOAA Weather Radio channels (nationwide, always on):
%   162.400  162.425  162.450  162.475  162.500  162.525  162.550  MHz
% Around Colorado Springs, try 162.475 first, then 162.550.

%% PARAMETERS
f_nominal   = 162.475e6;   % NOAA channel you are tuned to, in Hz
ppm_applied = 0;           % 0 for the first run; your measured ppm for the second

rtlsdr_id   = '0';
gain        = 40;          % tuner gain (dB); lower it if the spectrum looks clipped
play_secs   = 5;           % seconds of audio to capture and play back

% The RTL2832U only supports sample rates of 225-300 kHz or 0.9-3.2 MHz, so we
% cannot ask the hardware for a narrow rate directly. Instead we take the
% lowest convenient hardware rate and decimate in software. 240 kHz / 5 gives
% a 48 kHz baseband: a +/-24 kHz view, which is a good match for a ~16 kHz wide
% narrowband FM signal, and a standard audio rate for playback.
fs_rtl      = 240e3;       % hardware sample rate (Hz)
decim       = 5;           % software decimation factor
frmlen      = 2^15;        % samples per frame from the radio

Nfft        = 8192;        % FFT length for the spectrum (5.9 Hz bins at 48 kHz)
search_khz  = 20;          % only look this far either side of centre for the carrier
audio_bw    = 5e3;         % voice bandwidth to keep, in Hz

fs_bb = fs_rtl / decim;    % baseband / audio rate after decimation

%% RECEIVER
rx = comm.SDRRTLReceiver(...
    rtlsdr_id,...
    'CenterFrequency',    f_nominal,...
    'EnableTunerAGC',     false,...
    'TunerGain',          gain,...
    'SampleRate',         fs_rtl,...
    'SamplesPerFrame',    frmlen,...
    'OutputDataType',     'single',...
    'FrequencyCorrection', ppm_applied);

if isempty(sdrinfo(rx.RadioAddress))
    release(rx);
    error('No RTL-SDR found. Check the connection with sdrinfo.');
end

%% CAPTURE
nframes = ceil(play_secs * fs_rtl / frmlen);
fprintf('Capturing %.1f s at %.4f MHz ...\n', play_secs, f_nominal/1e6);

for k = 1:10, rx(); end                       % discard start-up frames

x = complex(zeros(nframes*frmlen, 1));
for k = 1:nframes
    x((k-1)*frmlen + (1:frmlen)) = double(rx());
end
release(rx);

%% DECIMATE TO BASEBAND
% Low-pass to the new Nyquist, then keep every decim-th sample.
h  = fir1(200, 1/decim);
xf = filter(h, 1, x);
xb = xf(1:decim:end);                          % complex baseband at fs_bb

%% FM DEMODULATE AND PLAY
% A discriminator: the angle between one sample and the previous one is
% proportional to the instantaneous frequency (the same relationship you
% will use again in Lab 4).
d     = xb(2:end) .* conj(xb(1:end-1));
audio = angle(d);

audio = audio - mean(audio);                   % strip the DC term (the offset itself)
ha    = fir1(200, audio_bw/(fs_bb/2));         % keep the voice band only
audio = filter(ha, 1, audio);

pk = max(abs(audio));
if pk > 0, audio = 0.9 * audio / pk; end       % normalise so it is audible, not clipped

fprintf('Playing %.1f s of audio -- you should hear the weather broadcast.\n', ...
        numel(audio)/fs_bb);
player = audioplayer(audio, fs_bb);
playblocking(player);                          % waits until playback finishes

%% AVERAGE THE SPECTRUM
nseg = floor(numel(xb)/Nfft);
w    = hann(Nfft);
Pavg = zeros(Nfft,1);
for k = 1:nseg
    seg  = xb((k-1)*Nfft + (1:Nfft));
    Pavg = Pavg + abs(fftshift(fft(seg .* w, Nfft))).^2;
end
Pavg = Pavg / max(nseg,1);

f = ((-Nfft/2):(Nfft/2)-1).' * (fs_bb/Nfft);   % double-sided frequency axis, Hz

%% FIND THE CARRIER AND CONVERT TO PPM
band    = abs(f) <= search_khz*1e3;
idx     = find(band);
[~, p]  = max(Pavg(idx));
f_err   = f(idx(p));                           % carrier offset from 0 Hz, in Hz

ppm_measured = (f_err / f_nominal) * 1e6;
ppm_total    = ppm_applied + ppm_measured;     % what to use from now on

%% REPORT
fprintf('\n--- RTL-SDR frequency calibration -----------------------------\n');
fprintf('  tuned to            : %.4f MHz\n', f_nominal/1e6);
fprintf('  hardware rate       : %.0f kHz, decimated by %d -> %.0f kHz\n', ...
        fs_rtl/1e3, decim, fs_bb/1e3);
fprintf('  correction applied  : %+.2f ppm\n', ppm_applied);
fprintf('  carrier landed at   : %+.1f Hz from centre\n', f_err);
fprintf('  residual error      : %+.2f ppm\n', ppm_measured);
fprintf('  USE THIS VALUE      : %+.2f ppm  <-- your dongle''s correction\n', ppm_total);
fprintf('---------------------------------------------------------------\n\n');

%% PLOT
figure;
plot(f/1e3, 10*log10(Pavg + eps), 'b-'); hold on;
xline(f_err/1e3, 'r--', 'LineWidth', 2);
xline(0, 'k:', 'LineWidth', 1);
hold off; grid on;
xlim([-fs_bb/2 fs_bb/2]/1e3);
xlabel('frequency offset from tuned centre (kHz)');
ylabel('averaged power (dB)');
title(sprintf('NOAA %.4f MHz: carrier %+.1f Hz off centre (%+.2f ppm)', ...
      f_nominal/1e6, f_err, ppm_measured));
legend('averaged spectrum','carrier found','tuned centre (0 Hz)','Location','best');
