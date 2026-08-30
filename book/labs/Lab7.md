# Lab 7: A Digital Communications Protocol — ASCII Messaging

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.4-12.7.)

## Overview

A synchronized QPSK link (Lab 6) only gets you a clean stream of symbols — it doesn't tell you where a message starts. Today you'll receive a live, framed, ASCII-encoded message from the instructor's PLUTO and decode actual text out of the air. As in Lab 6, only the instructor transmits; the whole class receives simultaneously on individual RTL-SDRs.

## Aims of the Lab

- Write down the cross-correlation frame-detection metric and use it to explain how the receiver locates a known sync word inside a continuous symbol stream.
- Decode a real over-the-air ASCII message end-to-end.

## Some Math: Finding the Frame with Cross-Correlation

The transmitter prepends every message with a known sequence of symbols, $c[0], c[1], \dots, c[L-1]$ (the sync word), that both transmitter and receiver agree on ahead of time. The receiver slides a window of length $L$ across its incoming symbol stream $r[n]$ and computes the cross-correlation at every position:

$$R[n] = \sum_{k=0}^{L-1} r[n+k]\, c^*[k]$$

When the window is aligned exactly with the transmitted sync word, every term in the sum adds constructively (since $r[n+k] \approx c[k]$ there), producing a sharp peak in $|R[n]|$. Anywhere else, the received symbols are essentially uncorrelated with $c[k]$, so the terms partially cancel and $|R[n]|$ stays small. Detecting that peak (usually by comparing it against a threshold) tells the receiver exactly which sample index the message frame starts at — this correlation is precisely the matched filter operation, so named because $c^*[k]$ is matched to the exact known waveform you're searching for.

## Setup

The instructor will announce a transmit frequency and run `digital/pluto_tx/pluto_QPSK_ascii_message.slx`, which repeatedly transmits a short text message framed with a known sync word.

## Activity 1: Frame Synchronization

1. Run `digital/rtlsdr_rx/rtlsdr_QPSK_ascii_message.slx`. Internally, this receiver computes exactly the $R[n]$ correlation above against the known sync word.
2. The model doesn't display the frame-sync signal by default, so add a readout yourself: open the **Frame Synchronisation** subsystem, right-click the **Frame Strobe** output signal, and connect a Scope (or enable signal logging) to it. You can do the same on the Matched Filter Correlator's **Correlation Amplitudes** output to watch the correlation itself.
3. Run the model and confirm the strobe is firing — each pulse is the receiver declaring "a sync word lines up here," which is what tells it where the message frame begins. That scope is the figure you'll submit.

*For more detail on data and frame synchronization, see Sec. 12.6 in SDR textbook.*

## Activity 2: Decode the Message

1. With frame sync locked, let the receiver decode the received symbols into ASCII characters.
2. Confirm you can read the transmitted text.
3. If the instructor changes the message partway through class, confirm your receiver picks up the new text too.
4. **If you're not receiving a clean decode**, fall back to `digital/rtlsdr_rx/rec_data/qpsk_ascii_msg.mat` to complete the assignment. There is also a differentially-encoded capture, `digital/rtlsdr_rx/rec_data/dqpsk_ascii_msg.mat` — if you use that one, you must also open the **Demodulation & Phase Ambiguity Correction** subsystem and flip its Manual Switch from the QPSK demodulator to the **DQPSK Demodulator Baseband**, or the text will decode as garbage. To switch a receiver model from live hardware to a recorded file, use the same block swap you did in [Lab 5](Lab5), Activity 4.

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
**Copy your figures, do not screenshot them.** In a MATLAB figure window use
**Edit > Copy Figure** (or run `copygraphics(gcf)` at the command line). In a
Simulink scope or Spectrum Analyzer, use that scope's own **File > Print to
Figure**, then copy the figure it creates. Paste straight into your document.
That gives you the plot at full resolution with the axes, tick labels, and
titles sharp. Phone photographs of a monitor, cropped screen grabs, and blurry
captures make the plots unreadable.
```

Submit a single PDF to Gradescope containing:

1. The scope showing your frame synchronization indicator locking on (e.g., the correlation peak or sync flag).
2. The decoded ASCII message text you received.
3. 2-3 sentences: what would your receiver see if the frame sync word were never found (e.g., due to a very weak signal)? Would it decode garbage, nothing at all, or something else?
4. Your documentation statement.
