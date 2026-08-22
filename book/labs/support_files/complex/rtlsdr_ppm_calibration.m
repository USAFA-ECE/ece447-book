%% ECE447 Lab 2, Activity 2: listen to NOAA Weather Radio, then measure ppm
%
% Your dongle's tuner is steered by a cheap crystal oscillator, so when you
% ask it for a given centre frequency you actually get something slightly
% different. This script measures that error against a transmitter whose
% frequency really is where it claims to be -- NOAA Weather Radio -- and
% converts the error into parts per million (ppm).
%
% Each run does three things, in order:
%   1) captures a few seconds of the weather station,
%   2) FM-demodulates it and PLAYS it, so you can hear you are on station,
%   3) reports how far the carrier sits from 0 Hz, in Hz and in ppm, and
%      plots the spectrum.
%
% You run it TWICE:
%   Run 1  ppm_applied = 0        -> the carrier sits off centre. SAVE THIS PLOT.
%   Run 2  ppm_applied = <your ppm> -> the carrier snaps to the middle. SAVE THIS PLOT TOO.
% Both plots go in your lab write-up.
%
% HOW THE CORRECTION IS APPLIED
% Not through the radio's 'FrequencyCorrection' property: that one takes whole
% numbers of ppm only, and on this hardware a few ppm often gets quantised
% away when the tuner retunes -- you ask for 3 ppm and the carrier does not
% move. Instead the script multiplies the samples by a complex exponential,
% s(t)*exp(-j*2*pi*df*t) -- the same expression from the maths section of the
% lab. That is exact, and it takes fractional ppm.
%
% BEFORE YOU MEASURE
% Let the dongle warm up. The E4000 tuner drifts a lot for the first 15-20
% minutes after you plug it in. Measure cold and you will measure the wrong
% number.
%
% NOAA Weather Radio channels (nationwide, always on):
%   162.400  162.425  162.450  162.475  162.500  162.525  162.550  MHz
% Around Colorado Springs, try 162.475 first, then 162.550.

%% PARAMETERS
f_nominal   = 162.475e6;   % NOAA channel you are tuned to, in Hz
ppm_applied = 0;           % RUN 1: leave at 0.
                           % RUN 2: type in the ppm that run 1 reported.

rtlsdr_id   = '0';
gain        = 40;          % tuner gain (dB); lower it if the spectrum looks clipped
play_secs   = 5;           % seconds of audio to capture and play back

% The RTL2832U only supports sample rates of 225-300 kHz or 0.9-3.2 MHz, so we
% cannot ask the hardware for a narrow rate directly. Instead we take a low
% hardware rate and decimate in software. 240 kHz / 5 gives a 48 kHz baseband:
% a +/-24 kHz view, a good match for a ~16 kHz wide narrowband FM signal, and
% a standard audio rate for playback.
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
    'OutputDataType',     'single');

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
h  = fir1(200, 1/decim);                      % low-pass to the new Nyquist
xf = filter(h, 1, x);
xb = xf(1:decim:end);                         % complex baseband at fs_bb

%% APPLY YOUR CORRECTION
% Convert the ppm you typed in above into hertz at this centre frequency,
% then spin the samples by that much. On run 1 this does nothing, because
% ppm_applied is 0.
df_applied = ppm_applied * 1e-6 * f_nominal;
n  = (0:numel(xb)-1).';
xb = xb .* exp(-1j*2*pi*df_applied*n/fs_bb);

%% FM DEMODULATE AND PLAY
% A discriminator: the angle between one sample and the previous one is
% proportional to instantaneous frequency (you meet this again in Lab 4).
d     = xb(2:end) .* conj(xb(1:end-1));
audio = angle(d);

audio = audio - mean(audio);                  % strip the DC term
ha    = fir1(200, audio_bw/(fs_bb/2));        % keep the voice band only
audio = filter(ha, 1, audio);

pk = max(abs(audio));
if pk > 0, audio = 0.9 * audio / pk; end      % audible, not clipped

fprintf('Playing %.1f s of audio -- you should hear the weather broadcast.\n', ...
        numel(audio)/fs_bb);
player = audioplayer(audio, fs_bb);
playblocking(player);

%% MEASURE WHERE THE CARRIER ENDED UP
[f_err, Pavg, f] = measure_carrier(xb, fs_bb, Nfft, search_khz);

ppm_measured = (f_err / f_nominal) * 1e6;     % error still left over
ppm_total    = ppm_applied + ppm_measured;    % your dongle's total error

%% REPORT
fprintf('\n--- RTL-SDR frequency calibration -----------------------------\n');
fprintf('  tuned to            : %.4f MHz\n', f_nominal/1e6);
fprintf('  hardware rate       : %.0f kHz, decimated by %d -> %.0f kHz\n', ...
        fs_rtl/1e3, decim, fs_bb/1e3);
fprintf('  correction applied  : %+.2f ppm\n', ppm_applied);
fprintf('  carrier landed at   : %+.1f Hz from centre\n', f_err);
fprintf('  error still left    : %+.3f ppm\n', ppm_measured);
fprintf('  ---------------------------------------------------------\n');
fprintf('  USE THIS VALUE      : %+.2f ppm  <-- your dongle''s correction\n', ppm_total);
fprintf('---------------------------------------------------------------\n');
if ppm_applied == 0
    fprintf('  Now put %+.2f into ppm_applied and run again.\n\n', ppm_total);
else
    fprintf('  Carrier should now be near 0 Hz. Save this plot.\n\n');
end

%% PLOT
figure;
plot(f/1e3, 10*log10(Pavg + eps), 'b-'); hold on;
xline(f_err/1e3, 'r--', 'LineWidth', 2);
xline(0, 'k:', 'LineWidth', 1);
hold off; grid on;
xlim([-fs_bb/2 fs_bb/2]/1e3);
xlabel('frequency offset from tuned centre (kHz)');
ylabel('averaged power (dB)');
title(sprintf('NOAA %.4f MHz, %+.2f ppm applied: carrier %+.1f Hz off centre', ...
      f_nominal/1e6, ppm_applied, f_err));
legend('averaged spectrum','carrier found','tuned centre (0 Hz)','Location','best');

%% ------------------------------------------------------------------
function [f_err, Pavg, f] = measure_carrier(x, fs, Nfft, search_khz)
% Average the double-sided spectrum and return the offset of the strongest
% component within +/- search_khz of centre, interpolated to sub-bin accuracy.
    nseg = max(floor(numel(x)/Nfft), 1);
    w    = hann(Nfft);
    Pavg = zeros(Nfft,1);
    for k = 1:nseg
        seg  = x((k-1)*Nfft + (1:Nfft));
        Pavg = Pavg + abs(fftshift(fft(seg .* w, Nfft))).^2;
    end
    Pavg = Pavg / nseg;

    f      = ((-Nfft/2):(Nfft/2)-1).' * (fs/Nfft);
    idx    = find(abs(f) <= search_khz*1e3);
    [~, p] = max(Pavg(idx));
    pk     = idx(p);
    f_err  = f(pk);

    % parabolic interpolation on the dB peak, for better than one 5.9 Hz bin
    if pk > 1 && pk < numel(f)
        a   = 10*log10(Pavg(pk-1) + eps);
        b   = 10*log10(Pavg(pk)   + eps);
        c   = 10*log10(Pavg(pk+1) + eps);
        den = a - 2*b + c;
        if den ~= 0
            delta = 0.5*(a - c)/den;
            if abs(delta) <= 1
                f_err = f(pk) + delta*(fs/Nfft);
            end
        end
    end
end
