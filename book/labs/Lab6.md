# Lab 6: QPSK Transmission and Reception over Real Hardware

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.)

## Overview

Today the classroom becomes a real digital radio link. The instructor will transmit a live QPSK signal from the front of the room; every student receives it independently on their own RTL-SDR. This is the same real-hardware chain from Lab 5, but now with an actual live-transmitted signal instead of a recording, and now built to fully synchronize rather than just confirming the signal is there on the spectrum.

All three activities work with that live signal. Activity 3 — the full synchronizer — is the one that does not lock every time; a recorded capture is there as a fallback, and the note at the start of that activity explains when to reach for it.

**Only the instructor transmits.** We don't have a transmit-capable radio for every student, and getting one working reliably across a whole class in 53 minutes isn't something we could count on — so this lab, and Labs 7 and 8, all use one instructor transmitter with the whole class receiving simultaneously.

## Aims of the Lab

- Write down the received-signal model with frequency and phase offset, and use it to explain, in equation terms, why an uncorrected constellation spins.
- Understand, at the level of "what problem does it solve," how coarse frequency estimation and fine carrier/timing tracking each remove one piece of that model.
- Build up a QPSK receiver in three stages and observe what each correction step fixes.

> This lab runs across two class periods: **Day 1** covers Activities 1-2 (acquiring the live signal and coarse frequency correction). **Day 2** covers Activity 3 (full carrier and timing synchronization) plus the write-up. The instructor transmits on both days, and you need your dongle on both days.

## Some Math: Why the Raw Constellation Spins

Your RTL-SDR's crystal doesn't sit at exactly the instructor's transmit frequency — call the mismatch $\Delta f$ (typically tens of Hz to a few kHz), and there's also some unknown constant phase offset $\phi$ between transmitter and receiver. Your received baseband samples look like:

$$r[n] = s[n]\, e^{j(2\pi \Delta f\, nT_s + \phi)} + w[n]$$

where $s[n]$ is the transmitted QPSK symbol from Lab 5's mapping, $T_s$ is your sample period, and $w[n]$ is noise. Compare this to the complex-exponential math from Lab 2: the term $e^{j2\pi\Delta f\, nT_s}$ is a phasor whose angle grows linearly with $n$ — so every new sample, the whole constellation rotates a little further. That's exactly the "spinning" you'll see on the `Rx Timing` scope in Activity 3, and it's the same math as Lab 2's frequency correction, just now with an unknown $\Delta f$ that the receiver has to estimate rather than one you dial in by hand.

**Coarse frequency correction** (Activity 2) estimates $\Delta f$ using a trick specific to QPSK: raising each received symbol to the 4th power strips off the modulation. Since the four QPSK phases are 90 degrees apart, $(e^{j(\pi/4+k\pi/2)})^4 = e^{j\pi}$ for every $k$ — a constant, regardless of which symbol was sent. What's left is a pure tone at $4\Delta f$, whose frequency you can read directly off a spectrum analyzer — the same tool from Lab 1 — as wherever its single peak sits, then divide by 4 to recover $\Delta f$. This gets you close, but any residual estimation error still leaves some rotation and blur.

**Fine carrier and timing synchronization** (Activity 3) cleans up what coarse correction leaves behind: a phase-locked loop continuously tracks the small residual $\phi$ error sample-by-sample, while a separate timing error detector nudges when you sample each symbol so you land exactly at the peak of each pulse-shaped symbol — the same Nyquist-criterion peak from Lab 5's pulse shaping. Get both right and the four constellation points stop moving entirely.

## Setup

The instructor will announce a transmit frequency at the start of each class period and transmit the signal for the activity you're on, pausing between stages:

**Day 1** — Activities 1 and 2

**Day 2** — Activity 3

You'll run the matching receiver model at each stage, and set the frequency, `Tuner Gain (dB)` and your ppm correction in every one of them — each model carries its own copy of those settings, and each ships at values that will not work.

```{note}
**Download the recorded captures before class**, from the course Teams folder (see the [Downloads](../downloads.md) page), into `digital/rtlsdr_rx/rec_data/`. There is one for every stage, and they are about 115 MB each:

| file | stage | when you'd use it |
|---|---|---|
| `qpsk_raised_cosine.mat` | Activity 1 | live signal too weak from your seat |
| `qpsk_coarse_synch.mat` | Activity 2 | same |
| `qpsk_carrier_timing.mat` | Activity 3 | **expect to need this one** — see Activity 3 |

Switching a model from live hardware to a recorded file is the block swap you did in [Lab 5](Lab5), Activity 4, spelled out in Activity 3, step 7.

One part does not survive the fallback: steps 5 and 6 of Activity 2 need the live signal, because they work by changing the dongle's tuning.
```

## Activity 1: Acquire the Live Signal

This is the same model you ran on a recording in Lab 5, Activity 4 — now pointed at a live transmission. Its only display is `Spectrum Analyzer Receive`, which shows the signal before and after the matched RRC filter. **There is no constellation diagram in this model**; you get your first constellation in Activity 3.

1. Tune to the announced frequency.
2. Open `digital/rtlsdr_rx/rtlsdr_QPSK_raised_cosine.slx` with the `RTL-SDR Receiver` block active (the reverse of the block swap you did in Lab 5).
3. **Enter your dongle's ppm correction.** Double-click the `RTL-SDR Receiver` block and put the figure you measured in [Lab 2](Lab2) into **`Frequency correction (ppm)`**, rounded to a whole number — the field takes integers only, the same limitation you ran into in Lab 2. It ships at `0`.

    Each model carries its own copy of that block, so you will do this again in Activities 2 and 3. It barely matters for just looking at the spectrum here, but it decides whether Activity 2's estimator has a believable offset to find — and by Activity 3 it decides whether the receiver works at all. This is the Lab 2 number finally earning its keep.
4. Find the instructor's signal on the spectrum and set `Tuner Gain (dB)` so it stands clearly above the noise floor without flattening off at the top. **Start at `40`** rather than the `10` the model ships with; somewhere in the 30-45 range usually works, and above about 45 the front end compresses. Getting the gain right here saves you real trouble in Activities 2 and 3, where too little gain stops the synchronizers working at all.
5. Note how wide the signal is and where it sits relative to 0 Hz. It will still not be exactly centered, even with the ppm correction in — integer ppm cannot cancel your dongle's error exactly, and what is left over is the $\Delta f$ you are about to measure.

*For more detail on this receiver model, see Exercise 12.2 in SDR textbook.*

## Activity 2: Coarse Frequency Correction

**Why this stage exists at all.** The fine carrier synchronizer you'll run in Activity 3 is a phase-locked loop, and a PLL can only pull in an offset that is already fairly small — on the order of a kilohertz. Your dongle's crystal can easily be further off than that, and a PLL handed too large an offset simply never locks. So a *coarse* stage runs first: drag the signal to within the PLL's reach, then let the PLL clean up what's left. Coarse gets you close, fine gets you exact.

**How the model makes that measurable.** Three design choices are worth understanding before you run it.

- **The offset is injected deliberately, and you control it.** The `Additional Freq Offset (Hz)` block is *summed with* `QPSK Signal Frequency (Hz)` before driving the `RTL-SDR Receiver`. The model mistunes your dongle on purpose, by a known amount, on top of whatever error your crystal already contributes. That gives you a ground truth to check the estimator against — and a knob to turn. **Set it to `700`.** It ships at `400`, which is close enough to a typical dongle's own crystal error at this frequency that the two can very nearly cancel, leaving no offset to find and nothing to see.
- **The signal is decimated hard before the estimator: 240 kHz, then ÷5 to 48 kHz, then ÷6 to 8 kHz.** The estimator takes an FFT of the 4th-power signal and picks the largest bin, and the bins are $f_{FFT} = f_s/N_{FFT}$ apart, so dropping $f_s$ makes them finer. What stops you decimating further is that the tone sits at $4\Delta f$, so $f_s$ must stay **at least 8 times the largest offset you intend to handle**. At 8 kHz that caps you near $\pm$1 kHz — comfortably above the 700 Hz you are injecting.
- **Correction happens before the matched filter here**, the reverse of the Activity 1 model. The order is decimate → estimate and correct → RRC filter.

1. Open `digital/rtlsdr_rx/rtlsdr_QPSK_coarse_synch.slx` and, before you run it, set three things:
    - **`Frequency correction (ppm)` on the `RTL-SDR Receiver` block**, to your whole-number ppm figure from [Lab 2](Lab2), exactly as in Activity 1. This is a separate copy of the block, so it is back at `0` here.
    - **`Tuner Gain (dB)` to `40`.** It ships at `10`, which is far too low for this activity. Your dongle puts a fixed DC spike at the centre of its output, and at gain 10 that spike sits roughly 28 dB above the signal, so the estimator finds the spike instead of the signal and reports an offset of 0 Hz. Raising the gain lifts the signal by about 20 dB while the spike barely moves, which is what makes the real tone findable. Above about 45 the front end starts to compress and it gets worse again.
    - **`Additional Freq Offset (Hz)` to `700`**, per the note above.
2. Run it once the instructor starts the matching transmitter.
3. This model has **no constellation diagram either**. What it gives you is `Spectrum Analyzer - Coarse Synch`, carrying three traces that walk through the 4th-power trick from the math section above:
    - **Decimated signal** — the 8 kHz signal going into the estimator, sitting off-center by $\Delta f$.
    - **Induced Peak** — that same signal raised to the 4th power. The QPSK modulation cancels and leaves energy concentrated at $4\Delta f$.
    - **Corrected signal** — the input shifted by the estimate, now centered on 0 Hz.

    **Expect a broad hump, not a clean spike.** The math says $s^4$ is a constant times a single phasor, so you might expect one sharp line. You will instead see a peak a few kilohertz wide, riding maybe 8 to 15 dB above its own skirts. Two reasons, and neither is a fault:

    - **The modulation only cancels exactly at the symbol instants.** The estimator runs at 8 kHz on a 1 kSps signal, so seven of every eight samples land partway up a pulse, where the phase is still sweeping between constellation points. Those samples raised to the 4th power point in scattered directions and spread out into the pedestal; only the on-symbol samples build the peak. Sample this signal at exactly one sample per symbol and the hump collapses to a line — but you cannot do that yet, because sampling at the symbol instants requires the timing recovery that does not run until Activity 3.
    - **Raising to the 4th power widens any spectrum by roughly four times**, since in the frequency domain it convolves the spectrum with itself four times. Your pulse-shaped signal is about 1.5 kHz wide to begin with, so the result is several kilohertz wide no matter how clean the signal is.

    This also means the bin spacing above is a *floor* on the error, not the accuracy you actually get. The bins may be about 1 Hz apart, but you are locating the middle of a hump thousands of hertz wide, so realistic accuracy is on the order of a hundred hertz. That gap is the whole reason this stage is called *coarse* and why a PLL has to finish the job.
4. **Get a number off the induced peak**, then divide it by 4 and compare against the `Calculated Frequency Offset (Hz)` display, which is what the model's own estimator computed.

    Do not try to eyeball this. You are reading a hump, not a line, and judging its middle by eye from a moving trace is genuinely hard. Use one of the scope's measurement tools instead — both live under **Measurements** (the toolstrip tab in recent releases, the side panel in older ones):

    - **Cursor Measurements** suits a hump best. Drag the two cursors to the points on either side where the hump climbs out of the pedestal, and take the midpoint of the two frequencies. You are deliberately estimating the centre rather than chasing the tallest point.
    - **Peak Finder** gives you a number directly. Ask it for one peak, and raise its minimum-height setting above the pedestal so it reports the hump rather than whichever noise spike happens to be tallest.

    Either way the reading wanders, typically by a hundred hertz or two, because the top of a broad hump moves around from update to update. Watch it for a few seconds and take a representative value rather than one snapshot. You are confirming the factor of 4, not measuring to the hertz.

    Two reasons your answer will not come back as exactly 700 Hz, and both are worth understanding. The hump is wide, so locating its centre is only good to roughly a hundred hertz. And your dongle's own crystal error adds to the offset you injected — that difference *is* your dongle's error, the same quantity you measured a different way in Lab 2.
5. **Turn the knob — live reception only.** Change `Additional Freq Offset (Hz)` to something else — try 300, then 900 — and re-run each time. Confirm that the induced peak moves to 4x whatever you set, that the displayed estimate follows it, and that the corrected trace stays centered on 0 Hz regardless. That is the entire algorithm working in front of you.

    This is the more convincing evidence of the two, and the easier to see. Reading the hump's absolute position is fuzzy, but 300 Hz against 900 Hz puts it near 1200 Hz and then near 3600 Hz — a shift across most of the display that you cannot mistake. Watching it move is a better demonstration that the $4\Delta f$ relationship holds than any single reading.

    This step does nothing if you are running from a recorded file. The offset block is summed with `QPSK Signal Frequency (Hz)` and the result drives the `RTL-SDR Receiver` tuning port only, so with `Import RTL-SDR Data` active that whole branch is disconnected and the recording's own built-in offset is all you get. Skip to step 7 if you are on the fallback.
6. **Now break it** (also live only). Set the offset past what an 8 kHz sample rate can support — try 1500 — and re-run. The estimate should come back wrong. Work out what happened to the $4\Delta f$ tone, using the 8x rule above, and be ready to explain it.
7. `Spectrum Analyzer - Received Signal` and `Spectrum Analyzer - RRC Filtered` show earlier points in the chain if you want to trace the signal through.

```{warning}
**If the induced peak sits at exactly 0 Hz, the estimator has locked onto DC, not onto your signal.**

Your dongle puts a DC spike at the center of its output — an artifact of LO
leakage and ADC bias, not part of the transmission. Raising a signal to the 4th
power leaves DC at DC, so that spike lands in the same FFT bin the estimator
searches and competes with the real $4\Delta f$ tone. Win that contest and the
reported offset is 0 Hz, which looks exactly like a broken model.

Work through it in this order:

1. **Raise `Tuner Gain (dB)` to about 40.** This is almost always the answer,
   and it is why step 1 asks for it. The DC spike is roughly fixed no matter
   what the gain is, while the signal rises with it, so turning the gain up
   changes which of the two the estimator finds. At the shipped gain of 10 the
   spike wins by around 28 dB and you get 0 Hz; by 30 to 40 the estimate settles
   on a steady, believable number. Past about 45 the front end compresses and
   you lose ground again.
2. **Check that the signal is actually there.** Look at `Spectrum Analyzer -
   Received Signal` and confirm you can see the QPSK signal above the noise
   floor. If the transmitter is not running or you are out of its reach, you are
   feeding the estimator noise plus a DC spike, and 0 Hz is the only answer it
   can give.
3. **Then improve the signal itself.** Re-aim or reposition as you did in Lab 1.
   What matters here is the ratio of signal to DC, so anything that strengthens
   the signal helps.
```

*For more detail on coarse frequency synchronization, see Exercises 12.3 and 12.4 in SDR textbook.*

## Activity 3: Full Carrier and Timing Synchronization

```{important}
**This one does not work every time, and that is expected.** The full
synchronizer is the most delicate stage in the lab — it has to acquire carrier
phase and symbol timing at the same time on a 1000 symbols per second signal,
and its loops only pull in over a narrow range. Measured on these same radios
at close range, it resolved four clean clusters on roughly **one run in
three**. The rest of the time it gives one slowly turning mass.

That is not something you did wrong, and there is no setting that fixes it.
When it fails it fails completely rather than looking marginal, so it is easy
to tell which you got. **Re-run it.** If three or four honest attempts with the
settings in step 1 all give you a rotating mass, switch to the recorded capture
in step 7 and carry on — it locks every time, and you lose nothing on the
assignment by using it.
```

1. Open `digital/rtlsdr_rx/rtlsdr_QPSK_carrier_timing.slx` and set three things before running it. **All three matter more here than anywhere else in the lab** — get any of them wrong and this activity cannot work at all.

    - **`QPSK Signal Frequency (Hz)`** to the announced frequency. It ships at `602e6`.
    - **`Frequency correction (ppm)` on the `RTL-SDR Receiver` block**, to your whole-number ppm figure from [Lab 2](Lab2). This is a fresh copy of the block, so it starts at `0` again. This activity runs at 1000 symbols per second, and an uncorrected dongle is typically a few hundred hertz out at this frequency — well over half a symbol's worth of rotation every symbol. The timing and carrier loops cannot recover from that.
    - **`Tuner Gain (dB)` to `40`**, for the same reason as Activity 2 — this model ships at `10` and carries the same coarse stage inside it. At gain 10 that stage locks onto your dongle's DC spike, reports an offset of 0 Hz, and everything downstream works on a signal that was never corrected.

    If the constellations still look poor after all three are set, give the dongle ten minutes to warm up and try again. Its crystal drifts while it reaches temperature, which moves the offset out from under the correction you just entered — the same warm-up effect Lab 2 warns about before taking a calibration reading.
2. Run it once the instructor starts the matching transmitter. This model adds fine carrier tracking and symbol timing recovery on top of the coarse correction, and **it is the model with the constellation diagrams** — three of them, tapping the signal at three points in the chain:
    - **`Rx Before AGC`** — straight off the matched filter, before any gain control or synchronization. This is your uncorrected view: a smeared ring, nothing yet resembling four points. Use it to judge signal strength — if the ring is squeezed tight around the origin or sprawling off the edges, change `Tuner Gain (dB)` and re-run.
    - **`Rx Timing`** — after AGC and symbol timing recovery. Four clusters should be distinguishable, but expect them to be **spinning**, clockwise or anti-clockwise depending on the sign of your carrier offset.
    - **`Rx Rotated`** — after carrier synchronization. Despite the name, this is the **fully corrected** output: four clusters sitting still around the reference markers.
3. Confirm you can see that progression across the three scopes. The ordering is the point — timing recovery gives you distinguishable clusters, and only carrier synchronization stops them moving.
4. **Judging what you got.** The two outcomes look quite different, so don't agonise over it:
    - **Locked** — `Rx Rotated` shows four tight, clearly separated clusters sitting still on the reference markers. Capture it.
    - **Not locked** — one diffuse mass rotating slowly, or four smears you have to squint to count. The clusters never settle. Re-run.

    If you catch a run that locks, grab all three figures before stopping it.
5. Re-run as needed, up to three or four attempts. Each run costs under a minute, and the outcome is independent each time, so a few attempts is a reasonable use of the period.
6. If you want additional scope views of the internal tracking loops, open `digital/rtlsdr_rx/rtlsdr_QPSK_carrier_timing_plots.slx`, which adds logging and scope instrumentation on top of the same synchronization chain (it drops the base model's symbol-decision/printout branch, which you don't need just to view the constellation). Its own recorded fallback is a different file, `rec_data/qpsk_carrier_timing_plots.mat`, which is not in the Teams folder — so treat this step as optional and use the base model for the assignment.

### Step 7: The recorded fallback

**If several honest attempts all give you a rotating mass, use this and move on.** It is a real over-the-air RTL-SDR capture recorded for the SDR textbook, not a simulation, and it locks within about a second of starting and holds for the whole run — so every part of the progression above is visible in it. Using it costs you nothing on the assignment; just say so in your write-up.

7. Download `qpsk_carrier_timing.mat` from the course Teams folder (see the [Downloads](../downloads.md) page) into `digital/rtlsdr_rx/rec_data/`. It is about 115 MB, so **do this before class**, not while the period is running.
    - Right-click `RTL-SDR Receiver o/p fs=240kHz` and choose **Comment Out**.
    - Right-click the greyed-out `Import RTL-SDR Data` block, sitting below the receiver, and choose **Comment In**. Its filename is already set to `rec_data/qpsk_carrier_timing.mat`.
    - Draw one signal line from the `Import RTL-SDR Data` output to the input of `FIR Decimation x5 o/p fs=48kHz`, which is where the receiver's output used to go. This is the same swap as [Lab 5](Lab5), Activity 4, and simpler here — one line instead of two.
    - Set the simulation mode to **Normal**. The model ships in *Accelerator*, which is meant for live hardware. Its **Stop Time** ships at `60`, exactly the length of the recording; `30` shows you everything in half the time.

    Keep MATLAB's **Current Folder** on `digital/rtlsdr_rx` — that filename is relative to it, and a "cannot find the file" error is almost always this.

    On the recording, `Frequency correction (ppm)`, `Tuner Gain (dB)` and `QPSK Signal Frequency (Hz)` all stop doing anything: commenting out the receiver disconnects the entire tuning branch, since all three feed that one block. The samples arrive exactly as they were captured, on someone else's dongle.

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
3. For each activity, a note on whether your figures came from the live signal or from a recorded fallback file, and if the latter, why. Using the fallback in Activity 3 is expected and costs you nothing — but say how many live attempts you made first.
4. Your documentation statement. Make sure you give specifics to: 1. Who helped you? 2. On which part? 3. How did they help? If you used generative AI: 4: Which AI did you use? 5: What was your prompt? 6: How did you modify the AI's response?
