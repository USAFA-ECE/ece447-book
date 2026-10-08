%% ECE447 - Lab 1: capture a real FM broadcast, then loop-transmit it in class
%
% Fairchild Hall blocks broadcast FM almost completely, so students cannot find
% a live FM station from inside the classroom. This script lets the instructor
% record a few seconds of a real broadcast once, then replay it on a continuous
% loop from an ADALM-PLUTO or a USRP, giving the whole class a genuine FM signal
% to tune to during Lab 1, Activity 1 - without anyone leaving the room.
%
% HOW TO USE
%   1) CAPTURE. Near a window or outside (the southeast corner of Fairchild
%      works well), plug in the RTL-SDR, set mode = 'capture', and run. The
%      script records a few seconds of a strong local station, saves it, and
%      plots the spectrum so you can confirm you actually caught the signal.
%
%   2) TRANSMIT. Back in the classroom, plug in the transmit radio, set
%      mode = 'transmit', set tx_radio, and run. Announce tx_freq to the class.
%
%        tx_radio = 'usrp'   The script streams the clip to the radio in a loop
%                            and KEEPS RUNNING - the command window is tied up
%                            until you stop it.
%                              to stop:  Ctrl+C, then  release(obj_usrp)
%
%        tx_radio = 'pluto'  The clip is handed to the PLUTO, which loops it
%                            from its own buffer. The script returns to the
%                            prompt immediately and the radio keeps going.
%                              to stop:  release(obj_pluto)
%
% BEFORE YOU TRANSMIT: set tx_freq to a frequency your unit is authorised to
% transmit on (the same one you announce for the Lab 6-8 PLUTO transmissions is
% a good choice), and keep the gain low - the signal only has to cross a
% classroom. Do not simply rebroadcast on the station's own frequency.
%
% NOTE ON GAIN: the two radios use opposite conventions. PLUTO gain runs from
% -89.75 to 0 dB (0 is full output), USRP gain runs upward from 0 (default 8,
% top of the range depends on the daughterboard). They are set separately below
% so one cannot be pasted into the other.

%% PARAMETERS
mode                = 'transmit';    % 'capture' to record, 'transmit' to replay
tx_radio            = 'usrp';       % 'usrp' or 'pluto' (only used to transmit)

rtlsdr_id           = '0';          % RTL-SDR ID
rtlsdr_station      = 98.1e6;       % strong local FM station to record, in Hz
rtlsdr_gain         = 30;           % RTL-SDR tuner gain in dB
rtlsdr_frmlen       = 2^18;         % RTL-SDR output data frame size

tx_freq             = 150e6;        % <<< SET THIS: transmit frequency, Hz

% --- USRP -------------------------------------------------------------------
usrp_platform       = '';           % '' to auto-detect, or 'B200', 'B210',
                                    %   'N200/N210/USRP2', 'N300', 'N310',
                                    %   'N320/N321', 'X300', 'X310'
usrp_address        = '';           % '' to auto-detect. Otherwise the serial
                                    %   number (B200/B210) or the IP address
                                    %   (every other platform).
usrp_gain           = 20;           % USRP transmit gain in dB, counts UPWARD
                                    %   from 0. Start low, raise in 5 dB steps
                                    %   only as far as the back row needs.
usrp_clockrate      = [];           % master clock, Hz. Leave [] to use the
                                    %   detected platform's default (32e6 for
                                    %   B200/B210, 200e6 for X300/X310 and
                                    %   N320/N321, 125e6 for N300/N310). Fixed
                                    %   at 100e6 on N200/N210/USRP2 whatever is
                                    %   set here.
usrp_frmlen         = 2^16;         % samples pushed to the radio per call.
                                    %   Raise it if you see underruns.

% --- ADALM-PLUTO ------------------------------------------------------------
pluto_id            = 'usb:0';      % ADALM-PLUTO ID
pluto_gain          = -30;          % PLUTO transmit gain in dB (-89.75 to 0),
                                    %   start low and raise only as needed

fs                  = 1e6;          % sample rate in Hz - valid for ALL radios
                                    %   (RTL-SDR 0.9-3.2 MHz, PLUTO >= ~0.52 MHz,
                                    %   and 1 MHz divides every USRP master
                                    %   clock by a legal interpolation factor)
capture_secs        = 5;            % seconds to record. On the PLUTO the whole
                                    %   clip is held in the radio's buffer, so
                                    %   keep it short; shrink this if
                                    %   transmitRepeat complains about the buffer
                                    %   size. The USRP streams from the host, so
                                    %   length is limited only by memory.
capture_file        = 'fm_capture.mat';

%% CAPTURE OR TRANSMIT
switch lower(mode)

    case 'capture'

        % rtl-sdr object
        obj_rtlsdr = comm.SDRRTLReceiver(...
            rtlsdr_id,...
            'CenterFrequency', rtlsdr_station,...
            'EnableTunerAGC', false,...
            'TunerGain', rtlsdr_gain,...
            'SampleRate', fs,...
            'SamplesPerFrame', rtlsdr_frmlen,...
            'OutputDataType', 'single');

        % check if RTL-SDR is active
        if isempty(sdrinfo(obj_rtlsdr.RadioAddress))
            release(obj_rtlsdr);
            error('No RTL-SDR found - plug it in and try again.');
        end

        nframes = ceil(capture_secs*fs/rtlsdr_frmlen);
        iq = complex(zeros(nframes*rtlsdr_frmlen, 1, 'single'));

        fprintf('Recording %.1f s of %.2f MHz ...\n', capture_secs, rtlsdr_station/1e6);
        for k = 1:nframes
            iq((k-1)*rtlsdr_frmlen + (1:rtlsdr_frmlen)) = obj_rtlsdr();
        end
        release(obj_rtlsdr);

        % scale to just under full scale so the transmit radio does not clip
        iq = single(0.8 * iq / max(abs(iq)));
        save(capture_file, 'iq', 'fs', 'rtlsdr_station', '-v7.3');
        fprintf('Saved %d samples to %s\n', numel(iq), capture_file);

        % sanity check - you should see a ~200 kHz wide FM signal near 0 Hz
        nfft = 2^15;
        seg  = double(iq(1:min(nfft, numel(iq))));
        fax  = (-nfft/2:nfft/2-1) * (fs/nfft) / 1e3;
        figure;
        plot(fax, 20*log10(abs(fftshift(fft(seg, nfft))) + eps));
        grid on;
        xlabel('Offset from centre frequency (kHz)');
        ylabel('Magnitude (dB)');
        title(sprintf('Captured FM at %.2f MHz', rtlsdr_station/1e6));

    case 'transmit'

        if ~isfile(capture_file)
            error('%s not found - run this script with mode = ''capture'' first.', ...
                capture_file);
        end
        rec = load(capture_file);
        fprintf('Loaded %d samples (%.1f s at %.2f MHz sample rate).\n', ...
            numel(rec.iq), numel(rec.iq)/rec.fs, rec.fs/1e6);

        switch lower(tx_radio)

            case 'usrp'

                % A radio left locked by an earlier Ctrl+C reports 'Busy', so
                % free one still sitting in the workspace before looking.
                if exist('obj_usrp', 'var') && isa(obj_usrp, 'comm.SDRuTransmitter')
                    release(obj_usrp);
                end

                % find the radio and fill in whatever was left blank above
                if isempty(usrp_address)
                    found = findsdru();
                else
                    found = findsdru(usrp_address);
                end
                if isempty(found) || ~isfield(found, 'Status')
                    error(['No USRP found. Check power and the USB or Ethernet ' ...
                        'cable; for a networked radio, check that the host is ' ...
                        'on the same subnet.']);
                end
                found = found(strcmp({found.Status}, 'Success'));
                if isempty(found)
                    error(['A USRP was found but is not available (busy or wrong ' ...
                        'firmware). If a previous run was stopped with Ctrl+C, ' ...
                        'free it with:  clear obj_usrp']);
                end

                found_radio = found(1);
                if isempty(usrp_platform)
                    usrp_platform = found_radio.Platform;
                end
                if isempty(usrp_address)
                    if any(strcmp(usrp_platform, {'B200', 'B210'}))
                        usrp_address = found_radio.SerialNum;
                    else
                        usrp_address = found_radio.IPAddress;
                    end
                end
                fprintf('Using %s (%s).\n', usrp_platform, usrp_address);

                % B-series radios are addressed by serial number over USB, the
                % networked platforms by IP
                if any(strcmp(usrp_platform, {'B200', 'B210'}))
                    usrp_args = {'Platform', usrp_platform, 'SerialNum', usrp_address};
                else
                    usrp_args = {'Platform', usrp_platform, 'IPAddress', usrp_address};
                end

                % N200/N210/USRP2 is fixed at 100 MHz and rejects the property
                if strcmp(usrp_platform, 'N200/N210/USRP2')
                    clockrate = 100e6;
                else
                    if isempty(usrp_clockrate)
                        clockrate = local_default_clockrate(usrp_platform);
                    else
                        clockrate = usrp_clockrate;
                    end
                    usrp_args = [usrp_args, {'MasterClockRate', clockrate}];
                end

                % unlike the PLUTO, a USRP has no "set the sample rate" control
                interp_factor = local_interp_factor(clockrate, rec.fs, usrp_platform);

                obj_usrp = comm.SDRuTransmitter(usrp_args{:},...
                    'CenterFrequency', tx_freq,...
                    'Gain', usrp_gain,...
                    'InterpolationFactor', interp_factor);

                % The radio locks its input size on the first call, so every
                % frame has to be the same length - drop the odd tail samples.
                nfrm = floor(numel(rec.iq) / usrp_frmlen);
                if nfrm < 1
                    error(['The clip is shorter than one %d-sample frame. ' ...
                        'Lower usrp_frmlen or raise capture_secs.'], usrp_frmlen);
                end
                frames = reshape(rec.iq(1:nfrm*usrp_frmlen), usrp_frmlen, nfrm);

                fprintf('Transmitting on a loop at %.2f MHz (gain %g dB, %.3f MHz baseband).\n', ...
                    tx_freq/1e6, usrp_gain, clockrate/interp_factor/1e6);
                fprintf('Announce %.2f MHz to the class.\n', tx_freq/1e6);
                fprintf('To stop:  Ctrl+C, then  release(obj_usrp)\n\n');

                % There is no transmitRepeat for the USRP - the loop lives here
                % on the host, which is why the script does not return.
                npass  = 0;
                nunder = 0;
                warned = false;
                while true
                    for k = 1:nfrm
                        nunder = nunder + double(obj_usrp(frames(:,k)));
                    end
                    npass = npass + 1;

                    if ~warned && nunder > 0
                        warning(['Underruns - the host is not feeding the radio ' ...
                            'fast enough, which students will hear as clicks. ' ...
                            'Raise usrp_frmlen and close other applications.']);
                        warned = true;
                    end
                    if npass == 1 || mod(npass, 12) == 0
                        fprintf('  pass %d, %.0f s on air, %d underruns\n', ...
                            npass, npass*nfrm*usrp_frmlen/rec.fs, nunder);
                    end
                end

            case 'pluto'

                % adalm-pluto object
                obj_pluto = sdrtx('Pluto',...
                    'RadioID', pluto_id,...
                    'CenterFrequency', tx_freq,...
                    'BasebandSampleRate', rec.fs,...
                    'Gain', pluto_gain);

                % hand the clip to the radio, which repeats it from its own buffer
                transmitRepeat(obj_pluto, double(rec.iq));

                fprintf('Transmitting on a loop at %.2f MHz (gain %g dB).\n', ...
                    tx_freq/1e6, pluto_gain);
                fprintf('Announce %.2f MHz to the class. To stop:  release(obj_pluto)\n', ...
                    tx_freq/1e6);

                % If transmitRepeat rejects the buffer size, either reduce
                % capture_secs and re-capture, or stream it from MATLAB instead:
                %     while true
                %         obj_pluto(double(rec.iq));
                %     end

            otherwise
                error('tx_radio must be ''usrp'' or ''pluto''.');

        end

    otherwise
        error('mode must be ''capture'' or ''transmit''.');

end

%% LOCAL FUNCTIONS
function rate = local_default_clockrate(platform)
%LOCAL_DEFAULT_CLOCKRATE  Stock master clock for a platform, in Hz.
%   Each platform accepts only certain clock rates, so guessing wrong is an
%   error rather than a quiet retune. A 1 MHz baseband rate divides all of
%   these by a legal interpolation factor.

switch platform
    case {'X300', 'X310', 'N320/N321'}
        rate = 200e6;
    case {'N300', 'N310'}
        rate = 125e6;
    otherwise                       % B200, B210
        rate = 32e6;
end
end

function n = local_interp_factor(clockrate, fs, platform)
%LOCAL_INTERP_FACTOR  Interpolation factor giving the wanted baseband rate.
%   A USRP is not told its sample rate directly: the baseband rate is
%   MasterClockRate/InterpolationFactor, so the ratio has to come out as an
%   integer the hardware will actually accept.

n = clockrate / fs;
if abs(n - round(n)) > 1e-6
    error(['A %.4f MHz sample rate does not divide the %.4f MHz master clock ' ...
        'evenly (ratio %.4f). Change usrp_clockrate, or re-capture at a rate ' ...
        'that divides it.'], fs/1e6, clockrate/1e6, n);
end
n = round(n);

% Valid factors: 1-3 (B- and X-series only), 4-128, 128-256 even,
% 256-512 in steps of 4.
if n < 1 || n > 512
    ok = false;
elseif n <= 3
    ok = any(strcmp(platform, {'B200', 'B210', 'X300', 'X310'}));
elseif n <= 128
    ok = true;
elseif n <= 256
    ok = (mod(n, 2) == 0);
else
    ok = (mod(n, 4) == 0);
end

if ~ok
    error(['An interpolation factor of %d is not valid for the %s. Valid ' ...
        'factors are 1-3 (B- and X-series only), 4-128, 128-256 even, and ' ...
        '256-512 in steps of 4. Adjust usrp_clockrate or the capture rate.'], ...
        n, platform);
end
end
