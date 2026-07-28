# Skills Review

## Due NLT Lesson 3, at the start of class, on Gradescope

```{important}
**Part D (MATLAB & RTL-SDR setup) is due NLT Lesson 2.** Lab 1 starts in Lesson 3 and you
will not be able to participate without a working toolchain. Do not leave it until the night before.
```

## Purpose

ECE 447 builds directly on ECE 333 (Signals & Systems) and ECE 346 / Math 356 (probability).
This assignment is a **bridge, not a filter**. It has three jobs:

1. Reactivate the handful of ECE 333 results that this course leans on hardest in the first three weeks.
2. Introduce two tools that ECE 333 does *not* cover but that ECE 447 uses constantly — **decibels** and **two-sided spectra of modulated signals**.
3. Confirm your MATLAB + RTL-SDR installation works *before* Lab 1.

Nothing here should be brand new except where explicitly flagged as **[NEW]**. If a problem feels
unfamiliar, that is useful information — for you and for me. Flag it in Part E and come to EI early.

## Directions

- Collaboration is authorized as noted in the syllabus Collaboration policy.
- Include a **Documentation statement**. If you used a graphing website, a solver, or GenAI, say so.
- Work should be organized using the Known/Given, Find, Solution, Answer method.
- Answers should be clearly indicated by a box.
- Use engineering notation with proper units.
- Submit to Gradescope with pages assigned to each problem. Include all MATLAB code and figures.

---

## Part A — Signals, spectra, and power

### Problem 1: Complex exponentials and two-sided spectra

Let

$$x(t) = 3\cos\left(2\pi (1000) t - \tfrac{\pi}{4}\right) + 2\sin\left(2\pi (2500) t\right)$$

1. Write $x(t)$ as a sum of complex exponentials of the form $\sum_k c_k e^{j2\pi f_k t}$. Give each $c_k$ in polar form.
2. Sketch the **two-sided** magnitude spectrum $|X(f)|$ and phase spectrum $\angle X(f)$. Label the frequency axis in Hz and mark negative frequencies explicitly.
3. Is $x(t)$ an energy signal or a power signal? Compute the quantity that is finite.

```{note}
Nearly every spectrum you draw for the rest of this course is two-sided. If negative
frequencies still feel like bookkeeping rather than something real, review L&D Ch. 3
before Lesson 6 — the RTL-SDR delivers complex baseband samples, and the negative half
of the spectrum carries real information there.
```

### Problem 2: Power ratios in decibels **[NEW]**

Decibels are not covered in ECE 333, but every lab, link budget, and SNR calculation in
ECE 447 uses them. Read L&D Sec. 2.x on dB units (or any standard reference) and then:

1. A receiver delivers 2 mW into a load. Express this power in **dBm**.
2. That signal passes through an amplifier with 12 dB of gain, then a cable with 3 dB of loss.
   Give the output power in **dBm** and in **mW**.
3. The noise power at the same point is $-85$ dBm. What is the SNR **in dB**?
4. In one or two sentences: why do engineers add dB values instead of multiplying ratios?

---

## Part B — Fourier analysis

### Problem 3: The frequency-shifting property

You met this in ECE 333 as a Fourier transform property, and again in Project 2 (Amplitude
Modulation). Here it is the single most important result in the first block of ECE 447.

A baseband message $m(t)$ has the triangular spectrum $M(f)$ shown below: $|M(f)|$ rises
linearly from $0$ at $f = -4$ kHz to a peak of $1$ at $f = 0$, then falls linearly back to
$0$ at $f = +4$ kHz.

1. Sketch, to scale and with labeled axes, the spectrum of

   $$s(t) = m(t)\cos\left(2\pi (50000) t\right)$$

2. State the bandwidth of $s(t)$ in Hz. How does it compare to the bandwidth of $m(t)$?
3. Now sketch the spectrum of $s(t)\cos(2\pi (50000) t)$ — that is, multiply by the carrier a
   *second* time. What must you do to recover $m(t)$ from this result?
4. Part 3 is the entire idea behind coherent demodulation. In one sentence, what goes wrong
   if the receiver's carrier is at $50{,}001$ Hz instead of $50{,}000$ Hz?

### Problem 4: Raised-cosine pulse and its Fourier series

A *raised cosine* is a useful pulse shape in communications because it has far weaker
high-frequency sidelobes than a rectangular pulse, and therefore needs less bandwidth.
Define

$$f(t) = \begin{cases} 1 + \cos(2\pi t), & |t| < 0.5 \\ 0, & \text{elsewhere} \end{cases}$$

1. Sketch $f(t)$ by hand. It looks roughly Gaussian, doesn't it? Look up the Fourier transform
   of a Gaussian — also a Gaussian — and sketch that too. A Gaussian pulse has very small tails
   (i.e. few high-frequency terms) in **both** domains.
2. Plot $f(t)$ over $-1 < t < 1$ in MATLAB. One approach:

   ```matlab
   t     = -1:.001:1;      % time axis in seconds
   t_cos = -?:?:?;         % time axis for just the cosine, -0.5 < t < 0.5
   f_t   = [zeros(??) 1+cos(2*pi*t_cos) zeros(??)];   % you can figure out the ?? yourself

   plot(t,f_t)
   title('Raised Cosine 1+cos(2\pi t)')
   xlabel('time [sec]')
   ```

3. Using the Fourier coefficient integral, find the **exponential** Fourier series coefficients
   $F_n$ for the raised-cosine pulse treated as one period of a periodic signal with period
   $T_0 = 2$ (i.e. over the interval $(-1,1)$), where

   $$f(t) = \sum_{n=-\infty}^{\infty} F_n e^{jn\omega_0 t}$$

   Give a closed-form expression for $F_n$. Handle $n = 0$ and $n = \pm 2$ carefully.

4. In MATLAB, plot the partial-sum reconstruction from your $F_n$ superimposed on your Problem 4.2
   plot, for $N = 1$, $N = 2$, $N = 3$, and $N = N^\*$, where $N^\*$ is the value at which the sum
   visually matches the original (your judgment). Report your $N^\*$. Include code and all four figures.

5. Repeat part 4 over the interval $-5 < t < 5$. How does the plot differ from the single pulse
   you plotted in parts 2 and 4? **Explain why** — this difference is the reason pulse trains,
   not single pulses, set the bandwidth of a digital link.

---

## Part C — Filtering and sampling

### Problem 5: Convolution and ideal filtering

Take the *periodic* raised-cosine train from Problem 4.5 ($T_0 = 2$ s, so $f_0 = 0.5$ Hz).
Pass it through an ideal lowpass filter with cutoff $f_c = 1.25$ Hz and unity passband gain.

1. Which harmonics $n$ survive the filter?
2. Write the filter output $y(t)$ as an explicit finite sum of real sinusoids (not complex exponentials).
3. Sketch $y(t)$ over one period, roughly to scale, alongside the unfiltered pulse train.
4. In ECE 333 you computed filter outputs two ways: convolution in time, or multiplication in
   frequency. Which did you just use, and why was it the easier choice here?

### Problem 6: Sampling and aliasing

Let $x(t) = \cos\left(2\pi (7000) t\right)$, sampled at $f_s = 10$ kHz.

1. What is the Nyquist rate for $x(t)$? Is $f_s$ adequate?
2. The samples are reconstructed with an ideal lowpass filter of cutoff $f_s/2$. What frequency
   does the reconstructed signal have? Show the spectral reasoning (sketch the sampled spectrum).
3. In MATLAB, plot $x(t)$ finely sampled, the sample points at $f_s$ (use `stem` or markers), and
   the aliased sinusoid from part 2 on the same axes over $0 \le t \le 2$ ms. Confirm visually that
   the alias passes through every sample point.
4. In one sentence: what does this tell you about the anti-alias filter in front of an ADC?

---

## Part D — MATLAB and RTL-SDR readiness **[NEW]** — due NLT Lesson 2

Lab 1 begins in Lesson 3. This part exists so that installation problems surface now, not then.

1. Confirm you have **MATLAB R2021a or later** with the **Communications Toolbox**. Run:

   ```matlab
   ver
   ```

   and submit a screenshot showing the MATLAB release and the Communications Toolbox line.

2. Install the **RTL-SDR support package** (Home → Add-Ons → Get Hardware Support Packages →
   *Communications Toolbox Support Package for RTL-SDR Radio*).

3. With your RTL-SDR dongle plugged in, run:

   ```matlab
   sdrinfo
   ```

   and submit the output. If it reports no radio found, work the troubleshooting steps on the
   course website, then come to EI **before Lesson 3**.

4. Download the course support files from the [Downloads](../downloads.md) page and confirm
   `rtlsdr_book_library.slx` opens in Simulink without error.

```{tip}
If you cannot get hardware working before Lesson 3, still submit Parts 1–2 and say so.
You can pair with a partner for Lab 1 while we sort it out — but tell me early.
```

---

## Part E — Self-assessment (completion grade only)

Rate your current confidence on each prerequisite, 1 (no recollection) to 5 (could teach it).
**Answer honestly — this is graded on completion, not on your ratings.** I use it to decide what
to re-derive in class, so a wall of 5s that isn't true only hurts you.

| # | Prerequisite skill | From | Confidence 1–5 |
|---|---|---|---|
| 1 | Complex exponentials, Euler's identity, phasors | ECE 333 L2 | |
| 2 | Signal energy vs. power; classifying signals | ECE 333 L3–L5 | |
| 3 | Convolution and impulse response of an LTI system | ECE 333 L8–L11 | |
| 4 | Orthogonal signal sets; signals as vectors | ECE 333 L15–L17 | |
| 5 | Exponential Fourier series and its coefficients | ECE 333 L20 | |
| 6 | Continuous-time Fourier transform and its properties | ECE 333 L22–L24 | |
| 7 | Ideal vs. practical filters; bandwidth | ECE 333 L25 | |
| 8 | Amplitude modulation (Project 2) | ECE 333 L26 | |
| 9 | Sampling, reconstruction, aliasing | ECE 333 L29–L31 | |
| 10 | Random variables, PDFs, conditional probability | ECE 346 / Math 356 | |
| 11 | Decibels, dBm, SNR in dB | **New in ECE 447** | |
| 12 | MATLAB: plotting, vectors, scripts | ECE 333 projects | |
| 13 | Simulink: opening and running a model | **New for many** | |

Then answer, in a sentence or two each:

- Which **one** topic above would help you most if I spent 15 minutes re-deriving it in class?
- Which topic did you most recently use, and in what course?

---

## Why these problems: the ECE 333 → ECE 447 bridge

| Problem | Where you learned it | Where you need it in ECE 447 |
|---|---|---|
| 1 — Complex exponentials, two-sided spectra | ECE 333 L2, L20 | L5–L6 signal space; every spectrum in the course |
| 2 — dB, dBm, SNR **[NEW]** | *not covered* | Labs 1–8; L36–L37 system performance |
| 3 — Frequency shifting | ECE 333 L24, Project 2 | L8–L9 amplitude modulation |
| 4 — Fourier series of a pulse | ECE 333 L18–L21 | L24 pulse shaping and ISI |
| 5 — Ideal filtering, bandwidth | ECE 333 L8–L11, L25 | L6 transmission of signals; L24 ISI |
| 6 — Sampling and aliasing | ECE 333 L29–L31 | L18–L20 sampling and PCM |
| D — MATLAB / RTL-SDR toolchain | ECE 333 projects | Lab 1 (Lesson 3) onward |

## Grading

| Part | Weight |
|---|---|
| A — Signals, spectra, power (Problems 1–2) | 20% |
| B — Fourier analysis (Problems 3–4) | 40% |
| C — Filtering and sampling (Problems 5–6) | 25% |
| D — MATLAB / RTL-SDR readiness | 10% |
| E — Self-assessment (completion) | 5% |

This assignment is worth one homework grade.
