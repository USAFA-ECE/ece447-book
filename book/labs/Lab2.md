# Lab 2: Complex Signals and Spectra

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 5.1-5.2.)

## Overview

Every receiver you built in Lab 1 was secretly working with **complex (I/Q) samples**, even though the spectrum display looked like an ordinary real-valued plot. This lab makes that explicit: you'll see why real signals produce mirror-image (symmetric) spectra, why complex signals don't, and why that distinction matters once your RTL-SDR hands you IQ data instead of a single real-valued stream.

## Aims of the Lab

- Derive, from Euler's formula, why a real cosine has a two-sided (mirrored) spectrum while a complex exponential has a one-sided spectrum.
- Compare the spectrum of a real-valued signal to the spectrum of a complex-valued signal built from the same information.
- Observe frequency offset in a live RTL-SDR capture (caused by your dongle's crystal drift) and correct it using a complex exponential, and understand the multiplication that performs the correction.

## Some Math: From Euler's Formula to Complex Baseband

Start with Euler's formula, $e^{j\theta} = \cos\theta + j\sin\theta$. Solving for cosine by combining $e^{j\theta}$ and $e^{-j\theta}$ gives:

$$\cos(2\pi f t) = \frac{1}{2}e^{j2\pi f t} + \frac{1}{2}e^{-j2\pi f t}$$

Read the right-hand side as two counter-rotating phasors, one spinning at $+f$ and one at $-f$, each with half the amplitude. That's exactly why a real-valued tone at frequency $f$ shows up as *two* impulses in its spectrum, at $+f$ and $-f$ — the "mirroring" you'll see in Activity 1 isn't a plotting artifact, it's a direct consequence of the fact that a real signal can only be built from *both* phasors together (cosines and sines are their own complex conjugate pair).

Now build a complex baseband signal directly from an in-phase and quadrature component, $I(t) = A\cos(2\pi f t)$ and $Q(t) = A\sin(2\pi f t)$:

$$s(t) = I(t) + jQ(t) = A\cos(2\pi f t) + jA\sin(2\pi f t) = Ae^{j2\pi f t}$$

by Euler's formula again — but this time there's only *one* phasor, spinning at $+f$. No $-f$ term exists to cancel or reinforce it. This is the one-sided spectrum you'll see in Activity 1's third exercise, and it's exactly how your RTL-SDR's quadrature downconverter produces a complex baseband signal from real RF.

Finally, frequency correction (Activity 2) is just multiplying by another phasor:

$$s(t)\cdot e^{-j2\pi \Delta f t} = Ae^{j2\pi f t}e^{-j2\pi \Delta f t} = Ae^{j2\pi (f-\Delta f)t}$$

which shifts your tone from $f$ down to $f - \Delta f$. If $\Delta f$ matches your RTL-SDR's crystal offset exactly, the signal lands back where it should be.

## Activity 1: Real vs. Complex Spectra

1. Run `complex/three_cosines_complex_spectra_plot.m`. This builds a signal from three real cosine tones and plots its spectrum two ways: once as you'd expect from a real signal (mirrored around 0 Hz — each tone appears twice, once positive and once negative frequency), and once treating it as a complex signal. Compare the two plots.
2. Step through `complex/time_to_frequency_domain_cosines1.m` and open `complex/time_to_frequency_domain_cosines2.slx` in Simulink to see the same relationship built up two ways, block by block, rather than in one script.
3. Run `complex/time_to_complex_frequency_domain.m`, which shows how combining two real signals with a 90-degree phase shift (I and Q) produces a spectrum that is *not* mirrored — energy appears only where the real signal actually was, not on both sides. This is exactly the trick your RTL-SDR uses to hand you a usable baseband signal.
4. Connect what you saw back to the math above: identify, in the mirrored plot, the two counter-rotating phasor terms from the cosine identity, and in the non-mirrored plot, explain why only one of them survives.

*For more detail on real vs. complex spectra, see Sec. 5.1-5.2 in SDR textbook.*

## Activity 2: Frequency Offset on a Real Capture

1. Tune your RTL-SDR to the FM station you found in Lab 1.
2. Open `complex/complex_demodulation.slx` and feed it live RTL-SDR data. You may notice the signal isn't perfectly centered where you expect — every RTL-SDR's internal crystal has some small frequency error (typically a few kHz), so your "0 Hz" isn't quite the station's actual center frequency.
3. Open `complex/complex_frequency_correction.slx`. This multiplies your baseband signal by a complex exponential tuned to your dongle's estimated offset, shifting the spectrum back into place.
4. Adjust the correction frequency slider until the signal is centered, and note the offset value you converged on — you'll report this for the assignment.

*For more detail on frequency offset and correction, see Sec. 5.8-5.9 in SDR textbook.*

## Assignment

Submit a single PDF to Gradescope containing:

1. Screenshots of the real-valued (mirrored) and complex-valued (non-mirrored) spectra from Activity 1, with 2-3 sentences explaining in your own words why the complex version isn't symmetric.
2. A before/after screenshot pair from Activity 2 showing your captured signal off-center, then corrected, along with the correction frequency you used.
3. Your documentation statement.
