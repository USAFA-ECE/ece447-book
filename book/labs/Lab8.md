# Lab 8: Capstone — Image Transmission with an Integrity Check

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 12.8.)

## Overview

This is your capstone SDR lab: the instructor's PLUTO will transmit an actual image over the air using the same QPSK link you've been building since Lab 5, and you'll receive and reconstruct it on your own RTL-SDR. We're also adding a short integrity-check exercise of our own, tying back to the parity/CRC/Hamming code lecture — the SDR textbook's exercise stops at "did the image come through," and we're extending it to "how would you know if it didn't."

As with Labs 6 and 7, only the instructor transmits; the whole class receives independently.

## Aims of the Lab

- Receive and reconstruct a real image transmitted live over RF.
- Implement a simple checksum comparison to verify data integrity, connecting back to the error-detection concepts from lecture.
- Reflect on how this lab's receiver builds on everything from Lab 1 through Lab 7.

## Setup

The instructor will announce a transmit frequency and run `digital/pluto_tx/pluto_QPSK_image_transfer.slx`, transmitting one of the sample images from the `rtlsdr_book_library/` folder (`image1.mat` through `image7.mat`, e.g. `rtlsdr_book_library/image3.mat`).

## Activity 1: Receive and Reconstruct the Image

1. Run `digital/rtlsdr_rx/rtlsdr_QPSK_image_transfer.slx`. This receiver reuses the same synchronization techniques from Lab 6 and the same framing approach from Lab 7, just with image bytes in the payload instead of ASCII text.
2. Once it locks on, confirm you see the transmitted image rendered in MATLAB.
3. Open `rtlsdr_book_library/image_receive.m` if you want to see the supporting reconstruction code — how the received bytes are reshaped back into an image.
4. **If your reception is unreliable**, fall back to one of `digital/rtlsdr_rx/rec_data/dqpsk_image1.mat`, `digital/rtlsdr_rx/rec_data/dqpsk_image2.mat`, or `digital/rtlsdr_rx/rec_data/dqpsk_image7.mat` to complete the assignment.

*For more detail on transmitting images across the desktop link, see Sec. 12.8 in SDR textbook.*

## Some Math: Why a Sum Isn't Enough, and What CRC Does Instead

Our checksum, chk = (sum of all bytes) mod 256, is blind to a specific, common failure: if one byte increases by some amount $k$ (mod 256) due to a bit error, and any other byte decreases by exactly $k$, the total sum — and therefore the checksum — is completely unchanged. Two independent bit errors can silently cancel out.

A **CRC** (cyclic redundancy check) closes that gap by working in a different algebraic structure entirely. Treat the message bits as the coefficients of a polynomial $M(x)$ over $GF(2)$ (binary field arithmetic, where addition is XOR), and agree on a fixed generator polynomial $G(x)$ of degree $r$. The transmitter computes the remainder of $M(x)\cdot x^r$ divided by $G(x)$ (using mod-2 polynomial division) and appends it as $r$ check bits, so that the full transmitted codeword $T(x)$ divides evenly by $G(x)$ with zero remainder. The receiver simply repeats that division on whatever it received: a nonzero remainder means an error occurred somewhere.

The payoff of choosing $G(x)$ carefully (a well-chosen, primitive polynomial) is that CRC is guaranteed to catch every single-bit error, every error burst shorter than $r$ bits, and the overwhelming majority of longer bursts and multi-bit patterns, specifically because an undetected error would require the error pattern itself to be an exact multiple of $G(x)$, which random noise essentially never produces. That's a much stronger guarantee than our simple sum can offer.

## Activity 2: A Basic Integrity Check

Real digital systems don't just hope the data arrived correctly — they check.

1. Add a simple checksum to your receiver:

```matlab
% After reconstructing the received image bytes into rxBytes:
rxChecksum = mod(sum(uint32(rxBytes)), 256);
```

2. Wait for the instructor to announce the correct checksum value for the transmitted image at the end of class.
3. Compare your `rxChecksum` against it and note whether they match.
4. Think through the blind-spot scenario from the math above (two errors that cancel in the sum) and be ready to describe one for the write-up.
5. If you want to see a step closer to a real implementation, look up `comm.CRCGenerator` and `comm.CRCDetector` in MATLAB's documentation and try replacing your checksum with an actual CRC.

This sum-based checksum is a deliberately simple stand-in for the CRC/Hamming techniques above — good enough to catch a clean, uncorrupted transfer, but with the blind spot described above. (This checksum/CRC exercise is our own addition tying back to lecture — it isn't in the SDR textbook's version of this lab.)

## Assignment

Submit a single PDF to Gradescope containing:

1. The image you reconstructed, alongside a note of whether your checksum matched the instructor's announced value.
2. 2-3 sentences on a bit-error scenario a simple sum-based checksum would fail to catch, and how CRC or a parity/Hamming code would do better.
3. A short paragraph (5-8 sentences) reflecting on the semester's SDR labs: which piece of the receiver chain (spectrum viewing, complex baseband, AM/FM demodulation, symbol synchronization, framing, or error checking) did you find hardest to get working, and why?
4. Your documentation statement.
