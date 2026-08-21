# Lab 2: Complex Signals and Spectra

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 5.1-5.2.)

## Overview

Every receiver you built in Lab 1 was secretly working with **complex (I/Q) samples**, even though the spectrum display looked like an ordinary real-valued plot. This lab makes that explicit: you'll see why real signals produce mirror-image (symmetric) spectra, why complex signals don't, and why that distinction matters once your RTL-SDR hands you IQ data instead of a single real-valued stream. Then you'll use a real off-air signal to measure exactly how far off frequency your own dongle is.

```{important}
**Required reading before lab: Sections 5.1 and 5.2 of the SDR textbook.** Activity 1 works straight through the examples from those two sections, and the exercises assume you have read them.
```

## Aims of the Lab

- Derive, from Euler's formula, why a real cosine has a two-sided (mirrored) spectrum while a complex exponential has a one-sided spectrum.
- Read a signal's spectrum four different ways -- magnitude, phase, real part, imaginary part -- and judge which pair actually tells you what you want to know.
- Discover what happens to a spectrum when a tone does not line up with the frequencies the FFT can represent.
- Measure your own RTL-SDR's crystal error against a known off-air transmitter and express it in parts per million.

## Some Math: From Euler's Formula to Complex Baseband

Start with Euler's formula, $e^{j\theta} = \cos\theta + j\sin\theta$. Solving for cosine by combining $e^{j\theta}$ and $e^{-j\theta}$ gives:

$$\cos(2\pi f t) = \frac{1}{2}e^{j2\pi f t} + \frac{1}{2}e^{-j2\pi f t}$$

Read the right-hand side as two counter-rotating phasors, one spinning at $+f$ and one at $-f$, each with half the amplitude. That's exactly why a real-valued tone at frequency $f$ shows up as *two* impulses in its spectrum, at $+f$ and $-f$ — the "mirroring" you'll see in Activity 1 isn't a plotting artifact, it's a direct consequence of the fact that a real signal can only be built from *both* phasors together (cosines and sines are their own complex conjugate pair).

Now build a complex baseband signal directly from an in-phase and quadrature component, $I(t) = A\cos(2\pi f t)$ and $Q(t) = A\sin(2\pi f t)$:

$$s(t) = I(t) + jQ(t) = A\cos(2\pi f t) + jA\sin(2\pi f t) = Ae^{j2\pi f t}$$

by Euler's formula again — but this time there's only *one* phasor, spinning at $+f$. No $-f$ term exists to cancel or reinforce it. This is exactly how your RTL-SDR's quadrature downconverter produces a complex baseband signal from real RF.

### Frequency error in parts per million

In Activity 2 you'll measure your dongle's tuning error. Because that error comes from a crystal oscillator, it scales with the frequency you ask for: a crystal that runs 20 parts per million fast is off by 20 Hz at 1 MHz, but by about 3.2 kHz at 162 MHz. So the error is quoted as a *fraction* rather than a fixed number of hertz:

$$\text{ppm} = \frac{\Delta f}{f_c}\times 10^{6}$$

where $\Delta f$ is the measured error in hertz and $f_c$ is the frequency you tuned to. Correcting it is the phasor multiplication from above,

$$s(t)\cdot e^{-j2\pi \Delta f t} = Ae^{j2\pi f t}e^{-j2\pi \Delta f t} = Ae^{j2\pi (f-\Delta f)t}$$

which slides the spectrum back where it belongs. Your RTL-SDR does this for you once you hand it a ppm value.

## Activity 1: Real vs. Complex Spectra

All four exercises use scripts in the `complex/` folder of the course support files. Each one runs as-is — your job is to read the plots, not to write code.

### Exercise 1: A real signal, one side of the spectrum

1. Open and run `complex/time_to_frequency_domain_cosines1.m`. It builds one signal from three real cosines (100, 200, and 300 Hz, with amplitudes 10, 1, and 4) and plots the time-domain waveform and its magnitude spectrum.
2. In the time-domain plot, confirm you cannot pick out the three tones by eye — the sum just looks like a complicated wiggle. This is the whole reason we go to the frequency domain.
3. In the magnitude spectrum, confirm you see exactly three spikes, at 100, 200, and 300 Hz, with heights in the ratio 10 : 1 : 4. Note that the plot only shows you frequencies from 0 to 400 Hz.
4. Look at the line that builds the frequency axis, `f = (0:Nfft-1)/Nfft*fs`. It runs from 0 all the way up to $f_s$, not from $-f_s/2$ to $+f_s/2$ — the plot's axis limits are simply hiding everything above 400 Hz. Predict what is living up in the part of the axis you cannot see. Exercise 2 will show you.

```{tip}
If you would rather see this built as a block diagram than as a script, open the Simulink equivalent, `complex/time_to_frequency_domain_cosines2.slx`. It is optional -- it produces the same result a different way.
```

### Exercise 2: The other half of the spectrum

1. Open and run `complex/time_to_complex_frequency_domain.m`. It uses the same three tones, but adds one function: `fftshift`, which rearranges the FFT output so the frequency axis runs from $-f_s/2$ to $+f_s/2$ with 0 Hz in the middle.
2. Confirm you now see **six** spikes instead of three: at $\pm 100$, $\pm 200$, and $\pm 300$ Hz.
3. Tie this back to the math above. The negative-frequency spikes were always there — Exercise 1 just wasn't plotting that part of the axis. Identify, in this plot, the two counter-rotating phasor terms of the cosine identity, and confirm each is half the height of the single spike you saw in Exercise 1.

### Exercise 3: Four ways to plot the same spectrum

1. Open and run `complex/three_cosines_complex_spectra_plot.m`. This one is different in two ways: the tones now start at different **phase** offsets, and the script plots the spectrum **four** ways — magnitude, phase, the real part, and the imaginary part.
2. Compare the magnitude plot against the real-part and imaginary-part plots. The spikes do not have the same heights, and the energy of a single tone is split across the real and imaginary plots in a way that changes from tone to tone.
3. Now look at the phase plot alongside the magnitude plot, and find where the $\pi/4$ and $\pi/6$ starting phases in the source code show up.
4. **Answer for your write-up:** why do the real/imaginary pair and the magnitude/phase pair look so different, when both are complete descriptions of the very same spectrum? Which pair would you rather hand an engineer who has been asked "which tones are present, and how strong is each one?" — and why?

### Exercise 4: When a tone lands between the cracks

So far every tone has produced one clean spike. Now change that.

1. Go back to `complex/time_to_frequency_domain_cosines1.m` and find the parameters `fs`, `Nfft`, and the three tone frequencies `f1`, `f2`, `f3`.
2. Change `f1` from 100 to **105** Hz. Leave everything else alone. Re-run the script and look carefully at the magnitude spectrum around 105 Hz. Describe exactly what the 105 Hz tone looks like now compared with the 200 and 300 Hz tones, which you did not touch.
3. Try a few more values for `f1` — say 101, 102.5, 107.5, and then to exactly 110. Note which values give you a clean single spike and which do not.
4. Now work out the pattern. Compute $f_s/N_{\text{fft}}$ for this script. Compare that number against the values of `f1` that behaved cleanly and the ones that didn't. What is special about the clean ones?
5. **Answer for your write-up:** state what happened to the spectrum when you moved the tone off 100 Hz, and explain *why* it happened. Your explanation should account for both what you saw at 105 Hz and what you saw at 110 Hz.

```{note}
The signal itself is still a perfect single-frequency cosine in all of these runs -- nothing has been added to it, and nothing is wrong with your dongle or with MATLAB. What changed is the FFT's ability to represent that particular frequency.
```

*For more detail on real vs. complex spectra, see Sec. 5.1-5.2 in SDR textbook.*

## Activity 2: How Far Off Frequency Is Your Dongle?

Your RTL-SDR's tuner is steered by an inexpensive crystal oscillator, so when you ask for a centre frequency you get something a bit different. In Lab 1 that didn't matter much — a wideband FM station is 200 kHz wide, so being a few kHz off still puts the signal on screen. For everything from Lab 5 onward, it matters a great deal.

To measure the error you need a transmitter that is genuinely where it says it is. **NOAA Weather Radio** is ideal: fixed frequencies, nationwide, transmitting 24/7.

```{warning}
**Let your dongle warm up for 15-20 minutes before you measure.** The E4000 tuner drifts significantly as it heats up, so a reading taken the moment you plug in will not be the value you want to keep. Plug in, start the first exercise of Activity 1, and come back to this.
```

### Setup

1. Fit your antenna for this band. A quarter wavelength at 162.5 MHz is about **46 cm** — set your whip to that and give it a ground plane, exactly as in [Lab 1](Lab1), Activity 2.
2. As in Lab 1, you will need a window or the southeast corner of Fairchild for usable reception.
3. Open `complex/rtlsdr_ppm_calibration.m` from the course support files and read the header comments.

### Exercise 1: Measure the error

1. Set `f_nominal` in the script to a NOAA channel. Around Colorado Springs, try **162.550 MHz** first, then **162.475 MHz**. (The full set of channels is 162.400 to 162.550 MHz in 25 kHz steps — if neither of the first two comes in, work along the list.)
2. Leave `ppm_applied = 0` and run the script. It captures live samples, averages the double-sided spectrum you learned to read in Activity 1, finds the carrier, and reports how far that carrier landed from 0 Hz.
3. Look at the plot. You should see a narrow FM voice signal near the centre, with the detected carrier marked. Confirm the detected peak really is the station and not a spur — if the trace looks like noise, check your antenna, your gain, and your location before trusting the number.

```{tip}
NOAA broadcasts continuous synthesised speech. The carrier is cleanest during the short pauses between words, which is why the script averages several spectra rather than taking a single snapshot.
```

### Exercise 2: Apply it and prove it worked

1. Take the ppm value the script prints and put it into `ppm_applied` at the top of the script.
2. Run it again. The carrier should now land very close to 0 Hz and the reported residual error should be far smaller than before.
3. **If the offset got bigger instead of smaller, flip the sign** of your ppm value and run once more. Sign conventions are easy to get backwards; the measurement tells you which way is right.
4. Repeat until the residual is small and stable. **The value in `ppm_applied` at that point is your dongle's calibration figure — record it, and record which NOAA frequency you used.** Write it on your dongle if it is one you keep using.
5. From now on, any script you write can carry this correction by passing it to the receiver:

   ```matlab
   rx = comm.SDRRTLReceiver('0', ...
       'CenterFrequency', 162.550e6, ...
       'SampleRate', 250e3, ...
       'FrequencyCorrection', 27);   % <-- your measured ppm here
   ```

6. Sanity-check the size of your answer against the math above: convert your ppm figure back into an error in hertz at 162.55 MHz, and then work out what that same ppm error would cost you in hertz at 100 MHz.

```{note}
Every dongle is different, and the same dongle will read differently cold than warm. Your number will not match your classmates', and that is the point -- this is a property of the hardware in your hand.
```

```{dropdown} Optional: how MathWorks does it
Communications Toolbox ships an example called [Frequency Offset Calibration for Receivers](https://www.mathworks.com/help/comm/ug/frequency-offset-calibration-for-receivers.html) that performs the same measurement against the pilot tone of a digital television signal instead of a weather station. It is worth reading, but note that it is written around one specific TV channel, so you would need to substitute a physical channel number that is actually on the air locally before it would work here.
```

*For more detail on frequency offset and correction, see Sec. 5.8-5.9 in SDR textbook.*

## Assignment

Submit a single PDF to Gradescope containing:

1. **Activity 1, Exercises 1-2:** your magnitude spectrum from Exercise 1 and your double-sided spectrum from Exercise 2, with 2-3 sentences explaining where the extra three spikes in Exercise 2 came from and why a real-valued signal must have them.
2. **Activity 1, Exercise 3:** the four-plot figure, with your written answer to why the real/imaginary pair and the magnitude/phase pair look so different, and which pair is more useful for identifying the tones in a signal. Justify your choice.
3. **Activity 1, Exercise 4:** a screenshot of the spectrum with `f1 = 105` Hz alongside the original `f1 = 100` Hz spectrum. State what happened to the 105 Hz tone, and explain why it happened and why 110 Hz behaved differently.
4. **Activity 2:** your dongle's measured frequency correction in **ppm**, the NOAA frequency you measured it against, and your before/after plots showing the carrier off centre and then corrected. Include the error in hertz at 162.55 MHz and what the same ppm error would be at 100 MHz.
5. Your documentation statement.
