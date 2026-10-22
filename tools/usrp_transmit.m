function usrp_transmit(which, secs, gain_db, freq_hz, payload, txdir, mirror)
%USRP_TRANSMIT  Run an ECE447 instructor transmit model on a USRP, correctly.
%
%   Instructor-side only. Students never run this; they only receive. The
%   transmit models themselves are NOT in this repo -- they ship with the
%   desktopSDR support files, under digital/usrp_tx/.
%
%   Several of the models' saved settings make them fail in ways that are easy
%   to misread as broken hardware. This wrapper fixes them at run time and
%   leaves the .slx files untouched, so nothing gets re-saved into a newer
%   MATLAB release (see tools/README.md).
%
% USAGE
%   usrp_transmit('lab6a1')                  % Lab 6 Activity 1, 120 s, gain 50
%   usrp_transmit('lab6a2', 600)             % Lab 6 Activity 2, 10 minutes
%   usrp_transmit('lab6a3', 600, 55)         % ... and a louder transmit gain
%   usrp_transmit('lab7', 1800, [], [], 'Go Falcons!')     % Lab 7 message
%   usrp_transmit('lab8', 1800, [], [], 'image3.mat')      % Lab 8 image
%   usrp_transmit('lab7', 0)                 % configure and report, do NOT transmit
%
%   WHICH    lab6a1 | lab6a2 | lab6a3 | lab7 | lab8, or a model name
%   SECS     seconds to transmit (default 120). Make it longer than you think:
%            a student starting a receiver mid-run needs the carrier still up.
%            **SECS = 0 is a dry run** -- it reports everything it would do and
%            never touches the radio. Use it to check a setup before class.
%   GAIN_DB  transmit gain, default 50 (see "Transmit gain" below)
%   FREQ_HZ  center frequency; default is whatever the model ships with
%            (433.5 MHz for all five). Announce this number to the class.
%   PAYLOAD  Lab 7: the message text, up to 50 characters.
%            Lab 8: the image file, 'image1.mat' ... 'image7.mat'.
%            Ignored by the Lab 6 models, which send random bits.
%   TXDIR    folder holding usrp_QPSK_*.slx, if not in the default location
%
% WHAT THIS FIXES, AND WHY
%
%   1. Transmit gain. Every model ships with its gain constant at 10.
%      A USRP's gain counts UPWARD (B200 range 0-89.75), the opposite of the
%      PLUTO these models were converted from, so 10 is nearly nothing.
%      Measured across a 6 ft bench link into an RTL-SDR: 10 and 30 dB are
%      not detectable at all, ~50 dB is the sweet spot, 70 dB saturates the
%      receiver's front end into a forest of spurs. Default here is 50.
%
%      The gain constant is NOT named the same in every model -- it is
%      'Transmitter Gain (dB)' in the Lab 6 models but 'Transmit Power (dB)'
%      in Labs 7 and 8 -- so this function finds it by following the wire into
%      the radio's gain port rather than by name. An earlier version matched
%      on the name and silently left Labs 7 and 8 transmitting at 10.
%
%      Note the gain on the SDRu block's own dialog (25 in the Lab 7 and 8
%      models) is ignored: gainSource is 'Input port', so only the Constant
%      counts.
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
% WHAT YOU HAVE TO TELL THE CLASS
%
%   This function prints an "ANNOUNCE TO THE CLASS" block before it goes on
%   air. Read it out. It covers the center frequency, and for Lab 8 the
%   image checksum that Activity 2 asks students to compare against.
%
%   Students also have to change two things on their own receivers, in every
%   lab from 6 onward, and both look like broken models when missed:
%     * Tuner Gain (dB) -- ships at 10 or 20, needs to be about 40
%     * Frequency correction (ppm) -- ships at 0, needs their Lab 2 figure
%
% MODULATION: LAB 7 IS QPSK, LAB 8 IS DQPSK
%
%   The Lab 7 transmit model has a Manual Switch choosing between a QPSK and
%   a DQPSK modulator, and the student receiver has a matching switch. They
%   must agree or the text decodes as garbage. Both ship on QPSK, and this
%   function forces the transmit side to QPSK so a stray click cannot leave
%   the class unable to decode. The Lab 8 chain is DQPSK end to end, with no
%   switch on either side, which is why its fallback captures are named
%   dqpsk_image*.mat.
%
% KEEP THE LAB 7 MESSAGE 12 CHARACTERS LONG
%
%   The receiver decodes a fixed number of characters per frame, set from the
%   model's own mask, and that number matches the shipped 'Hello World!' --
%   twelve characters. A shorter message still decodes but every line picks up
%   a trailing junk character: 'Go Falcons!' (eleven) came back as
%   'Go Falcons! 026?'. Harmless, but students will ask. Pad to twelve.
%
% VERIFIED 2026-10-21, USRP B200 to RTL-SDR at 6 ft, MATLAB R2023b:
%   Lab 6 Activity 1  signal received 28.8 dB over the noise floor
%   Lab 6 Activity 2  coarse estimator recovered the injected offset at
%                     receive tuner gain 40 (at the shipped 10 it reports 0)
%   Lab 6 Activity 3  does NOT acquire dependably over the air -- four
%                     clusters on only 6 of 16 runs. That activity now runs
%                     from the textbook's recorded capture instead; see
%                     book/labs/Lab6.md.
%   Lab 7             transmits correctly, and a live decode IS achievable --
%                     88 frames of the transmitted message recovered -- but
%                     only with a conjugate added on the RECEIVE side, and
%                     only when the carrier happens to lock at 0 degrees
%                     rather than 90, 180 or 270 (two of four captures). The
%                     lab therefore runs from the recording. tools/README.md
%                     has the measurements.
%   Lab 8             same transmit chain and same framing; runs from the
%                     recording for the same reason.
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
%     the models' default Tuner Gain, the coarse frequency estimator locks
%     onto the dongle's DC spike and reports 0 Hz no matter how good this
%     transmission is. The labs tell students to use about 40.

if nargin < 1 || isempty(which),   which   = 'lab6a1'; end
if nargin < 2 || isempty(secs),    secs    = 120;      end
if nargin < 3 || isempty(gain_db), gain_db = 50;       end
if nargin < 4, freq_hz = [];  end
if nargin < 5, payload = '';  end
if nargin < 6 || isempty(txdir)
    txdir = fullfile(getenv('USERPROFILE'), 'Documents', ...
                     'desktopSDR_supportFiles_v2_0__2021a', 'digital', 'usrp_tx');
end
dryrun = isnumeric(secs) && isscalar(secs) && secs == 0;

models = struct('lab6a1','usrp_QPSK_raised_cosine', ...
                'lab6a2','usrp_QPSK_coarse_synch', ...
                'lab6a3','usrp_QPSK_carrier_timing', ...
                'lab7',  'usrp_QPSK_ascii_message', ...
                'lab8',  'usrp_QPSK_image_transfer');
if isfield(models, which), mdl = models.(which); else, mdl = which; end

if ~isfolder(txdir)
    error(['Cannot find the transmit models in:\n  %s\n' ...
           'These ship with the desktopSDR support files, not with this repo. ' ...
           'Pass the folder as the 6th argument.'], txdir);
end
if ~isfile(fullfile(txdir, [mdl '.slx']))
    error('No model "%s.slx" in %s', mdl, txdir);
end

here = pwd;  cleanupObj = onCleanup(@() cd(here));
cd(txdir);
fprintf('[tx] %s  (%s)%s\n', mdl, which, tern(dryrun,'  *** DRY RUN ***',''));
load_system(mdl);

% --- fix 1: transmit gain --------------------------------------------------
% The SDRu block's gainSource is 'Input port', so its dialog gain is ignored
% and the Constant wired to that port is the only thing that reaches the
% radio. That Constant is named differently between models, so follow the
% wire rather than the name.
txb = findblk(mdl, 'SDRu Transmitter');
gain_set = false;
if ~isempty(txb)
    pc = get_param(txb{1}, 'PortConnectivity');
    for k = 1:numel(pc)
        if isempty(pc(k).SrcBlock), continue; end
        src = getfullname(pc(k).SrcBlock);
        if strcmp(get_param(src, 'BlockType'), 'Constant')
            fprintf('[tx] gain: "%s" %s -> %g dB\n', ...
                    regexprep(get_param(src,'Name'),'\s+',' '), ...
                    get_param(src,'Value'), gain_db);
            set_param(src, 'Value', num2str(gain_db));
            gain_set = true;
        end
    end
end
if ~gain_set
    fprintf(['[tx] WARNING: no Constant found feeding the radio gain port.\n' ...
             '     This transmission may go out at the model''s shipped gain,\n' ...
             '     which is 10 and is not receivable. Check the model.\n']);
end

% --- fix 2: source frame size ----------------------------------------------
% Same bit rate, far fewer model steps. SampleTime is per bit and is left
% alone, so nothing about the transmitted signal changes.
TARGET_FRAME = 0.020;      % s, the frame period we aim for when we do intervene
STEP_LIMIT   = 10000;      % steps/s above which the radio starves

b = findblk(mdl, 'Bernoulli Binary Generator');
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

% --- fix 3: mirrored I/Q, for the framed labs ------------------------------
% Our USRP transmit chain sends the signal spectrally mirrored (I and Q
% swapped) relative to the captures the textbook's receivers were built
% against. Almost certainly an artefact of converting these models from the
% PLUTO blocks they shipped on.
%
% Nothing in Lab 6 can see it: a mirrored QPSK constellation still shows four
% clusters, and a mirrored spectrum still shows the right bandwidth, so that
% lab measures the same either way (the one visible trace is that Lab 6
% Activity 2's coarse estimate comes back with the opposite sign to the
% induced peak's position).
%
% Labs 7 and 8 are a different matter, because they decide where a frame
% starts by correlating against a known 39-bit preamble and firing a strobe
% when the correlation reaches preamble_len-6 = 33. Mirroring scrambles the
% bit mapping without touching the constellation, and the correlation then
% peaks at 17 instead of 39 -- so the strobe never fires, nothing decodes,
% and the receiver looks perfectly healthy while doing it. Measured: feeding
% the textbook's own working capture through a conjugate reproduces exactly
% the 17 seen over the air, with the constellation still locked at 0.98.
%
% Conjugating here, in the transmit chain, SHOULD mean every student receiver
% works untouched. It does not, for reasons not yet understood -- see the
% measurement below. The conjugate has to go on the receive side instead.
% MEASURED 2026-10-21: inserting the conjugate HERE, on the transmit side, does
% not work. Four live captures that all locked cleanly (Rx Rotated 0.976-0.979)
% came back with preamble correlation 13, 13, 15 and 21 against the 33 needed,
% zero frame strobes and no text -- indistinguishable from not applying it.
% Conjugating the RECEIVED samples instead does work: the same four captures
% gave correlation 39 on two of them, 88 frame strobes and 88 decoded lines of
% the transmitted message. So the default is OFF; 'on' is left available only
% for anyone who wants to investigate why the two sides are not equivalent.
if nargin < 7 || isempty(mirror), mirror = 'off'; end
switch lower(mirror)
    case 'on',  needs_conj = true;
    otherwise,  needs_conj = false;
end
% Applied on the baseband SYMBOL path, at the transmit filter's input, which
% is the modulator's own output and is measurably complex (checked by logging
% it with the radio commented out). Placing it further down, on the
% interpolated stream entering the radio, works in principle too; this point
% is just the one that says what it means.
if needs_conj
    rrc = findblk(mdl, 'Raised Cosine Transmit Filter');
    done = false;
    if ~isempty(rrc)
        try
            pcr = get_param(rrc{1}, 'PortConnectivity');
            srcb = [];
            for k = 1:numel(pcr)
                if ~isempty(pcr(k).SrcBlock) && strcmp(pcr(k).Type,'1')
                    srcb = pcr(k).SrcBlock; break
                end
            end
            lnr = get_param(rrc{1}, 'LineHandles');
            delete_line(lnr.Inport(1));
            cj = [mdl '/IQ mirror fix'];
            add_block('simulink/Math Operations/Math Function', cj, ...
                      'Function', 'conj', 'Position', [40 40 80 70]);
            ch = get_param(cj, 'PortHandles');
            sh = get_param(srcb, 'PortHandles');
            add_line(mdl, sh.Outport(1), ch.Inport(1), 'autorouting','on');
            add_line(mdl, ch.Outport(1), ...
                     get_param(rrc{1},'PortHandles').Inport(1), 'autorouting','on');
            pc2 = get_param(rrc{1}, 'PortConnectivity');
            for q = 1:numel(pc2)
                if ~isempty(pc2(q).SrcBlock) && strcmp(pc2(q).Type,'1')
                    fprintf('[tx] I/Q mirror fix (conj) inserted: %s -> transmit filter\n', ...
                        strtrim(regexprep(get_param(pc2(q).SrcBlock,'Name'),'\s+',' ')));
                end
            end
            done = true;
        catch ME
            fprintf(['[tx] WARNING: could not insert the I/Q mirror fix (%s).\n' ...
                     '     Labs 7 and 8 will NOT decode without it -- the receiver\n' ...
                     '     will look fine but no frame strobe will ever fire.\n'], ...
                    regexprep(ME.message,'\s+',' '));
        end
    end
    if ~done
        fprintf('[tx] NOTE: I/Q mirror fix not applied; see tools/README.md\n');
    end
end

% --- center frequency ------------------------------------------------------
if ~isempty(txb) && ~isempty(freq_hz)
    set_param(txb{1}, 'centerFrequency', num2str(freq_hz, '%.10g'));
end
announce_freq = '';
if ~isempty(txb)
    announce_freq = get_param(txb{1}, 'centerFrequency');
end

% --- payload: Lab 7 message, Lab 8 image -----------------------------------
announce_extra = {};
switch mdl
    case 'usrp_QPSK_ascii_message'
        src = findblk(mdl, 'ASCII Transfer Binary Source');
        if isempty(src)
            fprintf('[tx] WARNING: no "ASCII Transfer Binary Source" block found\n');
        else
            if ~isempty(payload)
                if numel(payload) > 50
                    fprintf('[tx] message is %d chars; the generator truncates at 50\n', ...
                            numel(payload));
                end
                set_param(src{1}, 'msg_tx', payload);
            end
            msg = get_param(src{1}, 'msg_tx');
            fprintf('[tx] message: "%s"\n', msg);
            fprintf(['[tx] the generator appends a space and a 3-digit frame counter,\n' ...
                     '     so students see "%s 001" ... "%s 100" repeating. Consecutive\n' ...
                     '     counters are how they tell frames are arriving in order.\n'], msg, msg);
            announce_extra{end+1} = sprintf('Message being sent: "%s" (plus a frame counter)', msg);
        end
        % keep the modulator switch on QPSK, to match the student receivers
        sw = find_system(mdl, 'LookUnderMasks','all', 'FollowLinks','on', ...
                         'BlockType','ManualSwitch');
        for k = 1:numel(sw)
            fprintf('[tx] modulator switch sw=%s (forcing QPSK to match the receivers)\n', ...
                    get_param(sw{k},'sw'));
            set_param(sw{k}, 'sw', '1');
        end

    case 'usrp_QPSK_image_transfer'
        src = findblk(mdl, 'Image Transfer Binary Source');
        if isempty(src)
            fprintf('[tx] WARNING: no "Image Transfer Binary Source" block found\n');
        else
            if ~isempty(payload)
                set_param(src{1}, 'filename', payload);
            end
            imgfile = get_param(src{1}, 'filename');
            fprintf('[tx] image: %s\n', imgfile);
            % Lab 8 Activity 2 asks students to compare a checksum, so work
            % out the right answer here rather than making someone derive it.
            try
                S = load(imgfile);
                fn = fieldnames(S);
                img = S.(fn{1});
                chk = mod(sum(uint32(img(:))), 256);
                fprintf('[tx] checksum of %s = %d  <-- Lab 8 Activity 2 answer\n', imgfile, chk);
                announce_extra{end+1} = sprintf('Image: %s', imgfile);
                announce_extra{end+1} = sprintf('Correct checksum: %d', chk);
            catch ME
                fprintf(['[tx] could not load %s to compute its checksum (%s).\n' ...
                         '     Students need that number for Activity 2 -- work it out with\n' ...
                         '     load(''%s''); mod(sum(uint32(image(:))),256)\n'], ...
                        imgfile, ME.message, imgfile);
            end
        end
        if ~dryrun && secs < 150
            fprintf(['[tx] NOTE: one full image is 100 frames at about 0.5 s each, so a\n' ...
                     '     complete pass takes ~50 s. At %d s a student who starts late\n' ...
                     '     will see a part-white image. Run this for 10+ minutes in class.\n'], secs);
        end
end

set_param(mdl, 'StopTime', num2str(secs));
set_param(mdl, 'SimulationMode', 'accelerator');   % normal mode underruns badly

if ~isempty(txb)
    fprintf('[tx] %s Hz, master clock %s, interpolation %s, rate %s\n', ...
        get_param(txb{1},'centerFrequency'), get_param(txb{1},'masterClkRateParam'), ...
        get_param(txb{1},'decimInterp'),     get_param(txb{1},'sampleRate'));
end

% --- what the instructor has to say out loud -------------------------------
fprintf('\n=============== ANNOUNCE TO THE CLASS ===============\n');
if ~isempty(announce_freq)
    fprintf('  Transmit frequency: %s Hz\n', announce_freq);
end
for k = 1:numel(announce_extra)
    fprintf('  %s\n', announce_extra{k});
end
fprintf('  Remind them: Tuner Gain (dB) ~40, and their Lab 2 ppm figure.\n');
fprintf('=====================================================\n\n');

if dryrun
    fprintf('[tx] dry run: the radio was never opened. Pass a nonzero SECS to transmit.\n');
    close_system(mdl, 0);
    return
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

function o = tern(c, a, b)
if c, o = a; else, o = b; end
end

function h = findblk(mdl, want)
%FINDBLK  Top-level block whose name contains WANT, ignoring whitespace.
%   Some of these block names carry a leading space or an embedded newline
%   (' ASCII Transfer Binary Source', 'RTL-SDR Receiver\no/p fs=240kHz'), so
%   an exact 'Name' match to find_system silently returns nothing. Matching
%   on the collapsed, trimmed name is the only reliable way.
h = {};
want = lower(strtrim(regexprep(want, '\s+', ' ')));
for b = find_system(mdl, 'SearchDepth', 1, 'IncludeCommented', 'on', 'Type', 'Block').'
    nm = lower(strtrim(regexprep(get_param(b{1}, 'Name'), '\s+', ' ')));
    if contains(nm, want), h{end+1} = b{1}; end %#ok<AGROW>
end
end
