# Lab 3: Amplitude Modulation — Receiving Real Air Band Traffic

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, highlights of Ch. 5.3-8.3.)

```{note}
**Download this before you start.** Activity 3 uses one script that was added after
the Lab 1 download: `qam_qpsk_constellation_noise.m`. If you already unzipped the
support files, you do not need to download the whole package again -- just grab
[**qam_qpsk_constellation_noise.m**](support_files/digital/simulation/modulation/qam_qpsk_constellation_noise.m)
and save it into your support files at
`support_files/digital/simulation/modulation/qam_qpsk_constellation_noise.m`
-- the `digital/simulation/modulation` folder you already have, next to
`QAM16_constellation_noise.slx`.

Everything else you need for this lab is already in the copy you downloaded. If
you would rather start fresh, the full [support_files.zip](support_files.zip) on
the [Downloads](../downloads.md) page already contains it.
```

## Overview

Aircraft communications still use plain old amplitude modulation (DSB-LC, the same scheme as commercial AM broadcast) on the Air Band, 108-137 MHz — conveniently right in your RTL-SDR's tuning range, unlike commercial mediumwave AM. That makes today's lab genuinely off-the-air: you'll receive and demodulate real USAFA airfield traffic, not a simulated or instructor-transmitted signal.

This lab skips transmitting AM yourself with a PLUTO radio — since the goal is to hear a real signal, not one we generated in the room. We'll also take a first look at QAM in simulation, since you'll need it again soon in the digital communications unit.

## Aims of the Lab

- Derive the DSB-LC and DSB-SC equations and understand exactly why one demodulates with a simple envelope detector while the other needs a coherent (synchronous) receiver.
- Build and use a non-coherent (envelope) AM demodulator — the same basic technique used in real aviation radios.
- Receive and demodulate live Air Band traffic from the USAFA airfield.
- Get a first, low-stakes look at QAM constellations in simulation.

## Some Math: DSB-LC vs. DSB-SC

**DSB-LC** ("large carrier" — what Air Band radios and commercial AM broadcast use) transmits the message riding on top of a carrier:

$$s(t) = \big[A_c + m(t)\big]\cos(2\pi f_c t)$$

Because $A_c$ is a large constant added to $m(t)$, as long as $A_c + m(t) \ge 0$ for all $t$, the envelope of $s(t)$ — its amplitude, ignoring the carrier phase entirely — traces out $A_c + m(t)$ directly. That's the entire trick behind envelope detection: no local oscillator, no phase tracking, just rectify and low-pass filter, and $m(t)$ falls out (after removing the DC offset $A_c$). The positivity requirement defines the **modulation index**:

$$\mu = \frac{\max|m(t)|}{A_c} \le 1$$

If $\mu > 1$ ("over-modulation"), $A_c + m(t)$ goes negative somewhere, the envelope detector can't track it faithfully, and you get audible distortion. This simplicity is exactly why DSB-LC is still standard for aviation voice: it works with dead-simple, rugged receivers, at the cost of wasting transmit power on the carrier itself.

**DSB-SC** ("suppressed carrier") drops the carrier term entirely:

$$s(t) = m(t)\cos(2\pi f_c t)$$

More power-efficient, but now the envelope of $s(t)$ is just $|m(t)|$ — not $m(t)$ — so an envelope detector can't recover the message (it can't tell a positive swing from a negative one). Instead you need **coherent detection**: multiply by a locally generated copy of the carrier and low-pass filter:

$$s(t)\cos(2\pi f_c t) = m(t)\cos^2(2\pi f_c t) = \frac{m(t)}{2}\big[1 + \cos(4\pi f_c t)\big] \xrightarrow{\text{LPF}} \frac{m(t)}{2}$$

The catch: this only works if your local oscillator's phase matches the transmitter's carrier phase. A phase error $\phi$ scales the recovered signal by $\cos\phi$ — at $\phi=90°$ you get nothing at all. That phase-matching requirement is exactly what makes coherent receivers harder to build than envelope detectors, and why we're sticking with DSB-LC for today's real-world reception.

## Activity 1: DSB-LC in Simulation

1. Open `am/simulation/am_dsb_tc.slx` and run it at the default modulation index. This model *generates* a DSB-LC signal in simulation — it is a transmitter, not a receiver — so you can see what a clean modulated waveform and its spectrum look like before you go fight real noise and fading.
2. On the time-domain scope, confirm you can see the message riding on the carrier's envelope: the outline of the modulated waveform traces $A_c + m(t)$. That outline is exactly what the envelope detector in Activity 2 will pull back out.
3. On the spectrum, find the carrier spike at $f_c$ and the sidebands on either side of it. Note that the carrier itself carries no information — that is the transmit power DSB-LC "wastes" in exchange for a simple receiver.
4. Push the modulation index above $\mu=1$ (increase $m(t)$'s amplitude relative to $A_c$) and re-run. Confirm the envelope now crosses through zero and folds over, and explain in your own words why that makes the message unrecoverable by envelope detection.

*For more detail on DSB-LC and envelope detection, see Sec. 6.3 and 6.8 in SDR textbook.*

## Activity 2: Envelope Detection on Real Air Band Traffic

> **Set up your antenna and your location first.** Airfield transmissions are far weaker than commercial FM, so the antenna work from [Lab 1](Lab1) (Activity 2, step 1) matters *more* here, not less. Set your whip to a quarter wavelength for this band — about **62 cm** at 120 MHz — and give it a ground plane, either a magnetic base on a large metal surface or three or four radials cut to that same length. You'll also need to get out of the interior of Fairchild: a window, or better, the southeast corner.

1. Open `am/rtlsdr_rx/rtlsdr_am_envelope_demod.slx`.
2. Tune to the Air Band frequency you identified in Lab 1 for USAFA airfield traffic (tower, ground, or approach).
3. Listen for aircraft or controller transmissions — Air Band traffic is intermittent (push-to-talk), so you may need to wait, or try a couple of different frequencies in the 118-137 MHz range.
4. If you have trouble finding active traffic, switch to `am/rtlsdr_rx/rtlsdr_am_envelope_demod_matlab.m`, the same receiver as a MATLAB script, which is easier to leave running in the background while you work on something else and listen for activity.

*For more detail on downconverting and envelope-detecting real AM signals, see Sec. 6.7-6.8 and 8.2 in SDR textbook.*

## Activity 3: A First Look at QAM (Simulation)

```{note}
**This one is a preview.** QAM, constellations, symbols, and $E_b/N_0$ all belong to the
digital communications block later in the semester. You are not expected to have seen any
of it yet, and this lab does not test the details. It sits here because QAM falls straight
out of the DSB-SC math you just did -- it is literally two DSB-SC signals stacked on the
same carrier -- so this is the cheapest possible moment to look at it.
```

### Four ideas you need for today

**1. Digital systems send *symbols*, not one bit at a time.** Everything so far in this lab
carried a continuous message $m(t)$. A digital transmitter instead sends bits, and it is
wasteful to send them one at a time. So group them: 2 bits have 4 possible combinations,
4 bits have 16. Pick one waveform for each combination and send it for a fixed slice of
time. That slice is a **symbol**. Four bits per symbol means four times the data rate of
one bit per symbol, in the same bandwidth -- which is the entire reason anyone bothers.

**2. A *constellation* is the map of the allowed symbols.** Each symbol is just a choice of
$I$ and $Q$ amplitudes, so plot $I$ across and $Q$ up: every symbol becomes a **point** on
that plane, and the set of all allowed points is the constellation. **QPSK** uses 4 points
(2 bits each); **16-QAM** uses 16 points (4 bits each). The receiver's job is simply to
decide which point was sent, by picking whichever one the received sample landed nearest to.

**3. Noise is what makes that decision hard.** Noise nudges each received point off its
ideal position. As long as it stays nearer its own point than any neighbour, the receiver
still decides correctly and no error occurs. Push it past the halfway line to a neighbour
and the receiver reads out the wrong bits -- a **symbol error**. Cramming 16 points into
the same plane as 4 leaves each point much less elbow room, which is the whole experiment
below.

**4. $E_b/N_0$ is the noise knob.** Read it as "signal quality per bit" -- **higher means
cleaner, lower means noisier**. It is a per-*bit* measure rather than a per-symbol one,
which is what makes it a fair way to compare two schemes that carry different numbers of
bits per symbol. For today, just turn the knob and watch.

### Where QAM comes from

QAM is what you get from packing *two* DSB-SC signals into the same bandwidth, 90 degrees
out of phase with each other:

$$s(t) = I(t)\cos(2\pi f_c t) - Q(t)\sin(2\pi f_c t)$$

where $I(t)$ and $Q(t)$ each carry their own independent stream of bits. A coherent receiver
separates them by multiplying by $\cos(2\pi f_c t)$ and $\sin(2\pi f_c t)$ respectively (each
recovers one component, by the same coherent-detection math as DSB-SC above -- try writing
out $s(t)\cos(2\pi f_c t)$ and $s(t)\sin(2\pi f_c t)$ and low-pass filtering each). Notice
that an envelope detector can't do any of this: it only reports $\sqrt{I(t)^2+Q(t)^2}$,
throwing away exactly the phase information that tells $I$ and $Q$ apart.

### Where you have already used QAM today

Almost every high-rate link you touch runs some flavour of QAM:

- **Wi-Fi** -- up to 1024-QAM (Wi-Fi 6) and 4096-QAM (Wi-Fi 7)
- **4G LTE and 5G** -- commonly up to 256-QAM
- **Cable internet (DOCSIS) and digital cable TV** -- 256-QAM up to 4096-QAM
- **Satellite and microwave backhaul links**

And the experiment you are about to run explains something you have felt: your router and
phone *change* QAM order on the fly. Close to the access point, the signal is clean, so the
link uses a dense constellation and you get high throughput. Walk away, noise wins, and the
link falls back to fewer points per symbol -- slower, but decodable. You are about to watch
that same tradeoff happen on your own screen.

1. Open `digital/simulation/modulation/qam_qpsk_constellation_noise.m` (the script from the download note at the top of this lab) and run it as-is. It sends 5000 random symbols through a noisy channel twice -- once as **16-QAM**, once as **QPSK** -- at the *same* $E_b/N_0$, and plots both received constellations side by side. Red crosses mark where the symbols were supposed to land; blue dots are what actually arrived.
2. Note the symbol-error count printed in each subplot title. At the starting value of `EbNo_dB = 15` both should be clean or nearly so.
3. Now add noise: change `EbNo_dB` near the top of the script to 10, re-run, then 8, then 5. Watch the clusters spread. Find roughly the value at which **16-QAM starts making errors while QPSK is still error-free**, and record it.
4. Explain what you found using the constellations themselves: both modulations are held to the same average power, so packing 16 points into the I/Q plane instead of 4 leaves each point much less room before noise carries it across a decision boundary.
5. You'll come back to this exact tradeoff -- and to QPSK specifically -- in the digital communications block, where we work out *how much* noise each constellation can take before it breaks.

```{seealso}
If you want to see the underlying modulation and demodulation worked out in code, the
Chapter 4 computer exercise
[4.12.4 QAM modulation and demodulation](https://usafa-ece.github.io/ece447-book/chapter04.html#qam-modulation-and-demodulation)
builds a QAM signal and pulls the two messages back out. Optional -- we will cover this
properly in the digital communications block.
```

*For more detail on QAM, see Sec. 5.4 in SDR textbook.*

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

1. Your envelope detector output (spectrum, and a note on what you heard) while receiving live Air Band traffic, with the frequency you tuned to and a description of the traffic (tower/ground/approach, if you could tell).
2. Two figures from Activity 3 — the 16-QAM/QPSK pair at a low-noise setting and at a setting where 16-QAM is visibly breaking up — with the $E_b/N_0$ and error counts legible. In 2-3 sentences, state roughly where 16-QAM started making errors while QPSK did not, why that is, and explain in terms of $I(t)$ and $Q(t)$ why a DSB-LC envelope detector could not demodulate either of them.
3. Your documentation statement.
