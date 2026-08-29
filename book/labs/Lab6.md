# Lab 6: QPSK Transmission and Reception over Real Hardware

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.1-12.3.)

## Overview

Today the classroom becomes a real digital radio link. The instructor's ADALM-PLUTO will transmit a live QPSK signal from the front of the room; every student receives it independently on their own RTL-SDR. This is the same real-hardware chain from Lab 5, but now with an actual live-transmitted signal instead of a recording, and now built to fully synchronize instead of just observing a raw constellation.

**Only the instructor transmits.** We don't have a PLUTO for every student, and HackRF units aren't well-supported for transmit through MATLAB in a way we could reliably get running across a whole class in 53 minutes — so this lab, and Labs 7 and 8, all use one instructor transmitter with the whole class receiving simultaneously.

## Aims of the Lab

- Write down the received-signal model with frequency and phase offset, and use it to explain, in equation terms, why an uncorrected constellation spins.
- Understand, at the level of "what problem does it solve," how coarse frequency estimation and fine carrier/timing tracking each remove one piece of that model.
- Build up a QPSK receiver in three stages and observe what each correction step fixes.

> This lab runs across two class periods: **Day 1** covers Activities 1-2 (raw constellation and coarse frequency correction). **Day 2** covers Activity 3 (full carrier and timing synchronization), which tends to need the most troubleshooting time, plus the write-up.

## Some Math: Why the Raw Constellation Spins

Your RTL-SDR's crystal doesn't sit at exactly the instructor's transmit frequency — call the mismatch $\Delta f$ (typically tens of Hz to a few kHz), and there's also some unknown constant phase offset $\phi$ between transmitter and receiver. Your received baseband samples look like:

$$r[n] = s[n]\, e^{j(2\pi \Delta f\, nT_s + \phi)} + w[n]$$

where $s[n]$ is the transmitted QPSK symbol from Lab 5's mapping, $T_s$ is your sample period, and $w[n]$ is noise. Compare this to the complex-exponential math from Lab 2: the term $e^{j2\pi\Delta f\, nT_s}$ is a phasor whose angle grows linearly with $n$ — so every new sample, the whole constellation rotates a little further. That's exactly the "spinning" you'll see in Activity 1, and it's the same math as Lab 2's frequency correction, just now with an unknown $\Delta f$ that the receiver has to estimate rather than one you dial in by hand.

**Coarse frequency correction** (Activity 2) estimates $\Delta f$ using a trick specific to QPSK: raising each received symbol to the 4th power strips off the modulation. Since the four QPSK phases are 90 degrees apart, $(e^{j(\pi/4+k\pi/2)})^4 = e^{j\pi}$ for every $k$ — a constant, regardless of which symbol was sent. What's left is a pure tone at $4\Delta f$, whose frequency you can read directly off a spectrum analyzer — the same tool from Lab 1 — as wherever its single peak sits, then divide by 4 to recover $\Delta f$. This gets you close, but any residual estimation error still leaves some rotation and blur.

**Fine carrier and timing synchronization** (Activity 3) cleans up what coarse correction leaves behind: a phase-locked loop continuously tracks the small residual $\phi$ error sample-by-sample, while a separate timing error detector nudges when you sample each symbol so you land exactly at the peak of each pulse-shaped symbol — the same Nyquist-criterion peak from Lab 5's pulse shaping. Get both right and the four constellation points stop moving entirely.

## Setup

The instructor will announce a transmit frequency at the start of each class period and run the transmit model that matches the activity you're on, pausing between stages:

**Day 1**
1. `digital/pluto_tx/pluto_QPSK_raised_cosine.slx` — for Activity 1
2. `digital/pluto_tx/pluto_QPSK_coarse_synch.slx` — for Activity 2

**Day 2**
3. `digital/pluto_tx/pluto_QPSK_carrier_timing.slx` — for Activity 3

You'll run the matching receiver model at each stage.

```{note}
If the live signal is weak or breaks up from where you're sitting, there is a recorded capture for **every** stage of this lab so you can still finish — the file list is in Activity 3, step 4. You can fall back at any point, including on Day 1.
```

## Activity 1: Raw Constellation

1. Tune to the announced frequency.
2. Run `digital/rtlsdr_rx/rtlsdr_QPSK_raised_cosine.slx`.
3. With no correction applied, expect the constellation to look rotated, smeared, or slowly spinning — this is the combined effect of your RTL-SDR's crystal frequency offset and unknown symbol timing, both of which Lab 5 warned you about. Confirm you can see this before moving on.

*For more detail on this real-time QPSK receiver model, see Sec. 12.1 in SDR textbook.*

## Activity 2: Coarse Frequency Correction

1. Run `digital/rtlsdr_rx/rtlsdr_QPSK_coarse_synch.slx` once the instructor starts the matching transmitter.
2. Confirm the constellation stops spinning, though it likely still won't be crisp.
3. If a spectrum analyzer view is available in the model, locate the $4\Delta f$ tone described above and connect it back to the 4th-power trick.

*For more detail on coarse frequency synchronization, see Sec. 11.8 and 12.2 in SDR textbook.*

## Activity 3: Full Carrier and Timing Synchronization

1. Run `digital/rtlsdr_rx/rtlsdr_QPSK_carrier_timing.slx`. This adds fine carrier tracking and symbol timing recovery on top of the coarse correction.
2. Confirm you now see four tight, distinct constellation points.
3. If you want additional scope views of the internal tracking loops, open `digital/rtlsdr_rx/rtlsdr_QPSK_carrier_timing_plots.slx`, which adds logging and scope instrumentation on top of the same synchronization chain (it drops the base model's symbol-decision/printout branch, which you don't need just to view the constellation).
4. **If the live transmission is weak or interrupted from your seat in the room**, use the matching recorded capture as a fallback for each stage so you can still complete the assignment: `digital/rtlsdr_rx/rec_data/qpsk_raised_cosine.mat`, `digital/rtlsdr_rx/rec_data/qpsk_coarse_synch.mat`, or `digital/rtlsdr_rx/rec_data/qpsk_carrier_timing.mat`. To switch a receiver model from live hardware to a recorded file, use the same block swap you did in [Lab 5](Lab5), Activity 4.

*For more detail on carrier and timing synchronization, see Sec. 11.5-11.7 and 12.3 in SDR textbook.*

## Assignment

```{important}
**Copy your figures, do not screenshot them.** In a MATLAB figure window use
**Edit > Copy Figure** (or run `copygraphics(gcf)` at the command line). In a
Simulink scope or Spectrum Analyzer, use that scope's own **File > Print to
Figure**, then copy the figure it creates. Paste straight into your document.
That gives you the plot at full resolution with the axes, tick labels, and
titles sharp. Phone photographs of a monitor, cropped screen grabs, and blurry
captures make the plots unreadable.
```

Submit a single PDF to Gradescope containing:

1. Three constellation figures — raw, coarse-corrected, and fully synchronized — clearly labeled.
2. 2-3 sentences for each stage explaining what changed and why (in your own words, not copied from the book).
3. A note on whether you used the live signal or a recorded fallback file, and if the latter, why.
4. Your documentation statement.
