function usrp_transmit(which, secs, gain_db, txdir)
%USRP_TRANSMIT  Run an ECE447 instructor transmit model on a USRP, correctly.
%
%   Instructor-side only. Students never run this; they only receive. The
%   transmit models themselves are NOT in this repo -- they ship with the
%   desktopSDR support files, under digital/usrp_tx/.
%
%   The models work, but two of their saved settings make them fail in ways
%   that are easy to misread as broken hardware. This wrapper fixes both at
%   run time and leaves the .slx files untouched, so nothing gets re-saved
%   into a newer MATLAB release (see tools/README.md).
%
% USAGE
%   usrp_transmit('lab6a1')             % Lab 6 Activity 1, 120 s, gain 50
%   usrp_transmit('lab6a2', 600)        % Lab 6 Activity 2, 10 minutes
%   usrp_transmit('lab6a3', 600, 55)    % ... and a louder transmit gain
%   usrp_transmit('lab7')               % Lab 7 ASCII message
%   usrp_transmit('lab8')               % Lab 8 image transfer
%
%   WHICH   one of lab6a1 | lab6a2 | lab6a3 | lab7 | lab8, or a model name
%   SECS    seconds to transmit (default 120). Make it longer than you think:
%           a student starting a receiver mid-run needs the carrier still up.
%   GAIN_DB transmit gain, default 50 (see "Transmit gain" below)
%   TXDIR   folder holding usrp_QPSK_*.slx, if not in the default location
%
% WHAT THIS FIXES, AND WHY
%
%   1. Transmit gain. The models ship with Transmitter Gain (dB) = 10.
%      A USRP's gain counts UPWARD (B200 range 0-89.75), the opposite of the
%      PLUTO these models were converted from, so 10 is nearly nothing.
%      Measured across a 6 ft bench link into an RTL-SDR: 10 and 30 dB are
%      not detectable at all, ~50 dB is the sweet spot, 70 dB saturates the
%      receiver's front end into a forest of spurs. Default here is 50.
%
%   2. Source frame size, in ONE model only. The Activity 1 model ships with
%      SamplesPerFrame = 2 against SampleTime = 1/100e3, i.e. a 20 us frame.
%      That forces Simulink to execute 50,000 model steps per second to hand
%      the radio 4 samples at a time, and the per-step overhead starves it.
%      Measured on the classroom machine: 529 UHD underruns ('U' characters)
%      and 2.6x slower than real time. Raising the frame to 2000 samples --
%      identical data rate, 50 steps/s instead of 50,000 -- cut that to 14
%      underruns and put 4 dB more signal into the receiver.
%
%      The other models do NOT need this and must not get it. Their sources
%      run 50x slower (SampleTime 1/2e3), so the shipped frame of 2 bits is
%      already only 1000 steps/s. Applying 2000 there would make a ONE SECOND
%      frame feeding a Tx Prep stage that already buffers 2.7 s, which is a
%      good way to stop a receiver's timing and carrier loops ever settling.
%      Labs 7 and 8 have no Bernoulli source at all.
%
%      So the frame is only touched when the model's measured step rate is
%      above STEP_LIMIT, and then it is scaled to TARGET_FRAME rather than
%      set to a fixed count. On the Activity 1 model that reproduces the 2000
%      that was verified on air; everywhere else it is a no-op and says so.
%
%   It also forces Accelerator mode. Normal mode cannot keep up at all.
%
% VERIFIED 2026-10-21, USRP B200 to RTL-SDR at 6 ft, MATLAB R2023b:
%   Lab 6 Activity 1  signal received 28.8 dB over the noise floor
%   Lab 6 Activity 2  coarse estimator recovered the injected offset at
%                     receive tuner gain 40 (at the shipped 10 it reports 0)
%   Lab 6 Activity 3  NOT yet confirmed. The three constellations came back
%                     as one rotating mass rather than four clusters, with
%                     the frame wrongly forced to 2000 as described above.
%                     Re-test with this version before relying on it.
%
% THINGS THAT WILL BITE YOU
%
%   * Two MATLAB sessions. MATLAB is single threaded, so a blocking transmit
%     loop cannot also run a receiver. Transmit from one session and receive
%     from another. Both radios share one machine happily -- they are
%     separate USB devices with separate drivers.
%
%   * The radio serial is baked into the models. They are set for the B200
%     serial this course owns. On a different unit, open the SDRu Transmitter
%     block and set Platform and the serial to match, or findsdru will report
%     "No devices found".
%
%   * UHD intermittently reports "No devices found" for a radio that is
%     plainly attached. Usually it is the first access after plugging in,
%     while the B200 loads its FPGA image, but it has also happened mid
%     session after many successful runs. It clears by itself: the device
%     showed Status OK in Windows and Success from findsdru immediately
%     afterwards, and five consecutive opens then succeeded, including
%     back to back with no gap. This function now retries automatically,
%     so you should not see it. Do not start debugging configuration in
%     front of a class.
%
%   * matlab -batch segfaults on exit after any session that opened the USRP
%     (access violation in mnFullExitFcn). It happens strictly after all work
%     and output, is harmless, and does not occur interactively.
%
%   * Receiver gain is a separate problem. If the receiving dongle is left at
%     the models' default Tuner Gain of 10, the coarse frequency estimator
%     locks onto the dongle's DC spike and reports 0 Hz no matter how good
%     this transmission is. Lab 6 tells students to use about 40.

if nargin < 1 || isempty(which),   which   = 'lab6a1'; end
if nargin < 2 || isempty(secs),    secs    = 120;      end
if nargin < 3 || isempty(gain_db), gain_db = 50;       end
if nargin < 4 || isempty(txdir)
    txdir = fullfile(getenv('USERPROFILE'), 'Documents', ...
                     'desktopSDR_supportFiles_v2_0__2021a', 'digital', 'usrp_tx');
end

models = struct('lab6a1','usrp_QPSK_raised_cosine', ...
                'lab6a2','usrp_QPSK_coarse_synch', ...
                'lab6a3','usrp_QPSK_carrier_timing', ...
                'lab7',  'usrp_QPSK_ascii_message', ...
                'lab8',  'usrp_QPSK_image_transfer');
if isfield(models, which), mdl = models.(which); else, mdl = which; end

if ~isfolder(txdir)
    error(['Cannot find the transmit models in:\n  %s\n' ...
           'These ship with the desktopSDR support files, not with this repo. ' ...
           'Pass the folder as the 4th argument.'], txdir);
end
if ~isfile(fullfile(txdir, [mdl '.slx']))
    error('No model "%s.slx" in %s', mdl, txdir);
end

here = pwd;  cleanupObj = onCleanup(@() cd(here));
cd(txdir);
fprintf('[tx] %s  (%s)\n', mdl, which);
load_system(mdl);

% --- fix 1: transmit gain --------------------------------------------------
% gainSrc on the SDRu block is 'Input port', so the dialog gain is ignored and
% this Constant is what actually reaches the radio. Setting the dialog does
% nothing; this is the block to change.
g = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'Constant');
for k = 1:numel(g)
    if contains(get_param(g{k}, 'Name'), 'Transmitter Gain')
        fprintf('[tx] gain %s -> %g dB\n', get_param(g{k},'Value'), gain_db);
        set_param(g{k}, 'Value', num2str(gain_db));
    end
end

% --- fix 2: source frame size ----------------------------------------------
% Same bit rate, far fewer model steps. SampleTime is per bit and is left
% alone, so nothing about the transmitted signal changes.
TARGET_FRAME = 0.020;      % s, the frame period we aim for when we do intervene
STEP_LIMIT   = 10000;      % steps/s above which the radio starves

b = find_system(mdl, 'SearchDepth', 1, 'Name', 'Bernoulli Binary Generator');
if isempty(b)
    fprintf('[tx] no Bernoulli source in this model; frame size left alone\n');
else
    st  = get_param(b{1}, 'SampleTime');
    old = str2double(get_param(b{1}, 'SamplesPerFrame'));
    ts  = NaN;
    try, ts = eval(st); catch, end           %#ok<EVLDIR> the model's own parameter
    if ~isfinite(ts) || ~isfinite(old)
        fprintf('[tx] cannot read the source rate (SampleTime %s); frame left alone\n', st);
    else
        steps = 1/(ts*old);
        if steps <= STEP_LIMIT
            fprintf('[tx] source runs at %.0f steps/s (frame %.1f ms) - fine, left alone\n', ...
                    steps, ts*old*1e3);
        else
            new = max(2, 2*round(TARGET_FRAME/ts/2));   % even: QPSK takes bit pairs
            set_param(b{1}, 'SamplesPerFrame', num2str(new));
            fprintf('[tx] source runs at %.0f steps/s - too fast, starves the radio\n', steps);
            fprintf('[tx] SamplesPerFrame %d -> %d  (frame %.1f ms, %.0f steps/s)\n', ...
                    old, new, ts*new*1e3, 1/(ts*new));
        end
    end
end

set_param(mdl, 'StopTime', num2str(secs));
set_param(mdl, 'SimulationMode', 'accelerator');   % normal mode underruns badly

tx = find_system(mdl, 'SearchDepth', 1, 'Name', 'SDRu Transmitter');
if ~isempty(tx)
    fprintf('[tx] %s Hz, master clock %s, interpolation %s, rate %s\n', ...
        get_param(tx{1},'centerFrequency'), get_param(tx{1},'masterClkRateParam'), ...
        get_param(tx{1},'decimInterp'),     get_param(tx{1},'sampleRate'));
end

% UHD intermittently reports "No devices found" for a radio that is plainly
% attached, usually on the first access after plug-in but occasionally mid
% session. It clears by itself. Retry rather than dying in front of a class.
MAX_TRIES = 4;
for attempt = 1:MAX_TRIES
    if attempt > 1
        fprintf('[tx] retrying in 8 s (attempt %d of %d)\n', attempt, MAX_TRIES);
        pause(8);
    end
    fprintf('[tx] ON AIR for %d s -- Ctrl+C to stop early\n', secs);
    t0 = tic;
    try
        sim(mdl);
        el = toc(t0);
        fprintf('\n[tx] done: %.1f s wall for %d s simulated (%.2fx real time)\n', ...
                el, secs, el/secs);
        if el > secs*1.15 && secs >= 60
            fprintf(['[tx] NOTE: slower than real time, so the radio underran. ' ...
                     'The wall of U characters above is that. Close other work and retry.\n']);
        elseif el > secs*1.15
            fprintf(['[tx] (Short runs look slow because Accelerator compiles first. ' ...
                     'Judge the rate on a run of a minute or more.)\n']);
        end
        break
    catch ME
        msg = regexprep(ME.message, '\s+', ' ');
        transient = contains(msg,'No devices found') || contains(msg,'createDriver_c');
        fprintf('[tx] ERROR after %.1f s: %s\n', toc(t0), msg);
        if ~transient
            fprintf('[tx] not a known transient - stopping.\n');
            break
        elseif attempt == MAX_TRIES
            fprintf(['[tx] still not found after %d tries. Unplug the USRP, wait a few\n' ...
                     '     seconds, plug it back in and run again.\n'], MAX_TRIES);
        end
    end
end
close_system(mdl, 0);     % discard: never re-save these models
end
