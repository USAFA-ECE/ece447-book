# Homework 1

Chapter 3

## Due NLT Lesson 8, 2359 on Gradescope

## Directions: 
- Collaboration is authorized as noted in the syllabus Collaboration policy. 
- All homework must be complete, error-free, and _neatly organized_. **Points may be deducted for sloppy and illegible work.** 
- Answers should be clearly indicated by a box.
- Use engineering notation with proper units.
- Submit work to Gradescope with pages assigned to each problem. Scans/uploads must be legible and neat without excessive margins.

## Problems:
- 3.4-4 --> Signal transmission through an LTI system. Part(a): include both the magnitude and phase plots for each sketch. Part (b): just plot the magnitude and comment on the phase. Ensure plots are easily readable, with important values labeled
- 3.7-5 --> Energy spectral density and essential bandwidth
- Autocorrelation and spectral density --> Consider the signal $g(t)$ formed by two unit-height rectangular pulses, each of width $T$ - one centered at $t=0$ and the other centered at $t=2T$:

    $g(t)=\text{rect}\left(\frac{t}{T}\right)+\text{rect}\left(\frac{t-2T}{T}\right)$

    (a) Find and sketch the time autocorrelation function

    $\psi_g(\tau)=\int^{\infty}_{-\infty}g(t)g(t+\tau)dt$

    Label the values of $\psi_g(\tau)$ at $\tau=0,\pm T,\pm 2T,$ and $\pm 3T$. HINT: sketch $g(t)$ and a shifted copy $g(t+\tau)$ on the same axes and find the total overlap area as $\tau$ slides. Recall that the autocorrelation of a *single* rectangular pulse of width $T$ is a triangle of height $T$ and base $2T$.

    (b) Take the Fourier transform of $\psi_g(\tau)$ to find the spectral density of $g(t)$. Since $g(t)$ has finite energy, this is the *energy* spectral density $\Psi_g(f)$ - the power spectral density of Sec. 3.8 is the same idea applied to a power signal, using the time-averaged autocorrelation $R_g(\tau)$. Check your answer by confirming that $\Psi_g(f)=|G(f)|^2$.
