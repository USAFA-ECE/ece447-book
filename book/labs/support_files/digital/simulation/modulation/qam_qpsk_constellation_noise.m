%% ECE447 Lab 3, Activity 3 - Constellations under noise
%
% Sends random symbols through an AWGN channel and plots the transmitted and
% received constellations for 16-QAM and QPSK at the SAME noise level, so you
% can compare directly how much noise each one tolerates.
%
% HOW TO USE
%   1. Run as-is and look at the two received constellations.
%   2. Lower EbNo_dB (more noise), re-run, and watch the clusters spread.
%   3. Find the value where 16-QAM starts making symbol errors but QPSK does
%      not - that gap is the whole point of the exercise.

%% PARAMETERS  (this is the knob to turn)
EbNo_dB = 15;        % <-- lower this for more noise (try 15, 10, 8, 5)
nSym    = 5000;      % symbols to simulate

%% RUN BOTH MODULATIONS
orders = [16 4];                 % 16-QAM, then QPSK (4-QAM)
names  = {'16-QAM','QPSK'};

figure('Name','Constellations under AWGN','Color','w');

for k = 1:numel(orders)
    M   = orders(k);
    bps = log2(M);                                   % bits per symbol

    data = randi([0 M-1], nSym, 1);                  % random symbols
    tx   = qammod(data, M, 'gray', 'UnitAveragePower', true);

    % Eb/No -> SNR per symbol.  'measured' makes awgn scale to the actual
    % signal power, so both modulations really do see the same Eb/No.
    snr_dB = EbNo_dB + 10*log10(bps);
    rx     = awgn(tx, snr_dB, 'measured');

    % how many symbols did the noise actually push into the wrong region?
    demod  = qamdemod(rx, M, 'gray', 'UnitAveragePower', true);
    nErr   = sum(demod ~= data);

    subplot(1,2,k);
    plot(real(rx), imag(rx), '.', 'MarkerSize', 4); hold on;
    plot(real(qammod((0:M-1).', M, 'gray', 'UnitAveragePower', true)), ...
         imag(qammod((0:M-1).', M, 'gray', 'UnitAveragePower', true)), ...
         'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
    axis square; grid on; axis([-1.6 1.6 -1.6 1.6]);
    xlabel('In-phase (I)'); ylabel('Quadrature (Q)');
    title(sprintf('%s at E_b/N_0 = %g dB\n%d of %d symbols wrong (%.2f%%)', ...
                  names{k}, EbNo_dB, nErr, nSym, 100*nErr/nSym));
    legend('received','ideal points','Location','southoutside');
end

fprintf('\nE_b/N_0 = %g dB\n', EbNo_dB);
fprintf('Red crosses are the ideal symbol locations; blue dots are what arrived.\n');
fprintf('Lower EbNo_dB and re-run to add noise.\n');
