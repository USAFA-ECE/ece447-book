# Skills Review

## Due NLT Lesson 4, at the start of class, on Gradescope

ECE 447 builds directly on ECE 333. This diagnostic is a graded assessment of the
prerequisite skills the first several lessons assume. Each section names the ECE 447
lesson that builds on it, and the last page tells you what to review if you come up short.

```{important}
Include a **documentation statement with each problem**, written on that problem's page --
not a single statement for the whole assignment. Problems missing a documentation statement
will not be graded.
```

<embed src="../_static/Skills_Review_F26.pdf" width="100%" height="600px" type="application/pdf">

If you have trouble viewing, you can download the PDF [here](../_static/Skills_Review_F26.pdf).

---

The two sections below are **not part of the graded Skills Review**. The first one is to make sure you are ready for Lab 1. The second covers decibels in more detail than you may have received in previous courses. Work through both sections on your own.

## Before Lab 1: MATLAB and RTL-SDR setup

```{warning}
Lab 1 begins on **Lesson 3** -- before this assignment is even
due -- and you cannot participate in the lab without a working toolchain. If something will not install, you need time to get help beforehand.
```

1. Confirm you have **MATLAB R2021a or later** with the **Communications Toolbox, DSP System Toolbox, and Signal Processing Toolbox**. Type in the following command in MATLAB:

   ```matlab
   ver
   ```

   Check that the release and the toolboxes lines appear.

2. Install the **RTL-SDR support package**: Home -> Add-Ons -> Get Hardware Support Packages ->
   *Communications Toolbox Support Package for RTL-SDR Radio*.

3. With your RTL-SDR dongle plugged in, run:

   ```matlab
   sdrinfo
   ```

   If it reports no radio found, work the troubleshooting steps on this website and then come
   to EI **before Lesson 3**.

4. Download the course support files from the [Downloads](../downloads.md) page and confirm
   `rtlsdr_book_library.slx` opens in Simulink without error.

```{tip}
If you cannot get hardware working before Lesson 3, come see me early.
```

## Decibels

Decibels are in every lab, link budget, and SNR calculation in
ECE 447. Read the dB primer below, and then work
through the problems below that. They are not collected.

1. A receiver delivers 2 mW into a load. Express this power in **dBm**.
2. That signal passes through an amplifier with 12 dB of gain, then a cable with 3 dB of loss.
   Give the output power in **dBm** and in **mW**.
3. The noise power at the same point is $-85$ dBm. What is the SNR **in dB**?
4. Why do engineers add dB values instead of multiplying ratios?

<embed src="../_static/ydi_understandingdb.pdf" width="100%" height="600px" type="application/pdf">

If you have trouble viewing, you can download the PDF [here](../_static/ydi_understandingdb.pdf).

```{dropdown} Check your answers
1. $10\log_{10}(2) = 3.0$ dBm
2. $3.0 + 12 - 3 = 12.0$ dBm, which is $10^{12.0/10} = 15.9$ mW
3. $12.0 - (-85) = 97.0$ dB
4. The dB scale is logarithmic, so a product of linear ratios becomes a sum of dB values.
   Cascaded gains and losses add, which turns a link budget into arithmetic.
```
