# Lab 6: QPSK Transmission and Reception over Real Hardware

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.)

## Overview

Today the classroom becomes a real digital radio link. The instructor will transmit a live QPSK signal from the front of the room; every student receives it independently on their own RTL-SDR. This is the same real-hardware chain from Lab 5, but now with an actual live-transmitted signal instead of a recording, and now built to fully synchronize rather than just confirming the signal is there on the spectrum.

**Only the instructor transmits.** We don't have a transmit-capable radio for every student, and getting one working reliably across a whole class in 53 minutes isn't something we could count on — so this lab, and Labs 7 and 8, all use one instructor transmitter with the whole class receiving simultaneously.

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

The instructor will announce a transmit frequency at the start of each class period and transmit the signal for the activity you're on, pausing between stages:

**Day 1** — Activities 1 and 2

**Day 2** — Activity 3

You'll run the matching receiver model at each stage.

```{note}
If the live signal is weak or breaks up from where you're sitting, there is a recorded capture for **every** stage of this lab so you can still finish — the file list is in Activity 3, step 4. You can fall back at any point, including on Day 1.
```

## Activity 1: Acquire the Live Signal

This is the same model you ran on a recording in Lab 5, Activity 4 — now pointed at a live transmission. Its only display is `Spectrum Analyzer Receive`, which shows the signal before and after the matched RRC filter. **There is no constellation diagram in this model**; you get your first constellation in Activity 3.

1. Tune to the announced frequency.
2. Run `digital/rtlsdr_rx/rtlsdr_QPSK_raised_cosine.slx` with the `RTL-SDR Receiver` block active (the reverse of the block swap you did in Lab 5).
3. Find the instructor's signal on the spectrum and adjust `Tuner Gain (dB)` until it stands clearly above the noise floor without flattening off at the top. Getting the gain right here saves you trouble in Activity 3, where the synchronizer will not lock on a signal that is too weak.
4. Note how wide the signal is and where it sits relative to 0 Hz. It will not be exactly centered — that offset is the $\Delta f$ you are about to measure.

*For more detail on this receiver model, see Exercise 12.2 in SDR textbook.*

## Activity 2: Coarse Frequency Correction

1. Run `digital/rtlsdr_rx/rtlsdr_QPSK_coarse_synch.slx` once the instructor starts the matching transmitter.
2. This model has **no constellation diagram either**. What it gives you is `Spectrum Analyzer - Coarse Synch`, carrying three traces that walk through the 4th-power trick from the math section above:
    - **Decimated signal** — the signal as received, sitting off-center by $\Delta f$.
    - **Induced Peak** — the result of raising it to the 4th power. The modulation cancels and you are left with a single tone at $4\Delta f$.
    - **Corrected signal** — the received signal shifted by the estimated offset, now centered on 0 Hz.
3. Find the induced peak and read its frequency. Divide by 4 and compare against the `Calculated Frequency Offset (Hz)` display, which shows what the model's own estimator worked out. They should agree.
4. `Spectrum Analyzer - Received Signal` and `Spectrum Analyzer - RRC Filtered` show earlier points in the chain if you want to trace the signal through.

*For more detail on coarse frequency synchronization, see Exercises 12.3 and 12.4 in SDR textbook.*

## Activity 3: Full Carrier and Timing Synchronization

1. Run `digital/rtlsdr_rx/rtlsdr_QPSK_carrier_timing.slx`. This adds fine carrier tracking and symbol timing recovery on top of the coarse correction. **This is the model with the constellation diagrams** — three of them, tapping the signal at three points in the chain:
    - **`Rx Before AGC`** — straight off the matched filter, before any gain control or synchronization. This is your uncorrected view. Use it to judge signal strength: if the cluster is squeezed tight around the origin or sprawling off the edges, change `Tuner Gain (dB)` and re-run, because the synchronizer will struggle at either extreme.
    - **`Rx Timing`** — after AGC and symbol timing recovery. You should see four clusters here, but expect them to still be **spinning**, clockwise or anti-clockwise depending on the sign of your carrier offset.
    - **`Rx Rotated`** — after carrier synchronization. Despite the name, this is the **fully corrected** output: four clusters sitting still around the reference markers.
2. Confirm you can see that progression across the three scopes. The ordering is the point — timing recovery gives you distinguishable clusters, and only carrier synchronization stops them moving.
3. If you want additional scope views of the internal tracking loops, open `digital/rtlsdr_rx/rtlsdr_QPSK_carrier_timing_plots.slx`, which adds logging and scope instrumentation on top of the same synchronization chain (it drops the base model's symbol-decision/printout branch, which you don't need just to view the constellation). Note that its recorded fallback is a different file from the one listed in step 4 and is not on Teams, so use the base model if you need to fall back.
4. **If the live transmission is weak or interrupted from your seat in the room**, use the matching recorded capture as a fallback for each stage so you can still complete the assignment: `digital/rtlsdr_rx/rec_data/qpsk_raised_cosine.mat`, `digital/rtlsdr_rx/rec_data/qpsk_coarse_synch.mat`, or `digital/rtlsdr_rx/rec_data/qpsk_carrier_timing.mat`. To switch a receiver model from live hardware to a recorded file, use the same block swap you did in [Lab 5](Lab5), Activity 4.

*For more detail on carrier and timing synchronization, see Exercises 12.5 and 12.6 in SDR textbook.*

## Assignment

```{important}
**Copy your figures, do not screenshot them.** For MATLAB figure windows, use
**Edit > Copy Figure** (or run `copygraphics(gcf)` at the command line). If a
Simulink Scope or Spectrum Analyzer cannot be copied in your MATLAB release,
maximize the scope window and capture just that window with **Win+Shift+S**.
Either way, make sure the axis labels and tick values are readable in your
document.
```

Submit a single PDF to Gradescope containing:

1. The three constellation figures from Activity 3 — `Rx Before AGC`, `Rx Timing`, and `Rx Rotated` — clearly labeled, plus your `Spectrum Analyzer - Coarse Synch` figure from Activity 2 with the induced peak visible.
2. 2-3 sentences for each stage explaining what changed and why (in your own words, not copied from the book). For Activity 2, state the frequency you read off the induced peak, the $\Delta f$ you got by dividing it by 4, and how that compares to the model's own `Calculated Frequency Offset (Hz)` display.
3. A note on whether you used the live signal or a recorded fallback file, and if the latter, why.
4. Your documentation statement.
