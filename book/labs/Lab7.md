# Lab 7: A Digital Communications Protocol — ASCII Messaging

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.4-12.7.)

## Overview

A synchronized QPSK link (Lab 6) only gets you a clean stream of symbols — it doesn't tell you where a message starts. Today you'll receive a live, framed, ASCII-encoded message from the instructor and decode actual text out of the air. As in Lab 6, only the instructor transmits; the whole class receives simultaneously on individual RTL-SDRs.

One thing is different from Lab 6, and it is the point of the lab's last section: **the link runs differentially encoded.** Coherent QPSK framing does not survive the carrier's 90° phase ambiguity — measured on this exact hardware, it never once located a frame — while the differential version does, every time. You'll switch one block to make that work, and the Optional Extension at the end explains why it is necessary.

## Aims of the Lab

- Write down the cross-correlation frame-detection metric and use it to explain how the receiver locates a known sync word inside a continuous symbol stream.
- Decode a real over-the-air ASCII message end-to-end.

## Some Math: Finding the Frame with Cross-Correlation

The transmitter prepends every message with a known sequence of symbols, $c[0], c[1], \dots, c[L-1]$ (the sync word), that both transmitter and receiver agree on ahead of time. The receiver slides a window of length $L$ across its incoming symbol stream $r[n]$ and computes the cross-correlation at every position:

$$R[n] = \sum_{k=0}^{L-1} r[n+k]\, c^*[k]$$

When the window is aligned exactly with the transmitted sync word, every term in the sum adds constructively (since $r[n+k] \approx c[k]$ there), producing a sharp peak in $|R[n]|$. Anywhere else, the received symbols are essentially uncorrelated with $c[k]$, so the terms partially cancel and $|R[n]|$ stays small. Detecting that peak (usually by comparing it against a threshold) tells the receiver exactly which sample index the message frame starts at — this correlation is precisely the matched filter operation, so named because $c^*[k]$ is matched to the exact known waveform you're searching for.

## Setup

The instructor will announce a transmit frequency and repeatedly transmit a short text message framed with a known sync word, differentially encoded.

## Activity 1: Frame Synchronization

```{note}
**Frame detection is stricter than anything earlier in the course.** The
receiver declares a frame only when the correlation against the 39-bit sync
word reaches 33 — it tolerates a handful of wrong bits and no more. A signal
can produce a textbook-perfect constellation and still never cross that
threshold, in which case the receiver decodes nothing while looking completely
healthy. Step 2 is what keeps you out of that situation, so don't skip it.
```

1. Open `digital/rtlsdr_rx/rtlsdr_QPSK_ascii_message.slx` and set three things, exactly as in Lab 6:
    - **`QPSK Signal Frequency (Hz)`** to the announced frequency. It ships at `602e6`, which is not where the instructor is transmitting.
    - **`Tuner Gain (dB)` to `40`.** It ships at `10`, far too low — this model carries the same coarse frequency estimator as Lab 6, and at gain 10 that stage locks onto your dongle's DC spike instead of the signal.
    - **`Frequency correction (ppm)`** on the `RTL-SDR Receiver` block, to your whole-number figure from [Lab 2](Lab2). It ships at `0`.
2. **Switch the demodulator to DQPSK.** Open `Decimation, Demodulation, Frame Synch & ASCII Decoding`, then `Demodulation & Frame Synch`, then `Demodulation & Phase Ambiguity Correction`. Flip the **Manual Switch** from the `QPSK Demodulator Baseband` to the `DQPSK Demodulator Baseband`.

    This is not optional and it is not a workaround — it is the lab's lesson arriving early. The transmission is differentially encoded, and with the coherent QPSK demodulator selected the correlation tops out around 20 and **not one frame is ever found**, however clean your constellation looks. The Optional Extension at the end of this lab is the algebra for why.
3. Run it once the instructor starts transmitting. The model doesn't display the frame-sync signal, so add a readout yourself. Those signals are deeper in the model than you might expect — inside `Decimation, Demodulation, Frame Synch & ASCII Decoding`, then `Demodulation & Frame Synch`, then `Frame Synchronisation`. In there:
    - right-click the **Frame Strobe** signal and connect a Scope (or enable signal logging on it);
    - do the same inside `Matched Filter Correlator` on its **Correlation Amplitudes** output, to watch the $R[n]$ correlation itself.
4. Confirm the strobe is firing — each pulse is the receiver declaring "a sync word lines up here," which is what tells it where the message frame begins. That scope is the figure you'll submit.
5. Look at the correlation trace alongside it. The peaks should reach **39**, the full length of the sync word, meaning every bit of the preamble matched; between frames the correlation sits down around 3. That ratio is why a simple threshold works at all, and it is worth seeing before you trust it.

```{note}
If nothing is framing, work through it in this order: the demodulator switch
(step 2), then `Tuner Gain (dB)`, then the frequency, then your ppm figure. A
dead-looking receiver in this lab is almost always one of those four, not a
weak signal — check `Spectrum Analyzer - Received Signal` to confirm the signal
is actually there before chasing anything else.
```

*For more detail on data and frame synchronization, see Sec. 12.6 in SDR textbook.*

## Activity 2: Decode the Message

1. With frame sync firing, the receiver decodes each frame's payload into ASCII characters.
2. **The decoded text prints to the MATLAB Command Window**, not to any scope or display in the model — a `disp` inside the library's decoder writes one line per frame. Watch the Command Window as the simulation runs.
3. Confirm you can read the transmitted text. You should see the instructor's message followed by a three-digit frame counter that increments every frame — `Hello World! 035`, `Hello World! 036`, and so on, wrapping at 100. The transmitter appends that counter to every frame, so consecutive numbers are your evidence that frames are arriving in order and none are being dropped.
4. Copy a few consecutive lines for the write-up.

```{note}
**If the live signal is too weak from where you're sitting**, fall back to
`digital/rtlsdr_rx/rec_data/qpsk_ascii_msg.mat` (download it from the course
Teams folder — see the [Downloads](../downloads.md) page). Use the same block
swap as [Lab 5](Lab5), Activity 4, drawing lines from `Import RTL-SDR Data` to
**both** `Decimation Stage` and `Spectrum Analyzer - Received Signal`, and set
the simulation mode to **Normal**.

That capture is *coherently* encoded, so on the fallback you must put the
Manual Switch from step 2 **back** on the `QPSK Demodulator Baseband`. Ignore
`dqpsk_ascii_msg.mat` entirely — the carrier synchronizer never locks on it in
either switch position.
```

*For more detail on ASCII encoding and message transmission, see Sec. 12.5 and 12.7 in SDR textbook.*

## Why You Had to Switch to DQPSK

QPSK has a subtle problem: the 4th-power frequency estimation trick from Lab 6 can't tell the difference between the true carrier phase and the true phase plus any multiple of 90 degrees — so a receiver can lock on 90, 180, or 270 degrees rotated from the truth and have no way to know it (this is called phase ambiguity).

Nothing you have looked at so far would reveal it. A constellation rotated by 90 degrees still shows four clean clusters sitting on the reference markers; the lock is just as tight and the EVM just as low. What it *does* change is every demapped bit, and that is what frame synchronization depends on. Measured on this hardware, with the coherent demodulator selected and a constellation locked at 0.98: the preamble correlation came back at **−39** on one capture — the framing working perfectly on an inverted preamble, which fails a "greater than 33" test — and near **zero** on another, a 90-degree lock. Only a 0-degree lock gives +39. That is a one-in-four chance of a lab that works, which is why step 2 moved you to the differential path.

Differential encoding sidesteps the problem entirely by transmitting information in the change between consecutive symbols rather than their absolute value: $b[n] = a[n]\, b[n-1]$, where $a[n]$ is the data-bearing unit-magnitude symbol and $b[n-1]$ is the previously transmitted symbol. The receiver recovers $a[n]$ by multiplying by the conjugate of the previous received symbol:

$$\hat{a}[n] = r[n]\, r^*[n-1]$$

If the whole received constellation is rotated by some unknown ambiguity $\theta_0$ — i.e. $r[n] = b[n]e^{j\theta_0}$ for every $n$ — then $\hat{a}[n] = b[n]e^{j\theta_0}\, \big(b[n-1]e^{j\theta_0}\big)^* = b[n]b^*[n-1] = a[n]$: the $e^{j\theta_0}$ terms cancel exactly, regardless of what $\theta_0$ is. That's why differential encoding is immune to phase ambiguity.

**Optional, if you finish early:** open `digital/simulation/differential_coding/QPSK_diff_encode_decode.slx`. It has a Manual Switch that swaps the normally-received sequence for one carrying a built-in 180° phase ambiguity. Flip it back and forth and confirm the decoded bits come out identical either way — the rotation cancels, exactly as the algebra above predicts. Then, if you want to see the failure for yourself, put your receiver's demodulator switch back on `QPSK Demodulator Baseband` and watch the correlation collapse and the frame strobe stop firing on a signal that still looks perfect.

*For more detail on phase ambiguity and differential encoding, see Sec. 11.9-11.10 in SDR textbook.*

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

1. The scope showing your frame synchronization indicator locking on (the Frame Strobe firing, the correlation peaks, or both).
2. The decoded ASCII text from the Command Window — several consecutive lines, so the frame counter is visible — and the peak correlation value you measured.
3. 2-3 sentences: what would your receiver see if the frame sync word were never found (e.g., because the correlation peaked just below the threshold)? Would it decode garbage, nothing at all, or something else? Note that the constellation can look perfect while this is happening.
4. Your documentation statement.
