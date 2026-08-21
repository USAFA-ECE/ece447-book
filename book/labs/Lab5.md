# Lab 5: Digital Modulation Fundamentals

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 11.1-11.2.)

## Overview

This lab is entirely simulation-based — no live transmission needed — and sets up everything you'll need for the hands-on hardware labs that follow. You'll map bits to symbols, look at constellations under noise, and see why we shape pulses instead of just switching amplitudes on and off. To ground it in something real, you'll finish by loading an actual RTL-SDR capture of a QPSK signal recorded for the SDR textbook, straight from your course files.

## Aims of the Lab

- Write down the QPSK and 16-QAM symbol-mapping equations and use them to explain, quantitatively, why higher-order constellations are more fragile to noise.
- See how noise degrades a constellation, and connect what you see to minimum distance between constellation points.
- Derive the Nyquist ISI criterion and the bandwidth-vs-rolloff tradeoff for pulse shaping.
- View a real captured QPSK signal for the first time.

## Some Math: Symbol Mapping and Minimum Distance

QPSK maps every 2 bits onto one of 4 symbols, each a point on the unit circle at one of four phases:

$$s_k = \sqrt{E_s}\, e^{j(\pi/4 + k\pi/2)}, \qquad k = 0,1,2,3$$

or equivalently in I/Q form, $s_k \in \{\pm 1 \pm j\}\sqrt{E_s/2}$. In general, an $M$-ary constellation carries $k=\log_2 M$ bits per symbol, so for a fixed bit rate $R_b$, the symbol rate is $R_s = R_b/k$ — this is exactly why higher-order modulation (more bits/symbol) lets you fit more data into the same symbol rate (and therefore the same bandwidth).

That efficiency has a cost, though. For a fixed *average symbol energy* $E_s$ (roughly, fixed transmit power), packing more points into the same I/Q area means each pair of adjacent points is closer together — their **minimum distance** $d_{min}$ shrinks as $M$ grows. Since additive noise pushes a received point around by some random amount, a smaller $d_{min}$ means a much higher chance that a noise-corrupted point crosses into a neighboring symbol's decision region and gets decoded wrong. That's the precise, quantitative version of "16-QAM is more fragile than QPSK" you'll observe in Activity 2.

## Activity 1: Bits to Symbols

1. Open `digital/simulation/modulation/QPSK_map_demap.slx` and `digital/simulation/modulation/QPSK_map_demap_IQ.slx`. These implement the QPSK mapping equation above.
2. Confirm that mapping then demapping recovers your original bits with no noise present.
3. Identify which of the four constellation points corresponds to which 2-bit pair, and check it against the $s_k$ equation above (which phase does $k=0$ land at?).

*For more detail on symbol mapping, see Sec. 11.1 in SDR textbook.*

## Activity 2: Constellations Under Noise

1. Open `digital/simulation/modulation/QPSK_constellation_noise.slx` and `digital/simulation/modulation/QAM16_constellation_noise.slx`.
2. Sweep the noise level up on both and compare: at what noise level does QPSK's constellation start to look "fuzzy," versus 16-QAM's? You should see 16-QAM degrade first — its $d_{min}$ is smaller for the same average energy, exactly as the math above predicts.
3. Open `digital/simulation/modulation/QAM16_constellation_IQ.slx`, which breaks the same 16-QAM signal into separate I and Q views, if you want to see the components individually.

*For more detail on constellation noise sensitivity, see Sec. 11.1 in SDR textbook.*

## Activity 3: Pulse Shaping — the Nyquist ISI Criterion

A pulse shape $p(t)$ avoids inter-symbol interference (ISI) if it satisfies the **Nyquist ISI criterion**: sampled at the symbol rate, it must be zero at every neighboring symbol instant and 1 at its own center,

$$p(nT_s) = \begin{cases}1 & n=0 \\ 0 & n \ne 0\end{cases}$$

so that when pulses from neighboring symbols overlap in time (which shaped pulses do), they contribute exactly zero at the instant you sample the symbol you care about. The raised-cosine family of pulses is built specifically to satisfy this. Its bandwidth depends on the **roll-off factor** $\alpha$ (0 to 1):

$$B = \frac{1+\alpha}{2T_s}$$

A rectangular pulse is the extreme case that doesn't satisfy the criterion cleanly in a bandlimited channel — its spectrum has long, slowly-decaying sidelobes that leak into neighboring channels, which is exactly what you'll see in the comparison below. A smaller $\alpha$ saves bandwidth but makes the pulse decay more slowly in time (harder to implement, more sensitive to timing error) — you'll feel that tradeoff again in Lab 6 and 7's real-time symbol timing recovery.

1. Open `digital/simulation/pulse/rect_v_RRC.slx` to compare a rectangular pulse against a root-raised-cosine (RRC) shaped pulse, in both time and frequency.
2. Open `digital/simulation/pulse/raised_cosine_pulses.slx` and `digital/simulation/pulse/sqrt_raised_cosine_pulses.slx` to see the shaped pulses in the time domain.
3. Confirm for yourself that each pulse crosses zero exactly at the neighboring symbols' sampling instants, per the criterion above.
4. Try increasing and decreasing the roll-off factor $\alpha$ and note how the pulse's time-domain decay and frequency-domain bandwidth trade off against each other.

*For more detail on pulse shaping and the Nyquist ISI criterion, see Sec. 11.2 in SDR textbook.*

## Activity 4: A Real Captured Signal

1. Download `qpsk_raised_cosine.mat` from the course Teams folder (see the [Downloads](../downloads.md) page) and put it in `digital/rtlsdr_rx/rec_data/`.
2. Open `digital/rtlsdr_rx/rtlsdr_QPSK_raised_cosine.slx`. It ships wired for **live** hardware: the `RTL-SDR Receiver` block is active and the `Import RTL-SDR Data` block next to it is greyed out (commented out). You need to swap which one feeds the receiver:
    - Right-click `RTL-SDR Receiver` and choose **Comment Out**.
    - Right-click the greyed-out `Import RTL-SDR Data` block and choose **Comment In**. Its filename is already set to `rec_data\qpsk_raised_cosine.mat`.
    - Draw signal lines from the `Import RTL-SDR Data` output to the two places the `RTL-SDR Receiver` output used to go: the `Raised Cosine Receive Filter` and the `Matrix Concatenate` block.
3. Run it. This is an actual over-the-air RTL-SDR capture recorded for the SDR textbook, not a simulation — so you do **not** need your dongle plugged in for this activity.
4. Look at the resulting constellation and note what it looks like: it likely will *not* look clean yet, since this file hasn't gone through the frequency and timing correction you'll build in Lab 6.

*For more detail on real-time QPSK receiver models, see Sec. 12.1 in SDR textbook.*

## Assignment

Submit a single PDF to Gradescope containing:

1. Constellation screenshots for QPSK and 16-QAM at two comparable noise levels, with 2-3 sentences comparing their sensitivity to noise.
2. The rectangular vs. RRC pulse spectrum comparison from Activity 3, with 1-2 sentences on which one you'd rather transmit next to another signal, and why.
3. Your constellation screenshot from the real recorded QPSK capture in Activity 4, with a one-sentence prediction of what you think is wrong with it (you'll find out for real in Lab 6).
4. Your documentation statement.
