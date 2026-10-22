# Lab 7: A Digital Communications Protocol — ASCII Messaging

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.4-12.7.)

## Overview

A synchronized QPSK link (Lab 6) only gets you a clean stream of symbols — it doesn't tell you where a message starts. Today you'll take a framed, ASCII-encoded transmission and decode actual text out of it.

You'll work from a capture that ships with the SDR textbook, the same way you did in Lab 6, Activity 3 — see the note at the start of Activity 1. The instructor will also transmit the signal live so you can see it arrive on the spectrum analyzer, but the decoding you submit comes from the recording.

## Aims of the Lab

- Write down the cross-correlation frame-detection metric and use it to explain how the receiver locates a known sync word inside a continuous symbol stream.
- Decode a real over-the-air ASCII message end-to-end.

## Some Math: Finding the Frame with Cross-Correlation

The transmitter prepends every message with a known sequence of symbols, $c[0], c[1], \dots, c[L-1]$ (the sync word), that both transmitter and receiver agree on ahead of time. The receiver slides a window of length $L$ across its incoming symbol stream $r[n]$ and computes the cross-correlation at every position:

$$R[n] = \sum_{k=0}^{L-1} r[n+k]\, c^*[k]$$

When the window is aligned exactly with the transmitted sync word, every term in the sum adds constructively (since $r[n+k] \approx c[k]$ there), producing a sharp peak in $|R[n]|$. Anywhere else, the received symbols are essentially uncorrelated with $c[k]$, so the terms partially cancel and $|R[n]|$ stays small. Detecting that peak (usually by comparing it against a threshold) tells the receiver exactly which sample index the message frame starts at — this correlation is precisely the matched filter operation, so named because $c^*[k]$ is matched to the exact known waveform you're searching for.

## Setup

Download `qpsk_ascii_msg.mat` from the course Teams folder (see the [Downloads](../downloads.md) page) and put it in `digital/rtlsdr_rx/rec_data/`. It is about 115 MB, so do this before class. It is a real over-the-air RTL-SDR capture recorded for the SDR textbook, not a simulation.

The instructor will also announce a frequency and transmit the signal live. Tune to it with `rtlsdr_QPSK_ascii_message.slx` if you want to see the framed signal on `Spectrum Analyzer - Received Signal` — set `Tuner Gain (dB)` to about `40` and enter your [Lab 2](Lab2) ppm figure first, as in Lab 6. The decode you submit comes from the recording.

## Activity 1: Frame Synchronization

```{note}
**This activity runs from the recorded capture.** Frame detection is stricter
than anything earlier in the course: the receiver declares a frame only when
the correlation against the 39-bit sync word reaches 33, so it tolerates a
handful of wrong bits and no more. A signal can produce a textbook-perfect
constellation and still never cross that threshold, in which case the receiver
decodes nothing while looking completely healthy. The textbook's capture
crosses it every time, which is what makes the correlation visible as a
measurement rather than a lottery.
```

1. Open `digital/rtlsdr_rx/rtlsdr_QPSK_ascii_message.slx` and swap it from live hardware to the file — the same swap you did in [Lab 5](Lab5), Activity 4:
    - Right-click `RTL-SDR Receiver` and choose **Comment Out**.
    - Right-click the greyed-out `Import RTL-SDR Data` block and choose **Comment In**. Its filename already reads `rec_data/qpsk_ascii_msg.mat`.
    - Draw signal lines from the `Import RTL-SDR Data` output to the **two** places the receiver's output used to go: `Decimation Stage` and `Spectrum Analyzer - Received Signal`.

    Keep MATLAB's **Current Folder** on `digital/rtlsdr_rx`, since that filename is relative to it.
2. Set the simulation mode to **Normal** and the **Stop Time** to `40`. The model ships in *Accelerator* at a stop time of `60`, which is meant for live hardware; the recording is 60 seconds long, so anything up to 60 works.
3. The model doesn't display the frame-sync signal, so add a readout yourself. The signals are deeper in the model than you might expect — inside `Decimation, Demodulation, Frame Synch & ASCII Decoding`, then `Demodulation & Frame Synch`, then `Frame Synchronisation`. In there:
    - right-click the **Frame Strobe** signal and connect a Scope (or enable signal logging on it);
    - do the same inside `Matched Filter Correlator` on its **Correlation Amplitudes** output, to watch the $R[n]$ correlation itself.
4. Run it and confirm the strobe is firing — each pulse is the receiver declaring "a sync word lines up here," which is what tells it where the message frame begins. That scope is the figure you'll submit.
5. Look at the correlation trace alongside it. On this capture the peaks reach **39**, the full length of the sync word, meaning every bit of the preamble matched; between frames the correlation sits down around 3. That ratio is why a simple threshold works at all, and it is worth seeing before you trust it.

*For more detail on data and frame synchronization, see Sec. 12.6 in SDR textbook.*

## Activity 2: Decode the Message

1. With frame sync firing, the receiver decodes each frame's payload into ASCII characters.
2. **The decoded text prints to the MATLAB Command Window**, not to any scope or display in the model — a `disp` inside the library's decoder writes one line per frame. Watch the Command Window as the simulation runs.
3. Confirm you can read the transmitted text. On this capture you should see `Hello World!` followed by a three-digit frame counter that increments every frame — `Hello World! 068`, `Hello World! 069`, and so on, wrapping at 100. The transmitter appends that counter to every frame, so consecutive numbers are your evidence that frames are arriving in order and none are being dropped.
4. Copy a few consecutive lines for the write-up.

```{warning}
`rec_data/dqpsk_ascii_msg.mat`, the differentially-encoded capture, does **not**
work with this model — the carrier synchronizer never locks on it, in either
position of the Manual Switch, so no amount of switching demodulators will
decode it. Use `qpsk_ascii_msg.mat`.
```

*For more detail on ASCII encoding and message transmission, see Sec. 12.5 and 12.7 in SDR textbook.*

## Optional Extension

QPSK has a subtle problem: the 4th-power frequency estimation trick from Lab 6 can't tell the difference between the true carrier phase and the true phase plus any multiple of 90 degrees — so a receiver can lock on 90, 180, or 270 degrees rotated from the truth and have no way to know it (this is called phase ambiguity).

Differential encoding sidesteps the problem entirely by transmitting information in the change between consecutive symbols rather than their absolute value: $b[n] = a[n]\, b[n-1]$, where $a[n]$ is the data-bearing unit-magnitude symbol and $b[n-1]$ is the previously transmitted symbol. The receiver recovers $a[n]$ by multiplying by the conjugate of the previous received symbol:

$$\hat{a}[n] = r[n]\, r^*[n-1]$$

If the whole received constellation is rotated by some unknown ambiguity $\theta_0$ — i.e. $r[n] = b[n]e^{j\theta_0}$ for every $n$ — then $\hat{a}[n] = b[n]e^{j\theta_0}\, \big(b[n-1]e^{j\theta_0}\big)^* = b[n]b^*[n-1] = a[n]$: the $e^{j\theta_0}$ terms cancel exactly, regardless of what $\theta_0$ is. That's why differential encoding is immune to phase ambiguity.

If you finish early, open `digital/simulation/differential_coding/QPSK_diff_encode_decode.slx`. It has a Manual Switch that swaps the normally-received sequence for one carrying a built-in 180° phase ambiguity. Flip it back and forth and confirm the decoded bits come out identical either way — the rotation cancels, exactly as the algebra above predicts.

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
