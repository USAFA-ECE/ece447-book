%% ECE447 - Lab 1: capture a real FM broadcast, then loop-transmit it in class
%
% Fairchild Hall blocks broadcast FM almost completely, so students cannot find
% a live FM station from inside the classroom. This script lets the instructor
% record a few seconds of a real broadcast once, then replay it on a continuous
% loop from an ADALM-PLUTO, giving the whole class a genuine FM signal to tune
% to during Lab 1, Activity 1 - without anyone leaving the room.
%
% HOW TO USE
%   1) CAPTURE. Near a window or outside (the southeast corner of Fairchild
%      works well), plug in the RTL-SDR, set mode = 'capture', and run. The
%      script records a few seconds of a strong local station, saves it, and
%      plots the spectrum so you can confirm you actually caught the signal.
%
%   2) TRANSMIT. Back in the classroom, plug in the ADALM-PLUTO, set
%      mode = 'transmit', and run. The PLUTO loops the recording until stopped.
%      Announce tx_freq to the class.
%          to stop:  release(obj_pluto)
%
% BEFORE YOU TRANSMIT: set tx_freq to a frequency your unit is authorised to
% transmit on (the same one you announce for the Lab 6-8 PLUTO transmissions is
% a good choice), and keep tx_gain low - the signal only has to cross a
% classroom. Do not simply rebroadcast on the station's own frequency.

%% PARAMETERS
mode                = 'capture';    % 'capture' to record, 'transmit' to replay

rtlsdr_id           = '0';          % RTL-SDR ID
rtlsdr_station      = 98.1e6;       % strong local FM station to record, in Hz
rtlsdr_gain         = 30;           % RTL-SDR tuner gain in dB
rtlsdr_frmlen       = 2^18;         % RTL-SDR output data frame size

pluto_id            = 'usb:0';      % ADALM-PLUTO ID
tx_freq             = 915e6;        % <<< SET THIS: PLUTO transmit frequency, Hz
tx_gain             = -30;          % PLUTO transmit gain in dB (-89.75 to 0),
                                    %   start low and raise only as needed

fs                  = 1e6;          % sample rate in Hz - valid for BOTH radios
                                    %   (RTL-SDR 0.9-3.2 MHz, PLUTO >= ~0.52 MHz)
capture_secs        = 2;            % seconds to record. The whole clip is held
                                    %   in the PLUTO's buffer and looped, so keep
                                    %   it short; shrink this if transmitRepeat
                                    %   complains about the buffer size.
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

        % scale to just under full scale so the PLUTO does not clip
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

        % adalm-pluto object
        obj_pluto = sdrtx('Pluto',...
            'RadioID', pluto_id,...
            'CenterFrequency', tx_freq,...
            'BasebandSampleRate', rec.fs,...
            'Gain', tx_gain);

        % hand the clip to the radio, which repeats it from its own buffer
        transmitRepeat(obj_pluto, double(rec.iq));

        fprintf('Transmitting on a loop at %.2f MHz (gain %g dB).\n', ...
            tx_freq/1e6, tx_gain);
        fprintf('Announce %.2f MHz to the class. To stop:  release(obj_pluto)\n', ...
            tx_freq/1e6);

        % If transmitRepeat rejects the buffer size, either reduce capture_secs
        % and re-capture, or stream it from MATLAB instead:
        %     while true
        %         obj_pluto(double(rec.iq));
        %     end

    otherwise
        error('mode must be ''capture'' or ''transmit''.');

end
