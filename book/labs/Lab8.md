# Lab 8: Capstone — Image Transmission with an Integrity Check

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.8.)

## Overview

This is your capstone SDR lab: the instructor will transmit an actual image over the air using the same QPSK link you've been building since Lab 5, and you'll receive and reconstruct it on your own RTL-SDR. We're also adding a short integrity-check exercise of our own, tying back to the parity/CRC/Hamming code lecture — the SDR textbook's exercise stops at "did the image come through," and we're extending it to "how would you know if it didn't."

As with Labs 6 and 7, only the instructor transmits; the whole class receives independently. This receiver is differentially encoded end to end — the same thing you switched on by hand in Lab 7 — so there is no demodulator switch to set here. It is already the version that works.

## Aims of the Lab

- Receive and reconstruct a real image transmitted live over RF.
- Implement a simple checksum comparison to verify data integrity, connecting back to the error-detection concepts from lecture.
- Reflect on how this lab's receiver builds on everything from Lab 1 through Lab 7.

## Setup

The instructor will announce a transmit frequency and transmit one of the sample images from the `rtlsdr_book_library/` folder (`image1.mat` through `image7.mat`), along with the correct checksum for it at the end of class.

## Activity 1: Receive and Reconstruct the Image

1. Open `digital/rtlsdr_rx/rtlsdr_QPSK_image_transfer.slx` and set three things before running it, the same three as Lab 7:
    - **`QPSK Signal Frequency (Hz)`** to the announced frequency. It ships at `602e6`.
    - **`Tuner Gain (dB)` to `40`.** This model ships at `20` — closer than the others, still not enough. The coarse frequency estimator inside it behaves the same way as Lab 6's.
    - **`Frequency correction (ppm)`** on the `RTL-SDR Receiver` block, to your figure from [Lab 2](Lab2).
2. Run it once the instructor starts transmitting, and **leave it running**. The image is sent one pixel column per frame at about two frames a second, so a complete 100-column pass takes roughly 50 seconds. The model's Stop Time ships at `60`, which is about right for one pass; raise it if you want more.
3. Watch the **Command Window**: it prints `Searching for first frame...` and then `Picture Column Number: 46`, `47`, `48` … as each column arrives. Which number it starts from just depends on where in the image the transmitter happened to be when you started. The image itself appears in a MATLAB figure, redrawn as it fills in, and starts out white because the receiver initializes all 100 columns to 255.
4. The receiver also publishes the reconstructed image to the base workspace as a 100×100 `uint8` variable named `image`. You'll use that in Activity 2.
5. **Expect some columns to be missing**, especially if you started mid-pass. A frame whose header fails the integrity check is discarded rather than guessed at, and that column stays white. Count how many columns actually arrived:

```matlab
% how many of the 100 columns are not still blank white?
nArrived = sum(any(image ~= 255, 1))
```

    Letting it run through a second pass fills in most of what the first one missed, since the receiver keeps the columns it already has.
6. If you want to see how the payload is put back together, the frame/protocol parameters (preamble, frame length, header fields) are defined in `rtlsdr_book_library/image_receive.m`, and the actual byte-to-pixel reconstruction lives in the **Image Reconstruction** MATLAB Function block inside the shared `rtlsdr_book_library.slx` library.

```{note}
**If the live signal is too weak from where you're sitting**, fall back to one
of `digital/rtlsdr_rx/rec_data/dqpsk_image1.mat`, `dqpsk_image2.mat` or
`dqpsk_image7.mat` from the course Teams folder (see the
[Downloads](../downloads.md) page). Use the same block swap as [Lab 5](Lab5),
Activity 4, drawing lines from `Import RTL-SDR Data` to **both**
`Decimation Stage` and `Spectrum Analyzer - Received Signal`, and set the
simulation mode to **Normal**. Check the import block's filename — it ships
pointing at `dqpsk_image2.mat`.

On the fallback, the image is whichever one that capture contains, not the one
the instructor transmitted, so the announced checksum won't apply. Say in your
write-up that you used the fallback.
```

*For more detail on transmitting images across the desktop link, see Sec. 12.8 in SDR textbook.*

## Some Math: Why a Sum Isn't Enough, and What CRC Does Instead

Our checksum, chk = (sum of all bytes) mod 256, is blind to a specific, common failure: if one byte increases by some amount $k$ (mod 256) due to a bit error, and any other byte decreases by exactly $k$, the total sum — and therefore the checksum — is completely unchanged. Two independent bit errors can silently cancel out.

A **CRC** (cyclic redundancy check) closes that gap by working in a different algebraic structure entirely. Treat the message bits as the coefficients of a polynomial $M(x)$ over $GF(2)$ (binary field arithmetic, where addition is XOR), and agree on a fixed generator polynomial $G(x)$ of degree $r$. The transmitter computes the remainder of $M(x)\cdot x^r$ divided by $G(x)$ (using mod-2 polynomial division) and appends it as $r$ check bits, so that the full transmitted codeword $T(x)$ divides evenly by $G(x)$ with zero remainder. The receiver simply repeats that division on whatever it received: a nonzero remainder means an error occurred somewhere.

The payoff of choosing $G(x)$ carefully (a well-chosen, primitive polynomial) is that CRC is guaranteed to catch every single-bit error, every error burst shorter than $r$ bits, and the overwhelming majority of longer bursts and multi-bit patterns, specifically because an undetected error would require the error pattern itself to be an exact multiple of $G(x)$, which random noise essentially never produces. That's a much stronger guarantee than our simple sum can offer.

## Activity 2: A Basic Integrity Check

Real digital systems don't just hope the data arrived correctly — they check.

1. Compute a checksum over what you received:

```matlab
% The receiver publishes the reconstructed image to the base workspace as `image`,
% a 100x100 array of pixel values 0-255. The (:) flattens it so sum() returns a
% single number rather than one sum per column. uint32 stops the sum wrapping
% before the mod does it deliberately.
rxChecksum = mod(sum(uint32(image(:))), 256)
nArrived   = sum(any(image ~= 255, 1))      % how many columns actually arrived
```

```{warning}
`image` is also the name of a built-in MATLAB function, so while that variable
exists in your workspace you cannot call `image(...)` to plot anything. Clear it
or copy it to another name when you're done.
```

2. Wait for the instructor to announce the correct checksum for the transmitted image at the end of class.
3. Compare your `rxChecksum` against it — **and report `nArrived` alongside it.** If even one column is missing, your checksum will not match and cannot match: a blank column contributes 100 pixels of 255 instead of the real values, which moves the sum by an essentially arbitrary amount mod 256. In a measured run with 99 of 100 columns, the checksum came back 73 against a true value of 28 — no closer than a wrong answer.

    This is the most useful thing in the exercise, so don't skip past it. A checksum tells you *whether* the data matches, and nothing about *how badly* it differs: one missing column and 100 missing columns are equally "wrong." That's a property of the check, not a flaw in your receiver, and it is why real protocols checksum each frame separately and re-request the ones that fail rather than checksumming the whole file once at the end.
4. Think through the blind-spot scenario from the math above (two errors that cancel in the sum) and be ready to describe one for the write-up.
5. If you want to see a step closer to a real implementation, look up `comm.CRCGenerator` and `comm.CRCDetector` in MATLAB's documentation and try replacing your checksum with an actual CRC.

This sum-based checksum is a deliberately simple stand-in for the CRC/Hamming techniques above — good enough to catch a clean, uncorrupted transfer, but with the blind spot described above. (This checksum/CRC exercise is our own addition tying back to lecture — it isn't in the SDR textbook's version of this lab.)

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

1. The image you reconstructed, alongside your `rxChecksum`, your `nArrived` column count, and the instructor's announced value — and a sentence on whether a mismatch tells you the image is wrong or only that it is incomplete.
2. 2-3 sentences on a bit-error scenario a simple sum-based checksum would fail to catch, and how CRC or a parity/Hamming code would do better.
3. A short paragraph (5-8 sentences) reflecting on the semester's SDR labs: which piece of the receiver chain (spectrum viewing, complex baseband, AM/FM demodulation, symbol synchronization, framing, or error checking) did you find hardest to get working, and why?
4. Your documentation statement.
