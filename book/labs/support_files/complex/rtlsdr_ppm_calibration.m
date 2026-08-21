%% ECE447 Lab 2, Activity 2: measure your RTL-SDR's frequency error, in ppm
%
% Your dongle's tuner is steered by a cheap crystal oscillator, so when you
% ask it for a given centre frequency you actually get something slightly
% different. This script measures that error against a transmitter whose
% frequency really is where it claims to be -- NOAA Weather Radio -- and
% converts the error into parts per million (ppm).
%
% The measurement itself is just the double-sided spectrum from Activity 1:
% tune to the station, and whatever the carrier sits away from 0 Hz in the
% baseband spectrum IS your frequency error.
%
% HOW TO USE
%   1) Let the dongle warm up. The E4000 tuner drifts a lot for the first
%      15-20 minutes after you plug it in. Measure cold and you will measure
%      the wrong number.
%   2) Set f_nominal to the NOAA channel that comes in best where you are.
%   3) Run with ppm_applied = 0 and note the ppm the script prints.
%   4) Put that number into ppm_applied and run again. The carrier should
%      move to (nearly) 0 Hz. If it moved the WRONG way, flip the sign.
%
% NOAA Weather Radio channels (nationwide, always on):
%   162.400  162.425  162.450  162.475  162.500  162.525  162.550  MHz
% Around Colorado Springs, try 162.550 and 162.475 first.

%% PARAMETERS
f_nominal   = 162.550e6;   % NOAA channel you are tuned to, in Hz
ppm_applied = 0;           % 0 for the first run; your measured ppm for the second

rtlsdr_id   = '0';
fs          = 250e3;       % sample rate (Hz) -- plenty for one NBFM channel
frmlen      = 2^16;        % samples per frame
gain        = 40;          % tuner gain (dB); lower it if the display looks clipped
navg        = 20;          % spectra to average (speech pauses give the cleanest carrier)
search_khz  = 40;          % only look this far either side of centre for the carrier

%% RECEIVER
rx = comm.SDRRTLReceiver(...
    rtlsdr_id,...
    'CenterFrequency',    f_nominal,...
    'EnableTunerAGC',     false,...
    'TunerGain',          gain,...
    'SampleRate',         fs,...
    'SamplesPerFrame',    frmlen,...
    'OutputDataType',     'single',...
    'FrequencyCorrection', ppm_applied);

if isempty(sdrinfo(rx.RadioAddress))
    release(rx);
    error('No RTL-SDR found. Check the connection with sdrinfo.');
end

%% CAPTURE AND AVERAGE THE SPECTRUM
Nfft = frmlen;
for k = 1:10, rx(); end                 % discard start-up frames

Pavg = zeros(Nfft,1);
for k = 1:navg
    x    = double(rx());
    X    = fftshift(fft(x, Nfft));
    Pavg = Pavg + abs(X).^2;            % average power, not voltage
end
release(rx);
Pavg = Pavg / navg;

f = ((-Nfft/2):(Nfft/2)-1).' * (fs/Nfft);   % double-sided frequency axis, Hz

%% FIND THE CARRIER AND CONVERT TO PPM
band     = abs(f) <= search_khz*1e3;        % ignore anything far from centre
idx      = find(band);
[~, pk]  = max(Pavg(idx));
f_err    = f(idx(pk));                      % carrier offset from 0 Hz, in Hz

ppm_measured = (f_err / f_nominal) * 1e6;
ppm_total    = ppm_applied + ppm_measured;  % what to use from now on

%% REPORT
fprintf('\n--- RTL-SDR frequency calibration -----------------------------\n');
fprintf('  tuned to            : %.4f MHz\n', f_nominal/1e6);
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
xlim([-search_khz search_khz]);
xlabel('frequency offset from tuned centre (kHz)');
ylabel('averaged power (dB)');
title(sprintf('NOAA carrier at %.4f MHz: %+.1f Hz off centre (%+.2f ppm)', ...
      f_nominal/1e6, f_err, ppm_measured));
legend('averaged spectrum','carrier found','tuned centre (0 Hz)','Location','best');
