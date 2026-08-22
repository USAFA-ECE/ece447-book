# Lab 2: Complex Signals and Spectra

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 5.1-5.2.)

```{note}
**Updating your support files.** Lab 2 uses one script that was added after the
Lab 1 download: `rtlsdr_ppm_calibration.m`. If you already unzipped the support
files for Lab 1, you do not need to download the whole package again -- just grab
[**rtlsdr_ppm_calibration.m**](support_files/complex/rtlsdr_ppm_calibration.m)
and save it into your support files at `support_files/complex/rtlsdr_ppm_calibration.m`
-- the `complex` folder you already have, next to `three_cosines_complex_spectra_plot.m`.

Everything else you need for this lab is already in the copy you downloaded. If
you would rather start fresh, the full [support_files.zip](support_files.zip) on
the [Downloads](../downloads.md) page already contains it.
```

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
4. **Put all four spectrum plots in a single figure.** As written, the script scatters them: `figure(502)` holds the magnitude, `figure(503)` the phase, and `figure(504)` the real and imaginary parts as a 2x1 subplot. Edit the script so all four land in one figure as a 2x2 grid — that is, replace those three `figure(...)` calls with a single figure and four `subplot(2,2,n)` calls, keeping each plot's own `title`, `xlabel`, `ylabel`, and `axis` line. Copy that one combined figure into your write-up.
5. **Answer for your write-up:** why do the real/imaginary pair and the magnitude/phase pair look so different, when both are complete descriptions of the very same spectrum? Which pair would you rather hand an engineer who has been asked "which tones are present, and how strong is each one?" — and why?

### Exercise 4: When a tone lands between the cracks

So far every tone has produced one clean spike. Now change that.

1. Go back to `complex/time_to_frequency_domain_cosines1.m` and find the parameters `fs`, `Nfft`, and the three tone frequencies `f1`, `f2`, `f3`.
2. Change `f1` from 100 to **105** Hz. Leave everything else alone. Re-run the script and look carefully at the magnitude spectrum around 105 Hz. Describe exactly what the 105 Hz tone looks like now compared with the 200 and 300 Hz tones, which you did not touch.
3. Try a few more values for `f1` — say 101, 102.5, 107.5, and then to exactly 110. Note which values give you a clean single spike and which do not.
4. Now work out the pattern. Compute $f_s/N_{\text{fft}}$ for this script. Compare that number against the values of `f1` that behaved cleanly and the ones that didn't. What is special about the clean ones?
5. Copy the magnitude spectrum figure for `f1 = 105` Hz, and the one for the original `f1 = 100` Hz, into your write-up so the two sit side by side. Two copied figures, nothing else — no screenshots.
6. **Answer for your write-up:** state what happened to the spectrum when you moved the tone off 100 Hz, and explain *why* it happened. Your explanation should account for both what you saw at 105 Hz and what you saw at 110 Hz.

```{note}
The signal itself is still a perfect single-frequency cosine in all of these runs -- nothing has been added to it, and nothing is wrong with MATLAB. What changed is the FFT's ability to represent that particular frequency.
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

```{note}
The RTL2832U chip only accepts sample rates of 225-300 kHz or 0.9-3.2 MHz, so the script cannot simply ask the hardware for a narrow rate. It captures at 240 kHz and then low-pass filters and decimates by 5 in software, giving a 48 kHz baseband. That is why the spectrum you get spans only ±24 kHz -- wide enough to hold a ~16 kHz narrowband FM signal comfortably, narrow enough to actually see its shape.
```

### Exercise 1: Measure the error

1. Set `f_nominal` in the script to a NOAA channel. Around Colorado Springs, try **162.475 MHz** first, then **162.550 MHz**. (The full set of channels is 162.400 to 162.550 MHz in 25 kHz steps — if neither of the first two comes in, work along the list.)
2. Leave `ppm_applied = 0` and run the script. It captures five seconds of the station, demodulates it, and **plays the audio through your speakers** — listen for the synthesised weather voice. That is your proof you are actually on the station before you trust any number it prints.
3. Once playback finishes, the script averages the double-sided spectrum you learned to read in Activity 1, finds the carrier, and reports how far that carrier landed from 0 Hz — in hertz, and as a ppm figure.
4. Look at the plot. Because the script narrows the view to ±24 kHz, you can see the shape of the narrowband FM signal itself rather than a spike lost in a wide empty span. Confirm the detected peak really is the station and not a spur — if you heard nothing and the trace looks like noise, check your antenna, your gain, and your location before trusting the number.
5. **Copy this plot into your write-up** (Edit > Copy Figure, not a screenshot). It is your "before" figure, and it should clearly show the carrier sitting off centre. Note the ppm value the script reports.

```{tip}
NOAA broadcasts continuous synthesised speech. The carrier is cleanest during the short pauses between words, which is why the script averages several spectra rather than taking a single snapshot.
```

### Exercise 2: Apply it and prove it worked

1. Take the ppm value the script reported and type it into `ppm_applied` at the top of the script.
2. Run it again. The script now spins the samples by that much before measuring, using the $s(t)\,e^{-j2\pi \Delta f t}$ phasor from the maths section. The carrier should land very close to 0 Hz, and the "error still left" figure should be a small fraction of what it was.
3. **Copy this plot into your write-up too**, the same way. It is your "after" figure. The title records the correction that was applied, so the two plots tell the story on their own.
4. If the offset got *bigger* instead of smaller, flip the sign of your ppm value and run once more.
5. **The value now in `ppm_applied` is your dongle's calibration figure — record it, along with which NOAA frequency you measured it against.** Write it on your dongle if it is one you keep using.
6. Using the ppm relationship from the maths section, work out by hand what your dongle's error amounts to **in hertz at 162.475 MHz**, and what the same ppm error would cost you **in hertz at 100 MHz**. Show the arithmetic.

```{note}
Every dongle is different, and the same dongle will read differently cold than warm. Your number will not match your classmates', and that is the point -- this is a property of the hardware in your hand.
```

```{warning}
The radio object also has a `FrequencyCorrection` property, and you may be tempted to use it instead. It accepts **whole numbers of ppm only**, and on this hardware a correction of a few ppm is often quantised away when the tuner retunes -- you ask for 3 ppm and the carrier does not move. Correcting in software, as this script does, avoids both problems.
```

```{dropdown} Optional: how MathWorks does it
Communications Toolbox ships an example called [Frequency Offset Calibration for Receivers](https://www.mathworks.com/help/comm/ug/frequency-offset-calibration-for-receivers.html) that performs the same measurement against the pilot tone of a digital television signal instead of a weather station. It is worth reading, but note that it is written around one specific TV channel, so you would need to substitute a physical channel number that is actually on the air locally before it would work here.
```

*For more detail on frequency offset and correction, see Sec. 5.8-5.9 in SDR textbook.*

## Assignment

```{important}
**Copy your figures, do not screenshot them.** For every figure below, use
**Edit > Copy Figure** in the MATLAB figure window (or run `copygraphics(gcf)`
at the command line) and paste it straight into your document. That gives you
the plot at full resolution with the axes, tick labels, and titles sharp.
Phone photographs of a monitor, cropped screen grabs, and blurry captures make
the plots unreadable and will lose credit.
```

Submit a single PDF to Gradescope containing:

1. **Activity 1, Exercises 1-2:** your magnitude spectrum from Exercise 1 and your double-sided spectrum from Exercise 2, with 2-3 sentences explaining where the extra three spikes in Exercise 2 came from and why a real-valued signal must have them.
2. **Activity 1, Exercise 3:** your combined 2x2 figure holding all four spectrum plots, with your written answer to why the real/imaginary pair and the magnitude/phase pair look so different, and which pair is more useful for identifying the tones in a signal. Justify your choice.
3. **Activity 1, Exercise 4:** the two copied spectrum figures — `f1 = 105` Hz and the original `f1 = 100` Hz — placed side by side. State what happened to the 105 Hz tone, and explain why it happened and why 110 Hz behaved differently.
4. **Activity 2:** *your own* dongle's measured frequency correction in **ppm**, and the NOAA frequency you measured it against. Include **both** copied plots -- the first run with the carrier off centre, and the second run with your correction applied and the carrier centred. Then show your arithmetic converting that ppm figure into an error in hertz at 162.475 MHz, and into an error in hertz at 100 MHz.
5. Your documentation statement.
