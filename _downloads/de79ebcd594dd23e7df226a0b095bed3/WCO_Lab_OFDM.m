% Follow up to completion of MATLAB Academy Wireless Comm Onramp (WCO)
% course for ECE 348. 
% 
% Goal: Solidify concepts taught in WCO through design of MATLAB-based
% digital communication chain.

%% Options
% What level of CSI knowledge does the Rx have? The CSI at the Rx is used
% for equalization, and if the CSI is corrupted (e.g., through incorrect
% channel measurements), it affects the system's ability to perform at the
% intended level.
% 1 - Rx has perfect CSI knowledge, so perfect equalization can occur
% 2 - Rx has almost perfect CSI knowledge with only one path incorrect
% 3 - Small amount of noise added to each multipath component of the channel
% 4 - No CSI knowledge at Rx
RxCSI = 4;
noiseAmp = 0.05; % Set amplitude of noise corrupting CSI at Rx

%% Set up loop to save BER at various SNRs
SNR=-20:0.5:40; % range of SNRs in dB to test against
modOrder = [4,16,64,256]; % range of QAM modulation orders to test against
BER = zeros(length(modOrder),length(SNR)); % initialize BER array for saving values

for jj=1:length(modOrder)
    for ii=1:length(SNR)
        %% OFDM transmission using 16-QAM over AWGN, multipath channel with equalization at the receiver
        modOrderi = modOrder(jj);  % select modulation order
        bitsPerSymbol = log2(modOrderi);  % modOrder = 2^bitsPerSymbol
        mpChan = [0.8; zeros(7,1); -0.5; zeros(7,1); 0.34];  % multipath channel
        SNRi = SNR(ii);   % dB, signal-to-noise ratio of AWGN
        
        % Set number of OFDM subcarriers
        numCarr = 2^16;
        numBits = numCarr*bitsPerSymbol;
        
        % Create the source bit sequence and modulate using 16-QAM
        srcBits = randi([0,1],numBits,1);
        qamModOut = qammod(srcBits,modOrderi,"InputType","bit",...
            "UnitAveragePower",true);
   
        % Generate OFDM symbols
        cycPrefLen = 32; % Set cyclic prefix length
        ofdmModOut = ofdmmod(qamModOut,numCarr,cycPrefLen);
        
        %% Signal sent over AWGN, multipath channel
        % Start CSI options
        if RxCSI == 1 % Rx has perfect CSI
            % Add multipath effects to channel using mpChan vector 
            mpChanOut = filter(mpChan,1,ofdmModOut); 
            % Get multipath channel transfer function (taking Fourier
            % transform of multipath channel impulse response returns
            % frequency domain transfer function -- necessary since
            % equalization happens in frequency domain)
            mpChanFreq = fftshift(fft(mpChan,numCarr));
            plotTitle = 'BER vs SNR for Various QAM Formats using OFDM w/ Perfect CSI';

        elseif RxCSI == 2 % Rx CSI off in only one path of multipath CSI
            % Add multipath effects to channel using mpChan vector 
            mpChanOut = filter(mpChan,1,ofdmModOut); 
            % Add noise to CSI in single path before getting multipath
            % transfer function using FFT
            mpChanNoisy = mpChan; mpChanNoisy(4)=noiseAmp; % changing element 4 of multipath vector
            % Get multipath channel transfer function (taking Fourier
            % transform of multipath channel impulse response returns
            % frequency domain transfer function -- necessary since
            % equalization happens in frequency domain)
            mpChanFreq = fftshift(fft(mpChanNoisy,numCarr));
            plotTitle = 'BER vs SNR for Various QAM Formats using OFDM w/ Almost Perfect CSI';

        elseif RxCSI == 3 % Rx CSI has small noise added in each path
            % Add multipath effects to channel using mpChan vector 
            mpChanOut = filter(mpChan,1,ofdmModOut); 
            % Add noise to CSI in single path before getting multipath
            % transfer function using FFT
            mpChanNoisy = mpChan+noiseAmp*(2*(rand(size(mpChan))-0.5));
            % Get multipath channel transfer function (taking Fourier
            % transform of multipath channel impulse response returns
            % frequency domain transfer function -- necessary since
            % equalization happens in frequency domain)
            mpChanFreq = fftshift(fft(mpChanNoisy,numCarr));
            plotTitle = 'BER vs SNR for Various QAM Formats using OFDM w/ Noisy CSI';

        elseif RxCSI == 4 % Rx has no CSI knowledge
            % Add multipath effects to channel using mpChan vector 
            mpChanOut = filter(mpChan,1,ofdmModOut); 
            % Set multipath channel transfer function to ones, so no
            % equalization occurs
            mpChanFreq = ones(numCarr,1);
            plotTitle = 'BER vs SNR for Various QAM Formats using OFDM w/ No CSI';

        end % end CSI feedback options

        % Add AWGN to the channel based on provided SNR in dB
        chanOut = awgn(mpChanOut,SNRi,"measured");
        
        %% Demodulate OFDM symbols and plot output
        ofdmDemodOut = ofdmdemod(chanOut,numCarr,cycPrefLen);
        % scatterplot(ofdmDemodOut)
        
        % Complete channel equalization
        eqOut = ofdmDemodOut ./ mpChanFreq;
        % scatterplot(eqOut)
        % title("Frequency Domain Equalizer Output")
        
        % Demodulate back into bits, then calculate the BER
        qamDemodOut = qamdemod(eqOut,modOrderi,"OutputType","bit",...
            "UnitAveragePower",true);
        numBitErrors = nnz(srcBits~=qamDemodOut); 
        BER(jj,ii) = numBitErrors/numBits;
    end
end

figure
semilogy(SNR,BER);
title(plotTitle);
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
legend('4-QAM','16-QAM','64-QAM','256-QAM','Location', 'best');
grid on;

% Set y-axis scale
ylim([1e-5 1]);