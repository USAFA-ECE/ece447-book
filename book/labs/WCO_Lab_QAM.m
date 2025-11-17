% Follow up to completion of MATLAB Academy Wireless Comm Onramp (WCO)
% course for ECE 348. 
% 
% Goal: Solidify concepts taught in WCO through design of MATLAB-based
% digital communication chain.

%% Options
% Multipath channel or not? 
% 0 = no, just AWGN channel
% 1 = yes, the channel is multipath
hasMP = 1;

%% Set up loop to save BER at various SNRs
SNR=-20:1:40; % range of SNRs in dB to test against
modOrder = [4,16,64,256]; % QAM modulation orders to test against
BER = zeros(length(modOrder),length(SNR)); % initialize BER array for saving values to

for jj=1:length(modOrder)
    for ii=1:length(SNR)
        %% M-QAM over AWGN channel (maybe multipath) with Tx/Rx filtering
        modOrderi = modOrder(jj);  % select modulation order
        bitsPerSymbol = log2(modOrderi);  % modOrder = 2^bitsPerSymbol
        numSym = 10e4; % 100,000 symbols
        numBits = numSym*bitsPerSymbol; % total number of bits
        mpChan = [0.8; zeros(7,1); -0.5; zeros(7,1); 0.34];  % multipath channel
        SNRi = SNR(ii);   % dB, signal-to-noise ratio of AWGN

        % Create matched Tx and Rx pulse-shaping filters
        txFilt = comm.RaisedCosineTransmitFilter;
        rxFilt = comm.RaisedCosineReceiveFilter;
        
        % Create the source bit sequence and modulate using M-QAM
        srcBits = randi([0,1],numBits,1);
        qamModOut = qammod(srcBits,modOrderi,"InputType","bit",...
            "UnitAveragePower",true);
        txFiltOut = txFilt(qamModOut); % filter QAM signal before transmitting
   
        %% Signal sent over AWGN (and possibly multipath) channel
        if hasMP % multipath channel
            % Add multipath effects to channel using mpChan vector 
            mpChanOut = filter(mpChan,1,txFiltOut); 
            % Add AWGN to the channel based on provided SNR in dB
            chanOut = awgn(mpChanOut,SNRi,"measured");
        
        else % no multipath, just AWGN channel
            % Add AWGN to the channel based on provided SNR in dB
            chanOut = awgn(txFiltOut,SNRi,"measured");
        
        end % end hasMP if statement

        %% Demodulate QAM symbols and plot output
        rxFiltOut = rxFilt(chanOut);
        % scatterplot(rxFiltOut)
        % title("Receive Filter Output")
        qamDemodOut = qamdemod(rxFiltOut,modOrderi,"OutputType","bit","UnitAveragePower",true);
        
        % Calculate the BER
        delayInSymbols = txFilt.FilterSpanInSymbols/2 + rxFilt.FilterSpanInSymbols/2;
        delayInBits = delayInSymbols * bitsPerSymbol;
        srcAligned = srcBits(1:(end-delayInBits));
        demodAligned = qamDemodOut((delayInBits+1):end);
    
        numBitErrors = nnz(srcAligned~=demodAligned);
        BER(jj,ii) = numBitErrors/length(srcAligned);
    end
end

figure
semilogy(SNR,BER);
if hasMP % change title based on whether multipath channel or not
    title('BER vs SNR for Various QAM Formats, AWGN Multipath Channel');
else
    title('BER vs SNR for Various QAM Formats, AWGN Channel with No Multipath');
end
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
legend('4-QAM','16-QAM','64-QAM','256-QAM','Location', 'best');
grid on;

% Set y-axis scale
ylim([1e-6 1]);

if hasMP % plots transmitted signal and channel in frequency domain for 256-QAM at SNR = 40dB (the last parameters ran in the for loops)
    specAn = spectrumAnalyzer("NumInputPorts",2, ...
        "SpectralAverages",50,...
        "ShowLegend",true);
    specAn(txFiltOut,chanOut)
end