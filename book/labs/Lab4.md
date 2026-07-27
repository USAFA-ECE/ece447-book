# Lab 4: Frequency Modulation — Receiving Commercial FM Radio

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 9-10.)

## Overview

Commercial FM broadcast is one of the strongest, easiest signals your RTL-SDR can receive, which makes it a great real-world testbed for FM demodulation. Today you'll build an FM receiver, get working mono audio out of a real local station, and then push into stereo decoding. As with Lab 3, we're keeping this receive-only — no PLUTO transmission needed, since there's already a strong, legal, real-world FM signal on the air for you to use.

## Aims of the Lab

- Write down the FM signal equation, its instantaneous frequency, and Carson's Rule for bandwidth — and connect each to something you can see on the spectrum analyzer.
- Understand how a discriminator recovers the message from instantaneous frequency, using the same phase/frequency relationship from Lab 2.
- Build a non-coherent FM discriminator receiver and get real audio out of it.
- Attempt stereo (MPX) decoding on a real broadcast signal, and see DSB-SC coherent detection (Lab 3) reappear inside it.

## Some Math: FM, Carson's Rule, and the Discriminator

An FM signal encodes the message $m(t)$ in the carrier's instantaneous frequency rather than its amplitude:

$$s(t) = A_c \cos\!\left(2\pi f_c t + 2\pi k_f\int_0^t m(\tau)\,d\tau\right), \qquad f_i(t) = f_c + k_f\, m(t)$$

where $f_i(t)$ is the instantaneous frequency and $k_f$ is the frequency sensitivity (Hz per unit of $m(t)$). Because the *amplitude* $A_c$ never changes, amplitude noise and fading — which directly corrupt AM — mostly don't touch the information here, which is the whole reason FM sounds cleaner than AM in the presence of noise.

Peak frequency deviation is $\Delta f = k_f \max|m(t)|$. **Carson's Rule** estimates the transmission bandwidth from that deviation and the highest message frequency $f_m$:

$$B_T \approx 2(\Delta f + f_m)$$

For commercial WFM, $\Delta f \approx 75\text{ kHz}$ and $f_m \approx 15\text{ kHz}$ (plus multiplex content, in practice), giving the roughly 200 kHz channel width you'll measure on the spectrum analyzer in Activity 2 — go ahead and check your measured bandwidth against this estimate.

The **discriminator** recovers $m(t)$ by exploiting the same phase/frequency relationship you used for frequency correction in Lab 2: instantaneous frequency is the derivative of instantaneous phase, $f_i(t) = \frac{1}{2\pi}\frac{d\theta(t)}{dt}$, so differentiating the received phase and subtracting $f_c$ recovers $k_f m(t)$ directly. In discrete time, this derivative is approximated by comparing each complex baseband sample to the previous one:

$$\hat{m}[n] \propto \angle\big(x[n]\,x^*[n-1]\big)$$

(the angle of one sample times the conjugate of the last one) — this is literally the block computation your discriminator model performs, sample by sample, with no local oscillator or carrier recovery required.

## Activity 1: FM Basics on the Spectrum Analyzer

> **Set up your antenna and your location first.** This whole lab runs on real off-air FM, and Fairchild's interior blocks it — head for a window or the southeast corner of the building, as in [Lab 1](Lab1). Set your whip to a quarter wavelength for the FM band — about **77 cm** at 98 MHz — and give it a ground plane, either a magnetic base on a large metal surface or three or four radials cut to that same length. See Lab 1, Activity 2, step 1 if you need the details again.

1. Tune to a strong local FM station using the spectrum tools from Lab 1.
2. Measure its occupied bandwidth directly off the spectrum display.
3. Compare your measurement against the Carson's Rule estimate above ($\Delta f \approx 75$ kHz, $f_m \approx 15$ kHz).
4. Note how much wider the FM signal is than the DSB-LC Air Band signal from Lab 3 — this is why your RTL-SDR's ~1.8-2.4 MHz sample rate only fits a handful of FM stations at once.

*For more detail on FM bandwidth, see Sec. 9.3 in SDR textbook.*

## Activity 2: Mono FM Reception

1. Open `fm/rtlsdr_rx/rtlsdr_fm_discrim_demod.slx`. This implements the discriminator equation above.
2. Tune to a strong local FM station and confirm you get clean mono audio out of your computer's speakers.
3. If you'd rather work from a MATLAB script, step through `fm/rtlsdr_rx/rtlsdr_fm_discrim_demod_matlab.m`, which implements the same receiver without Simulink.

*For more detail on the discriminator and mono FM reception, see Sec. 9.6-9.7 and 10.2 in SDR textbook.*

## Activity 3: Stereo Decoding

Most FM stations broadcast in stereo using a multiplexed (MPX) baseband:

$$m_{MPX}(t) = (L+R)(t) \;+\; \underbrace{A_p\cos(2\pi \cdot 19\text{kHz}\cdot t)}_{\text{pilot}} \;+\; (L-R)(t)\cos(2\pi \cdot 38\text{kHz}\cdot t)$$

That last term should look familiar: $(L-R)(t)$ riding on a 38 kHz subcarrier is exactly a **DSB-SC** signal, the same as in Lab 3. The 19 kHz pilot tone exists purely so the receiver can double it to regenerate a phase-locked 38 kHz reference for coherent detection — solving the exact "you need the transmitter's carrier phase" problem from Lab 3's DSB-SC math, without needing to send the full-power 38 kHz carrier itself.

1. Open `fm/rtlsdr_rx/rtlsdr_fm_discrim_stereo_demod.slx` and see if you can separate left and right channels on your station.
2. Stereo separation is more sensitive to signal strength than mono — if you're not getting clean separation, try `fm/rtlsdr_rx/rtlsdr_fm_pll_stereo_demod.slx` or `fm/rtlsdr_rx/rtlsdr_fm_slope_stereo_demod.slx`, which use different techniques to lock onto the pilot tone.
3. You don't need to understand the internals of all three — just compare which one works best on your captured signal.

*For more detail on stereo MPX transmission and reception, see Sec. 10.3-10.4 in SDR textbook.*

## Assignment

Submit a single PDF to Gradescope containing:

1. A screenshot of your mono FM receiver's spectrum and a short note confirming you heard clean audio, with the station frequency.
2. A screenshot of your stereo decoding attempt, and 2-3 sentences on whether you achieved clean L/R separation and, if not, what you think limited it (signal strength, multipath, etc.).
3. Your documentation statement.
