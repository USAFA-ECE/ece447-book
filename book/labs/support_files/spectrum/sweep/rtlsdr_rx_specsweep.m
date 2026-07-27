%RTL-SDR Spectrum Sweep
% - You can use this script to sweep and record the RF spectrum with your
%   RTL-SDR
% - Change the "location" parameter (line 22) to something that identifies
%   your location, eg Glasgow, New York or Sydney
% - You may change range that the RTL-SDR will sweep over by changing the
%   values of "start_freq" and "stop_freq" (lines 23 and 24)
% - If you wish, you can also change the RLT-SDR sampling rate by changing
%   "rtlsdr_fs", and the tuner gain by modifying "rtlsdr_gain" (lines 26
%   and 27)
% - At the end of the simulation, the recorded data will be processed and
%   plotted in a popup figure
% - This figure will be saved to the MATLAB 'current folder' for later
%   viewing
% - NOTE: to end simulation early, use |Ctrl| + |C|

function rtlsdr_rx_specsweep

% PARAMETERS (can change)
location            = 'USAFA_Fairchild_3rdFloorOutside';    % location used for figure name
start_freq          = 80e6;         % requested sweep start (auto-clipped to the detected tuner's usable bands)
stop_freq           = 1750e6;       % requested sweep stop  (auto-clipped to the detected tuner's usable bands)
rtlsdr_id           = '0';          % RTL-SDR stick ID
tuner_name          = 'auto';       % 'auto' detects via sdrinfo; or force 'E4000' / 'R820T'
rtlsdr_fs           = 2.8e6;        % RTL-SDR sampling rate in Hz
rtlsdr_gain         = 40;           % RTL-SDR tuner gain in dB
rtlsdr_frmlen       = 4096;         % RTL-SDR output data frame size
rtlsdr_datatype     = 'single';     % RTL-SDR output data type
rtlsdr_ppm          = 9;            % RTL-SDR tuner parts per million correction
% PARAMETERS (can change, but may break code)
nfrmhold            = 20;           % number of frames to receive
fft_hold            = 'avg';        % hold function "max" or "avg"
nfft                = 4096;         % number of points in FFTs (2^something)
dec_factor          = 16;           % output plot downsample
overlap             = 0.5;          % FFT overlap to counter rolloff
nfrmdump            = 100;          % number of frames to dump after retuning (to clear buffer)

% DETECT TUNER AND SELECT USABLE FREQUENCY BANDS
% Query the connected stick so the same script works on either tuner. The
% E4000 has a hard low-frequency floor (~52 MHz) and a 1100-1250 MHz PLL gap;
% the R820T/R820T2 tunes continuously with no gap. Leave tuner_name = 'auto'
% to detect, or force 'E4000'/'R820T' if sdrinfo is unavailable.
radio_info = sdrinfo(rtlsdr_id);
if isempty(radio_info)
    error(['RTL-SDR not found at ID ''',rtlsdr_id,'''. Check the ',...
        'connection with the "sdrinfo" command.']);
end
if iscell(radio_info)
    radio_info = radio_info{1};                                 % sdrinfo may return a cell array of structs
end
if strcmpi(tuner_name,'auto')
    tuner_name = radio_info(1).TunerName;                       % e.g. 'E4000', 'R820T', 'R820T2'
end
tuner_name = char(tuner_name);                                 % coerce cellstr/string to a char row vector

switch upper(tuner_name)
    case 'E4000'
        % 53-1100 MHz and 1250-2200 MHz (full E4000 range). The 1100-1250 MHz
        % gap is excluded so it is never retuned into.
        usable_bands = [ 53e6 1100e6 ; 1250e6 2200e6 ];
    case {'R820T','R820T2'}
        usable_bands = [ 25e6 1750e6 ];                         % continuous, no gap
    otherwise
        warning(['Unrecognised tuner ''',tuner_name,''' - sweeping the ',...
            'requested range as-is; unlockable retunes will be skipped.']);
        usable_bands = [ start_freq stop_freq ];
end

% CALCULATIONS
% Clip the requested [start_freq stop_freq] window to the tuner's usable
% bands, then build a list of tuner centre frequencies across each surviving
% band (no frequencies are generated inside a gap).
rtlsdr_tunerfreq = [];
band_tune_counts = [];                                          % #tunes per band, for plot line-breaks
for b = 1:size(usable_bands,1)
    band_lo = max(start_freq, usable_bands(b,1));
    band_hi = min(stop_freq,  usable_bands(b,2));
    if band_lo >= band_hi
        continue;                                              % requested window misses this band
    end
    band_freqs = band_lo : rtlsdr_fs*overlap : band_hi;
    if max(band_freqs) < band_hi                               % cover the top edge of the band
        band_freqs(end+1) = max(band_freqs)+rtlsdr_fs*overlap; %#ok<AGROW>
    end
    rtlsdr_tunerfreq = [rtlsdr_tunerfreq, band_freqs];         %#ok<AGROW>
    band_tune_counts = [band_tune_counts, numel(band_freqs)];  %#ok<AGROW>
end
if isempty(rtlsdr_tunerfreq)
    error('Requested %g-%g MHz range does not overlap the %s tuner usable bands.',...
        start_freq/1e6, stop_freq/1e6, tuner_name);
end
nretunes = length(rtlsdr_tunerfreq);                           % number of retunes required

% Build a frequency axis that follows the (possibly non-contiguous) tuner
% frequencies, so any coverage gap shows as a gap in the plot.
freq_bin_width = rtlsdr_fs/nfft;                               % Hz per raw FFT bin
nbins_per_tune = nfft*overlap/dec_factor;                      % output bins per retune
out_bin_width  = freq_bin_width*dec_factor;                    % Hz per output bin
freq_axis = zeros(1, nretunes*nbins_per_tune);
for k = 1:nretunes
    sub = rtlsdr_tunerfreq(k) - rtlsdr_fs*overlap/2 + (0:nbins_per_tune-1)*out_bin_width;
    freq_axis((k-1)*nbins_per_tune + (1:nbins_per_tune)) = sub;
end
freq_axis = freq_axis/1e6;

% create spectrum figure
h_spectrum = create_spectrum;

% run capture and plot
capture_and_plot;

% make spectrum visible
h_spectrum.fig.Visible = 'on';

% save data
filename = ['rtlsdr_rx_specsweep_',num2str(start_freq/1e6),'MHz_',num2str(stop_freq/1e6),'MHz_',location,'.fig'];
savefig(filename);

%% FUNCTION to create spectrum window
    function h_spectrum = create_spectrum
        
        % colours
        h_spectrum.line_blue = [0.0000 0.4470 0.7410];      % spectrum analyzer blue
        h_spectrum.line_orange = [1.0000 0.5490 0.0000];    % spectrum analyzer orange
        h_spectrum.window_grey = [0.95 0.95 0.95];          % background light grey
        h_spectrum.axes_grey = [0.1 0.1 0.1];               % dark grey for axes titles etc
        h_spectrum.plot_white = [1 1 1];                    % white for plot background
        
        % sizes
        fig_w = 1200;
        fig_h = 600;
        scnsize = get(0,'ScreenSize');                      % find monitor 1 size
        if scnsize(3) < fig_w                               % if monitor is not fig_w wide
            fig_w = scnsize(3);                             % reduce fig_w
        end
        if scnsize(4) < fig_h                               % if monitor is not fig_h tall
            fig_h = scnsize(4);                             % reduce fig_h
        end
        fig_pos = [(scnsize(3)-fig_w)/2 (scnsize(4)-fig_h)/2 fig_w fig_h];   % set to open in middle of monitor 1
        
        % create new figure
        h_spectrum.fig = figure(...
            'Color',h_spectrum.window_grey,...
            'Position',fig_pos,...
            'CloseRequestFcn','closereq',...
            'SizeChangedFcn',@resize_spectrum,...
            'Name',['RTL-SDR Spectrum Sweep: ',location],...
            'Visible', 'off');
        h_spectrum.fig.Renderer = 'painters';
        
        % subplot 1
        h_spectrum.axes1 = axes(...
            'Parent',h_spectrum.fig,...
            'YGrid','on','YColor',h_spectrum.axes_grey,...
            'XGrid','on','XColor',h_spectrum.axes_grey,...
            'GridLineStyle','--',...
            'Color',h_spectrum.plot_white);
        box(h_spectrum.axes1,'on');
        hold(h_spectrum.axes1,'on');
        xlabel(h_spectrum.axes1,'Frequency (MHz)');
        ylabel(h_spectrum.axes1,'Power Ratio (dBm)  [relative to 50 \Omega load]  ');
        xlim(h_spectrum.axes1,[freq_axis(1),freq_axis(end)]);
        
        % subplot 2
        h_spectrum.axes2 = axes(...
            'Parent',h_spectrum.fig,...
            'YGrid','on','YColor',h_spectrum.axes_grey,...
            'XGrid','on','XColor',h_spectrum.axes_grey,...
            'GridLineStyle','--',...
            'Color',h_spectrum.plot_white);
        box(h_spectrum.axes2,'on');
        hold(h_spectrum.axes2,'on');
        xlabel(h_spectrum.axes2,'Frequency (MHz)');
        ylabel(h_spectrum.axes2,'Relative Power (Watts)');
        xlim(h_spectrum.axes2,[freq_axis(1),freq_axis(end)]);
        
        % figure title
        title(h_spectrum.axes1,['RTL-SDR Spectrum Sweep (',tuner_name,')   ||   Range = ',...
            num2str(freq_axis(1),'%.1f'),'MHz to ',num2str(freq_axis(end),'%.1f'),...
            'MHz   ||   Bin Width = ',num2str(freq_bin_width*dec_factor/1e3),...
            'kHz   ||   Number of Bins = ',num2str(length(freq_axis)),'   ||   Number of Retunes = ',...
            num2str(nretunes)]);
        
        % position axes
        axes_position(fig_w,fig_h);
        
        % link plots together for zooming
        linkaxes([h_spectrum.axes1,h_spectrum.axes2],'x');
        
    end

%% FUNCTION to calculate axes positions
    function axes_position(fig_w,fig_h)
        
        h_spectrum.axes1.Position = [...        % dBm axes
            70/fig_w,...                        % 70px from left
            (fig_h/2)/fig_h,...                 % at centre line
            (fig_w-100)/fig_w,...               % 100px from right
            (fig_h/2-30)/fig_h];                % 80px from top
        
        h_spectrum.axes2.Position = [...        % Watts axes
            70/fig_w,...                        % 70px from left
            50/fig_h,...                        % 50px from bottom
            (fig_w-100)/fig_w,...               % 100px from right
            (fig_h/2-100)/fig_h];               % 100px below centre line
        
    end


%% FUNCTION (callback) to resize axes in spectrum window
    function resize_spectrum(hObject,callbackdata)
        
        % find current sizes
        fig_w = h_spectrum.fig.Position(3);
        fig_h = h_spectrum.fig.Position(4);
        
        % update axes positions
        axes_position(fig_w,fig_h);
        
    end


%% FUNCTION to capture data from the RTL-SDR and plot it
    function capture_and_plot
        
        % START TIMER
        tic;
        disp(' ');
        
        % SYSTEM OBJECTS
        % RTL-SDR system object
        obj_rtlsdr = comm.SDRRTLReceiver(...
            rtlsdr_id,...
            'CenterFrequency',      rtlsdr_tunerfreq(1),...
            'EnableTunerAGC', 		false,...
            'TunerGain', 			rtlsdr_gain,...
            'SampleRate',           rtlsdr_fs, ...
            'SamplesPerFrame', 		rtlsdr_frmlen,...
            'OutputDataType', 		rtlsdr_datatype ,...
            'FrequencyCorrection', 	rtlsdr_ppm );
        
        % FIR decimator
        obj_decmtr = dsp.FIRDecimator(...
            'DecimationFactor',     dec_factor,...
            'Numerator',            fir1(300,1/dec_factor));
        
        % CALCULATIONS (others)
        rtlsdr_data_fft = zeros(1,nfft);                     % fullsize matrix to hold calculated fft [1 x nfft]
        fft_reorder = zeros(length(nfrmhold),nfft*overlap);  % matrix with overlap compensation to hold re-ordered ffts [navg x nfft*overlap]
        fft_dec = zeros(nretunes,nfft*overlap/dec_factor);   % matrix with overlap compensation to hold all ffts  [ntune x nfft*overlap/data_decimate]
        
        % SIMULATION        
        % check if RTL-SDR is active
        if ~isempty(sdrinfo(obj_rtlsdr.RadioAddress))
        else
            error(['RTL-SDR failure. Please check connection to ',...
                'MATLAB using the "sdrinfo" command.']);
        end
        
        % create progress variable
        tune_progress = 0;
        
        % for each of the tuner values
        for ntune = 1:1:nretunes;
            
            % tune RTL-SDR to new centre frequency and dump frames to clear
            % the software buffer. Tuner gaps are already excluded from
            % rtlsdr_tunerfreq, so this retry only guards against occasional
            % transient USB stalls; anything that still will not lock is
            % skipped (left as a gap) rather than aborting the whole sweep.
            retune_ok = false;
            for attempt = 1:2
                try
                    obj_rtlsdr.CenterFrequency = rtlsdr_tunerfreq(ntune);
                    % dump frames to clear software buffer
                    for frm = 1:1:nfrmdump
                        % fetch a frame from the rtlsdr stick
                        rtlsdr_data = step(obj_rtlsdr);
                    end
                    retune_ok = true;
                    break;
                catch tune_err
                    warning('Retune to %.1f MHz failed (attempt %d/2): %s', ...
                        rtlsdr_tunerfreq(ntune)/1e6, attempt, tune_err.message);
                    % Do NOT release() here: releasing mid-sweep unlocks the
                    % radio, and the next step() then tries to re-create the
                    % driver and fails with "address '0' is already owned",
                    % cascading to every later retune. Keep the object locked
                    % and simply retune again after a short settle.
                    pause(0.2);
                end
            end
            if ~retune_ok
                warning('Skipping %.1f MHz after 2 failed attempts.', ...
                    rtlsdr_tunerfreq(ntune)/1e6);
                fft_dec(ntune,:) = NaN;    % leave a gap instead of crashing
                continue;
            end
            
            % display current centre frequency
            disp(['            fc = ',num2str(rtlsdr_tunerfreq(ntune)/1e6),'MHz']);
            
            % loop for nfrmhold frames
            for frm = 1:1:nfrmhold
                
                % fetch a frame from the rtlsdr stick
                rtlsdr_data = step(obj_rtlsdr);
                
                % remove DC component
                rtlsdr_data = rtlsdr_data - mean(rtlsdr_data);
                
                % find fft [ +ve , -ve ]
                rtlsdr_data_fft = abs(fft(rtlsdr_data,nfft))';
                
                % rearrange fft [ -ve , +ve ] and keep only overlap data
                fft_reorder(frm,( 1 : (overlap*nfft/2) ))      = rtlsdr_data_fft( (overlap*nfft/2)+(nfft/2)+1 : end );   % -ve
                fft_reorder(frm,( (overlap*nfft/2)+1 : end ))  = rtlsdr_data_fft( 1 : (overlap*nfft/2) );                % +ve
                
            end
            
            % process the fft data down to [1 x nfft*overlap/data_decimate] from [nfrmhold x nfft*overlap/data_decimate]
            if strcmp(fft_hold,'avg')
                % if set to average, find mean
                fft_reorder_proc = mean(fft_reorder);
                
            elseif strcmp(fft_hold,'max')
                % if set to max order hold, find max
                fft_reorder_proc = max(fft_reorder);
                
            end
            
            % decimate data to smooth and store in spectrum matrix
            fft_dec(ntune,:) = step(obj_decmtr,fft_reorder_proc')';
            
            % show progress if at an n10% value
            if floor(ntune*10/nretunes) ~= tune_progress;
                tune_progress = floor(ntune*10/nretunes);
                disp(['      progress = ',num2str(tune_progress*10),'%']);
            end
            
        end
        
        % REORDER INTO ONE MATRIX
        fft_masterreshape = reshape(fft_dec',1,nretunes*nbins_per_tune);

        % PLOT DATA
        y_data = fft_masterreshape;
        y_data_dbm = 10*log10((fft_masterreshape.^2)/50);

        % break the plotted line across any coverage gap between bands
        band_edges = cumsum(band_tune_counts);
        for be = 1:numel(band_edges)-1
            gap_idx = band_edges(be)*nbins_per_tune;
            y_data(gap_idx)     = NaN;
            y_data_dbm(gap_idx) = NaN;
        end

        plot(h_spectrum.axes1,freq_axis,y_data_dbm,'Color',h_spectrum.line_blue,'linewidth',1.25);
        plot(h_spectrum.axes2,freq_axis,y_data,'Color',h_spectrum.line_orange,'linewidth',1.25);
        
        % STOP TIMER
        disp(' ');
        disp(['      run time = ',num2str(toc),'s']);
        disp(' ');
        
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Software, Simulation Examples and Design Exercises Licence Agreement  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         
%  This license agreement refers to the simulation examples, design
%  exercises and files, and associated software MATLAB and Simulink
%  resources that accompany the book:
% 
%    Title: Software Defined Radio using MATLAB & Simulink and the RTL-SDR 
%    Published by Strathclyde Academic Media, 2015
%    Authored by Robert W. Stewart, Kenneth W. Barlee, Dale S.W. Atkinson, 
%    and Louise H. Crockett
%
%  and made available as a download from www.desktopSDR.com or variously 
%  acquired by other means such as via USB storage, cloud storage, disk or 
%  any other electronic or optical or magnetic storage mechanism. These 
%  files and associated software may be used subject to the terms of 
%  agreement of the conditions below:
%
%    Copyright � 2015 Robert W. Stewart, Kenneth W. Barlee, 
%    Dale S.W. Atkinson, and Louise H. Crockett. All rights reserved.
%
%  Redistribution and use in source and binary forms, with or without 
%  modification, are permitted provided that the following conditions are
%  met:
%
%   (1) Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%
%   (2) Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the 
%       distribution.
%
%   (3) Neither the name of the copyright holder nor the names of its 
%       contributors may be used to endorse or promote products derived 
%       from this software without specific prior written permission.
%
%   (4) In all cases, the software is, and all modifications and 
%       derivatives of the software shall be, licensed to you solely for
%       use in conjunction with The MathWorks, Inc. products and service
%       offerings.
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
%  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
%  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
%  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
%  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
%  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
%  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
%  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
%  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
%  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
%  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%%  Audio Tracks used in Simulations Examples and Design Exercises
% 
%  The music and vocal files used within the Examples files and software 
%  within the book were variously written, arranged, performed, recorded 
%  and produced by Garrey Rice, Adam Struth, Jamie Struth, Iain 
%  Thistlethwaite and also Marshall Craigmyle who collectively, and 
%  individually where appropriate, assert and retain all of their 
%  copyright, performance and artistic rights. Permission to use and 
%  reproduce this music is granted for all purposes associated with 
%  MATLAB and Simulink software and the simulation examples and design 
%  exercises files that accompany this book. Requests to use the music 
%  for any other purpose should be directed to: info@desktopSDR.com. For
%  information on music track names, full credits, and links to the 
%  musicians please refer to www.desktopSDR.com/more/audio.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%