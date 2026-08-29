# Lab 1: SDR Setup and Spectrum Exploration with MATLAB

(Adapted from R. W. Stewart, K. W. Barlee, D. S. W. Atkinson, L. H. Crockett, & A. G. Broadhurst, [*Software Defined Radio using MATLAB & Simulink and the RTL-SDR*](https://www.desktopsdr.com/download-files), 2nd Ed., Strathclyde Academic Media, 2022, Ch. 2 and Ch. 3.)

## Overview

Your RTL-SDR dongle can digitize a roughly 2-3 MHz wide slice of RF spectrum anywhere from a few tens of MHz up to around 2 GHz - the exact limits depend on which tuner chip is inside your dongle, which you'll check during setup and which matters again in Activity 4. Today you'll get MATLAB talking to that dongle and use it as a real-time spectrum analyzer to go looking for actual signals in the air around Fairchild Hall - FM radio, aviation traffic, ISM-band devices, and more.

## Aims of the Lab

- Get MATLAB, the required toolboxes, and the RTL-SDR Hardware Support Package installed and verified.
- Run your first live RTL-SDR receiver model in Simulink.
- Understand why complex (I/Q) sampling gives you twice the usable bandwidth of real sampling at the same sample rate, and how the length of your spectrum snapshot sets its frequency resolution.
- Tune across several interesting parts of the spectrum, identify what you're looking at, and listen to it on your laptop's speakers.
- Sweep the full RTL-SDR range and produce a wideband spectrum plot.

> This lab runs across two class periods: **Day 1** covers software/driver setup through Activity 1 (First Contact) - expect this to use most of the period. **Day 2** covers Activities 2-4 (spectrum viewing, band exploration, and the full sweep) plus the write-up.

> IMPORTANT: We will be using MATLAB and/or Simulink (the block diagram version of MATLAB) in all the labs in this course this semester. If you feel you need more instruction on how to use MATLAB or Simulink, you should go to https://matlabacademy.mathworks.com/, log in, and take some self-paced, online courses. Both MATLAB and Simulink have five "Get Started with..." courses. Take as many as you like (they're free!), but the Onramp courses should be sufficient. 

## Some Math: Why Complex Sampling Doubles Your Bandwidth

You've probably seen the Nyquist criterion stated as $f_s > 2B$ for a real-valued signal of bandwidth $B$ - you need to sample at more than twice the highest frequency present, or higher frequencies alias down on top of your signal.

Your RTL-SDR doesn't hand MATLAB a real-valued signal, though - it hands you **complex** samples, $x[n] = I[n] + jQ[n]$, formed by quadrature-downconverting the RF around your tuned center frequency $f_c$. Because $I[n]$ and $Q[n]$ are two independent real streams sampled at $f_s$ each, the resulting complex signal has a spectrum that is *not* forced to be symmetric about 0 Hz (you'll see exactly why in Lab 2). That means the full range $-f_s/2$ to $+f_s/2$ is usable, alias-free bandwidth - a total of $f_s$, not $f_s/2$. This is the whole reason a 2.4 MHz RTL-SDR sample rate can capture a 2.4 MHz-wide slice of spectrum rather than only 1.2 MHz.

This also explains the frequency resolution you'll see on the spectrum analyzer. You've likely seen in signals and systems that a signal's duration and its frequency resolution trade off against each other - the longer you observe a signal, the more precisely you can pin down its frequency content:

$$\Delta f \approx \frac{1}{T}$$

where $T$ is how long, in seconds, your spectrum snapshot looks at the signal. Since $T = N/f_s$ for $N$ captured samples at rate $f_s$, that's equivalent to $\Delta f \approx f_s/N$: watching more samples (a longer snapshot) buys you finer frequency resolution, at the cost of needing more time per snapshot - a tradeoff you'll notice directly if you change the window length on the spectrum analyzer block in Activity 2. (The spectrum analyzer computes this using an algorithm called the FFT, which turns a block of time samples into a frequency-domain plot efficiently - you'll study how it works if you are in DSP or take a DSP course in grad school. For this lab, just treat it as the tool that draws the spectrum for you.)

## Software and Hardware Checklist

You'll need:

- MATLAB R2021a or later
- DSP System Toolbox, Communications Toolbox, and Signal Processing Toolbox
- Communications Toolbox Support Package for RTL-SDR Radio (install via **Home > Add-Ons > Get Hardware Support Packages**)
- Your RTL-SDR USB dongle and antenna

### Installing the Support Package and USB Driver

MATLAB's RTL-SDR support package installs its USB driver (WinUSB, in place of the default DVB-T driver) as part of its own guided installer:

- Remove any other nonessential USB devices from your computer first, so you don't accidentally overwrite the wrong device's driver.
- Plug in your RTL-SDR with the antenna attached. If Windows automatically installs a DVB-T driver for it, let that finish first.
- On the MATLAB **Home** tab, click **Add-Ons > Get Hardware Support Packages**, find "Communications Toolbox Support Package for RTL-SDR Radio," and click **Install**.
- During installation you'll be prompted to install the USB driver. The installer opens Zadig for you in a separate window - follow its on-screen directions (accept the admin/UAC prompt if asked).
- **Carefully** confirm the selected device before clicking **Reinstall Driver** - if the wrong device is selected, that device (e.g. your keyboard) can become unusable.
- If your RTL-SDR isn't recognized afterward, try a USB 2 port; some USB 3 ports don't work reliably with it.

### Verify the Hardware Support Package

In MATLAB, run:

```matlab
hwinfo = sdrinfo
```

If it returns a hardware information structure (radio name, tuner, address, etc.), you're set. If it returns an error or an empty result, revisit the driver install above.

## Course Support Files

Every lab this semester opens Simulink models and MATLAB scripts from a shared **course support files** folder - the example files that accompany the desktopSDR textbook. Set this up once, now, before Activity 1. Every file path a lab gives you (like `intro/rtlsdr_rx_startup_simulink.slx`) is relative to the root of this folder.

1. **Get the models and scripts** (small). Download [`support_files.zip`](support_files.zip) and unzip it somewhere convenient, e.g. `Documents\ece447_support`. The unzipped `support_files` folder is your **support files root**.
2. **Get the recorded signal files** (Labs 5-8 only, large). A few later activities load recorded RTL-SDR captures that are too big to ship in the download (100-240 MB each). Download the ones you need from the course **Teams** folder - [ECE447-Fall2026 > Class Materials > desktopSDR_supportFiles](https://usafa0.sharepoint.com/:f:/r/teams/ECE447-Fall2026/Class%20Materials/desktopSDR_supportFiles_v2_0__2021a?csf=1&web=1&e=qckp9s) - from its `digital/rtlsdr_rx/rec_data/` folder, and drop them into the matching `digital/rtlsdr_rx/rec_data/` folder inside your support files root. (A `RECORDINGS_ON_TEAMS.txt` there lists exactly which file each lab needs.)
3. **Point MATLAB at it.** Set your support files root as the **Current Folder**, then go to **Home > Set Path > Add with Subfolders**, choose that folder, and click **Save**. This lets MATLAB find every model and the `rtlsdr_book_library` blocks the models depend on.
4. **Newer MATLAB, first time only.** Open `rtlsdr_book_library/rtlsdr_book_library.slx` and re-save it, so the block library updates to your MATLAB version.

> If a model ever reports a missing file, download the complete package (every example, plus a PDF of the book) as a single zip from [desktopsdr.com](https://www.desktopsdr.com/download-files), or use the full copy in the Teams folder.

## Activity 1: First Contact

> Fairchild Hall blocks broadcast FM almost completely, so you won't find a real station from inside the classroom. For this activity your instructor is looping a **recorded FM broadcast** into the room from an ADALM-PLUTO (`fm/pluto_tx/pluto_fm_capture_replay.m`) and will announce the frequency. That's your known-good signal to tune to - no need to leave the room.

1. Open `intro/rtlsdr_rx_startup_simulink.slx` from the course support files. Before running it, double-click the RTL-SDR Receiver block and take a look at its parameters - note where the center frequency, sample rate, and gain are set. You'll be adjusting these directly in later activities.
2. Run the model. You should see IQ samples streaming into a scope with no errors - this is your smoke test that the whole chain (driver, HSP, hardware) is actually working before you build anything more complex.
3. Change the center frequency parameter to the frequency your instructor announced for the looped FM broadcast, and re-run. Confirm the plot visibly changes in response - a signal roughly 200 kHz wide should appear where there was only noise.
4. Once that runs cleanly, open `intro/rtlsdr_rx_startup_matlab.m` and step through it line by line. It does the same thing using a MATLAB `comm.SDRRTLReceiver` object instead of a Simulink block. You'll use both styles throughout the course - Simulink for quick visual exploration, MATLAB code when you want more control.

*For more detail on the receiver setup process, see Sec. 2.2 and 2.4 in SDR textbook.*

## Activity 2: Spectrum Viewing

> **Head for a window, or step outside.** Unlike Activity 1, this activity uses real off-air signals, and Fairchild Hall's structure blocks broadcast FM almost entirely - from inside you'll see noise and little else. The **southeast corner of Fairchild** is the best spot: from there you can usually pick up several strong signals at once, including transmitters on Cheyenne Mountain and traffic from the airfield.

1. **Set your antenna up before you go.** The whip that ships with your dongle is a **quarter-wave monopole** - it only works well when its length matches the band you're listening to, and when it has something to work against electrically. Get both right now, and you'll see how much they matter in the last step:
    - **Length.** A quarter wavelength in centimeters is roughly $7500/f$, with $f$ in MHz. For the FM broadcast band (~98 MHz) that's about **77 cm**; for the Air Band (~120 MHz), about **62 cm**. Extend the telescoping whip to match the band you're hunting - a whip left at some arbitrary length is the most common reason a signal looks far weaker than it should. (In practice you'd trim it a few percent shorter to allow for end effects, but this is close enough to work with.)
    - **Ground plane.** A monopole needs a counterpoise - effectively the other half of the antenna. If your base is magnetic, sticking it to a large metal surface does the job. We have had some metal plates cut for use in this class. If you use one from the shelves, please return it when finished for other cadets to use. Otherwise, you can clip **three or four radial wires**, each cut to that same quarter-wave length, around the base of the connector and spread them out evenly. Sloping those radials down about 45° rather than straight out also pulls the feedpoint impedance closer to the 50 Ω your dongle expects. We don't have these wires in the classroom - you will have to make this set up yourself - but this is the more portable option. Plus, you won't have to share a metal plate with anyone!
2. Open `spectrum/exploring_the_spectrum.slx`. This single model is all you need: an RTL-SDR Receiver feeding both a live **Spectrum Analyzer (FFT)** view and a scrolling **Waterfall** - think of it as a much more flexible version of a bench spectrum analyzer. It also **demodulates whatever you're tuned to and plays it through your speakers**, so you can hear the same signal you're looking at (you'll turn that on in step 6).
3. Find the tuning controls. They live in a separate **GUI control panel window**, not in the block diagram - it exposes **center frequency** and **RF gain** for live tuning while the model runs (the same parameters you set by hand in Activity 1). Sample rate is *not* on the control panel: to change it, double-click the **RTL-SDR Receiver** block in the Simulink model and edit its sample-rate parameter there.
4. **Get oriented on the display.** On the spectrum view, the horizontal axis is **frequency** (a window about as wide as your sample rate, ≈2.8 MHz, centered on the frequency you tuned to) and the vertical axis is **power**, in dB. On the waterfall, the horizontal axis is that same frequency axis, the vertical axis is **time** (scrolling), and brightness/color is power.
    - Once the model starts running, each scope maximizes its plot to fill the window and **hides the axis labels and values**. To read them, click the **Maximize Axes** button - the box-with-an-arrow icon at the top-right of the scope's toolbar - to toggle the labeled axes back into view. You may need to click it again after each run.
5. In the control panel, set the center frequency to your local commercial FM band (about 88-108 MHz), and confirm the sample rate is 2.8 MHz. Tune around and find a strong local FM station. Note how wide the signal looks on the display (it should be roughly 200 kHz). 
6. **Now listen to it.** Turn your laptop volume up. The audio chain runs along the bottom of the block diagram, under the yellow *LISTEN TO THE SIGNAL* banner: it demodulates the same signal the two displays are showing and sends it to your speakers. The **Select FM or AM** switch picks the demodulator - it starts on **FM** (the upper path), which is what you want for broadcast radio. With a strong station tuned in you should hear it clearly. Then confirm that what you hear matches what you see: tune slowly off the station and the audio should fall away to hiss at the same moment the 200 kHz-wide bump slides off the display.
    - If the audio is too loud, too quiet, or distorted, double-click the **Volume** block and change its gain (it starts at 0.5); you can do this while the model is running.
    - If you get no sound at all, check that Windows is using the speakers you expect as the **default** playback device - the model plays to whatever that is.
7. Adjust the RF gain on the control panel up and down while watching the noise floor. Too little gain and weak signals disappear into the noise; too much and strong signals distort ("saturate") the display. Find a gain setting that gives you a clean, undistorted view of your FM station - and note that you can *hear* this too: an over-driven signal sounds harsh and distorted well before the display makes it obvious.
8. Reposition or reorient your antenna while watching the display, and note how much signal strength changes with antenna placement alone - this will matter for the weaker Air Band reception you'll do in Lab 3.

*For more detail on tuner controls and antenna/gain technique, see Sec. 3.3 and 3.6-3.7 in SDR textbook.*

## Activity 3: Go Looking for Signals

Using the same tunable spectrum model, explore a few of these bands (pick at least three). For each one, set the center frequency and span, note whether you see activity, and record whether it looks narrowband (a single sharp peak) or wideband (a broad block of energy). Listen as well as look - double-click the **Select FM or AM** switch to match the modulation noted below (**AM** for the Air Band, **FM** for the amateur bands), and let your ears help you decide what you've found:

- **Aviation / Air Band** (108-137 MHz, AM) - you should be able to see USAFA airfield tower and approach traffic here; keep this frequency noted, you'll use it again in Lab 3.
- **Amateur radio** (144-148 MHz, 420-450 MHz)
- **ISM / key fobs and sensors** (~433 MHz) - try triggering a car key fob, garage remote, wireless doorbell, or some other cheap wireless device (obviously not all these are readily available at USAFA - maybe your sponsor's house!) near your antenna and watch for a brief burst to appear on the waterfall.
- **Public safety / trunked radio** (450-470 MHz) - you'll likely see digital-looking (noisy, non-audio) signals here rather than clear voice; compare how their shape on the display differs from the analog FM/AM signals you've already seen.

> Note: no RTL-SDR tuner reaches down to the standard AM broadcast band (530-1700 kHz) - the lab dongles' E4000 bottoms out around 53 MHz - so AM broadcast is **out of range** here. We'll come back to AM using the Air Band instead in Lab 3.

*For more detail on what you'll find at each frequency, see Sec. 3.1-3.2 and 3.8-3.11 in SDR textbook.*

## Activity 4: Sweeping the Full Range

> **Your tuner sets the limits.** The `sdrinfo` output from setup lists your dongle's tuner chip, and the two common ones behave differently. The lab dongles use the **E4000**, which bottoms out near **53 MHz** and has a PLL gap from **1100-1250 MHz** where it cannot lock at all. An **R820T/R820T2** instead tunes continuously from about 25 MHz. The sweep script handles this for you: leave `tuner_name = 'auto'` and it detects your tuner via `sdrinfo`, restricts the sweep to that tuner's usable bands, and never retunes into the gap.

1. Open `spectrum/sweep/rtlsdr_rx_specsweep.m` and look at the parameter block near the top. Set `location` to something that identifies where you're sweeping from, and set `start_freq` / `stop_freq` to the window you want - the defaults (80 MHz to 1.75 GHz) are a good starting point. Whatever you request is clipped automatically to your tuner's usable bands.
2. Run the script. It retunes the dongle across the range and stitches the results into a single wideband plot; this takes a minute or two, and you'll see it build up band by band. On an E4000 you'll get a **blank gap between 1100 and 1250 MHz** - that's the tuner's dead zone, not a bug and not a quiet stretch of spectrum.
3. Once it finishes, zoom in on a couple of the bands you found in Activity 3 and confirm they show up in the same place on the wideband plot.
4. Label at least two features on the plot (e.g. "FM broadcast band," "cell/LTE band") and save it - you'll need this for the write-up. If your plot has a tuner gap, label that too.

If you want to see the E4000's full reach, raise `stop_freq` to 2.2 GHz - it tunes higher than an R820T does.

We are not covering multi-dongle setups (Sec. 3.12 in the SDR textbook) in this lab; one RTL-SDR is all you need.

*For more detail on spectrum sweeping, see Sec. 3.13 in SDR textbook.*

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

1. Your full-range sweep plot from Activity 4, with at least 2 features labeled (e.g., "FM broadcast band", "cell/LTE band").
2. The spectrum display tuned to one interesting narrowband signal you found in Activity 3 (not the FM broadcast band), with a 2-3 sentence description of what you believe it is and why.
3. Your documentation statement.

**Note**: GenAI Level 3 encompasses Level 2 which permits AI as a consultation tool for idea generation, i.e., you can use AI to help you identify what you are seeing in your plots.
