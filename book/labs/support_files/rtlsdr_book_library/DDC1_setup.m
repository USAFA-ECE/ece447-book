% -------------------------------------------------------------------------
% Script to design filters (and create filter objects) 
% for a Digital Upconverter (DUC) AND Digital Downconverter (DDC). 
%
% Louise Crockett, December 2013 / January 2014.
%
% **-----------------------**
%
% DUC Filter cascade is:
%                      (1) Square Root Raised Cosine        (RRC)
%                      (2) CIC Compensation Filter          (CFIR)
%                      (3) Cascade Integrate Comb Filter    (CIC)
%
% rates (based on initial values in the script):
%
%        1.5625MHz        6.25MHz        12.5MHz            100MHz
%
% input             RRC             CFIR            CIC             output
%                   (^4)            (^2)            (^8)
%
% **-----------------------**
%
% DDC Filter cascade is:
%                      (1) Cascade Integrate Comb Filter    (CIC)
%                      (2) CIC Compensation Filter          (CFIR)
%                      (3) Square Root Raised Cosine        (RRC)
%
% rates (based on initial values in the script):
%
%        100MHz        12.5MHz        6.25MHz            3.125MHz
%
% input             CIC             CFIR            RRC             output
%                   (v8)            (v2)            (v2)
%
%--------------------------------------------------------------------------

%**************************************************************************
% D I G I T A L   U P C O N V E R T E R 
%**************************************************************************

%-----------------------------
% ROOT RAISED COSINE SECTION
%-----------------------------

% Original data rate is 1.5625 MSPS. Hence original signal BW is 0.78125 MHz.
% Rolloff factor will increase the BW by that ratio, e.g. with rolloff =
% 0.25, the BW will be 0.78125 * 1.25 = 0.9765625MHz. Call it 1MHz for
% filtering!

RRC_rolloff     = 0.22;     % RRC rolloff factor
RRC_order       = 34;       % RRC order is one less than the filter length.
RRC_L_factor    = 4;        % interpolate by this number in the RRC

% create a SQUARE ROOT RAISED COSINE filter based on the above parameters. 
dRRC = fdesign.pulseshaping(RRC_L_factor,'Square Root Raised Cosine','N,Beta',RRC_order,RRC_rolloff);
hRRCtemp = design(dRRC, 'SystemObject',true);
hRRC = dsp.FIRInterpolator(RRC_L_factor, hRRCtemp.Numerator);

%---------------------------------------------------------------
% CIC COMPENSATION (CFIR) SECTION
% (Note: some parameters belong to the CIC being compensated.)
%---------------------------------------------------------------

CFIR_L_factor       = 2;        % interpolation factor of CFIR
CIC_D               = 1;        % differential delay of CIC
CIC_N               = 5;        % number of stages in CIC
CIC_R               = 8;        % interpolation factor of CIC
CFIR_Fp             = 1e6;      % passband edge frequency of CFIR
CFIR_Fst            = 2e6;      % stopband edge frequency of CFIR
CFIR_Ap             = 0.2;      % passband ripple of CFIR (in dB)
CFIR_Ast            = 80;       % stopband attenuation of CFIR (in dB)
CFIR_Fs             = 12.5e6;   % OUTPUT (interpolated) sampling frequency of CFIR

% create a CIC COMPENSATION FILTER based on the above parameters
dCFIR = fdesign.interpolator(CFIR_L_factor,'ciccomp', CIC_D, CIC_N, CIC_R, ...
	'Fp,Fst,Ap,Ast', ...
	CFIR_Fp, CFIR_Fst, CFIR_Ap, CFIR_Ast, CFIR_Fs);
hCFIR = design(dCFIR,'equiripple','SystemObject',true);

% create a CFIR SCALING FACTOR OBJECT
% (NOTE: the coefficients are scaled to prevent loss of signal power due to
% insertion of zero samples - this requires correction for convenient 
% plotting of the spectrum.)
K_cfir = 1/CFIR_L_factor;        % gain compensation value
hKcfir = K_cfir;
%--------------
% CIC SECTION
%--------------

CIC_Fs              = 100e6;    % OUTPUT (interpolated) sampling frequency of CIC
CIC_iwl             = 10;       % CIC input

% create a CIC filter object
% NOTE: Using this command requires the Fixed-Point Designer add-on.
%       The coefficients are provided here so that the CIC filter may 
%       be interpreted as an FIRInterpolator object and be ran without
%       the add-on. If you wish to edit the parameters of this script 
%       then you will require this add-on
% hCIC = dsp.CICInterpolator(CIC_R, CIC_D, CIC_N);%, 10, CIC_Fs);
% hCIC_coeff = impz(hCIC); % Get the coefficients of the CIC filter

hCIC_coeff = [0;0;0;0;0;1;5;15;35;70;126;210;330;490;690;926;1190;1470;1750;2010;2226;2380;2460;2460;2380;2226;2010;1750;1470;1190;926;690;490;330;210;126;70;35;15;5;1];
hCIC = dsp.FIRInterpolator(CIC_R, hCIC_coeff);  

% create a CIC scaling factor object
K_cic = 1/(CIC_R^CIC_N);        % gain compensation value
hK = K_cic;

%------------------
% CASCADE SECTION
%------------------

% create a cascade of the objects
hCIChK = dsp.FilterCascade(hCIC,hK);                    % CIC with scaling applied
hCFIRhKcfir = dsp.FilterCascade(hCFIR,hKcfir);          % CFIR with scaling applied
hCASC = dsp.FilterCascade(hRRC,hCFIR,hKcfir,hCIC,hK);   % cascade of all filters and scalings

%**************************************************************************
% D I G I T A L   D O W N C O N V E R T E R 
%**************************************************************************

%---------------------------------------------------------------
% CIC COMPENSATION (CFIR) SECTION
% (Note: some parameters belong to the CIC being compensated.)
%---------------------------------------------------------------

D_CFIR_M_factor       = 2;        % decimation factor of CFIR
D_CIC_D               = 1;        % differential delay of CIC
D_CIC_N               = 5;        % number of stages in CIC
D_CIC_R               = 4;        % decimation factor of CIC
D_CFIR_Fp             = 1e6;      % passband edge frequency of CFIR
D_CFIR_Fst            = 2e6;      % stopband edge frequency of CFIR
D_CFIR_Ap             = 0.2;      % passband ripple of CFIR (in dB)
D_CFIR_Ast            = 80;       % stopband attenuation of CFIR (in dB)
D_CFIR_Fs             = 12.5e6;   % OUTPUT (decimated) sampling frequency of CFIR

% create a CIC COMPENSATION FILTER based on the above parameters
D_dCFIR = fdesign.decimator(D_CFIR_M_factor,'ciccomp', D_CIC_D, D_CIC_N, D_CIC_R, ...
	'Fp,Fst,Ap,Ast', ...
	D_CFIR_Fp, D_CFIR_Fst, D_CFIR_Ap, D_CFIR_Ast, D_CFIR_Fs);
D_hCFIR = design(D_dCFIR,'equiripple','SystemObject',true);

%--------------
% CIC SECTION
%--------------

D_CIC_Fs              = 100e6;    % OUTPUT (decimated) sampling frequency of CIC
D_CIC_iwl             = 16;       % CIC input

% create a CIC filter object
% NOTE: Using this command requires the Fixed-Point Designer add-on.
%       The coefficients are provided here so that the CIC filter may 
%       be interpreted as an FIRInterpolator object and be ran without
%       the add-on. If you wish to edit the parameters of this script 
%       then you will require this add-on
% D_hCIC = dsp.CICDecimator(D_CIC_R, D_CIC_D, D_CIC_N);
% D_hCIC_coeff = impz(D_hCIC); % Get the coefficients of the CIC filter

D_hCIC_coeff = [0;0;0;0;0;1;5;15;35;65;101;135;155;155;135;101;65;35;15;5;1];
D_hCIC = dsp.FIRDecimator(D_CIC_R, D_hCIC_coeff);  


% create a CIC scaling factor object
D_K_cic = 1/(D_CIC_R^D_CIC_N);        % gain compensation value
D_hK = D_K_cic;

%-----------------------------
% ROOT RAISED COSINE SECTION
%-----------------------------

% Original data rate is 1.5625 MSPS. Hence original signal BW is 0.78125 MHz.
% Rolloff factor will increase the BW by that ratio, e.g. with rolloff =
% 0.25, the BW will be 0.78125 * 1.25 = 0.9765625MHz. Call it 1MHz for
% filtering!

RRC_rolloff     = 0.22;     % RRC rolloff factor
RRC_order       = 34;       % RRC order is one less than the filter length.
RRC_M_factor    = 4;        % interpolate by this number in the RRC

% create a SQUARE ROOT RAISED COSINE filter based on the above parameters. 
D_dRRC = fdesign.pulseshaping(RRC_M_factor,'Square Root Raised Cosine','N,Beta',RRC_order,RRC_rolloff);
D_hRRCtemp = design(D_dRRC);
D_hRRC = dsp.FIRDecimator(RRC_M_factor, D_hRRCtemp.Numerator);

%------------------
% CASCADE SECTION
%------------------

% create a cascade of the objects
D_hCIChK = dsp.FilterCascade(D_hCIC,D_hK);                    % CIC with scaling applied
D_hCASC = dsp.FilterCascade(D_hCIC,D_hK,D_hCFIR,D_hRRC);   % cascade of all filters and scalings

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
%    Copyright © 2015 Robert W. Stewart, Kenneth W. Barlee, 
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
