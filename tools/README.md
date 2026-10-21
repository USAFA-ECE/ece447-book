# tools

Instructor-side helpers. Nothing here is part of the student bundle, and nothing
here is built into the book — `_toc.yml` only covers `book/`.

## `usrp_transmit.m` — run a Lab 6/7/8 transmitter on the USRP

Only the instructor transmits in Labs 6, 7 and 8; students receive. The transmit
models live with the desktopSDR support files under `digital/usrp_tx/`, not in this
repo. They work, but two saved settings make them fail in ways that read as broken
hardware, so this wrapper corrects both at run time and leaves the `.slx` files
alone.

```matlab
addpath('tools')
usrp_transmit('lab6a1')          % Activity 1, 120 s, gain 50
usrp_transmit('lab6a2', 600)     % Activity 2 for ten minutes
usrp_transmit('lab7')            % Lab 7 ASCII message
```

**Transmit gain.** The models ship at 10 dB. USRP gain counts *upward* (B200 range
0–89.75), the opposite of the PLUTO these were converted from, so 10 dB is nearly
silent — measured undetectable at 6 ft, while ~50 dB works and 70 dB saturates the
receiver. The wrapper defaults to 50.

**Source frame size.** The Bernoulli generator ships at `SamplesPerFrame = 2`
against `SampleTime = 1/100e3`, a 20 µs frame, forcing 50,000 Simulink steps per
second to deliver 4 samples each. That starves the radio: 529 UHD underruns and
2.6× slower than real time. Raising the frame to 2000 — same data rate — gave 14
underruns and 4 dB more signal at the receiver.

The wrapper also forces Accelerator mode; Normal mode cannot keep up.

**Two MATLAB sessions.** MATLAB is single threaded, so a blocking transmit loop
cannot also run a receiver. Transmit from one session, receive from another. Both
radios share one machine fine.

**The radio serial is baked into the models.** On a different USRP, open the SDRu
Transmitter block and set Platform and serial to match.

Verified 2026-10-21, B200 to RTL-SDR at 6 ft, MATLAB R2023b: all three Lab 6
activities behave as the lab describes. Lab 7 and Lab 8 take the same treatment but
were not tested on hardware.

> Receiver gain is a separate trap. If a student leaves the receiving dongle at the
> models' default `Tuner Gain (dB)` of 10, the coarse frequency estimator locks onto
> the dongle's DC spike and reports 0 Hz however good the transmission is. Lab 6
> tells them to use about 40.

## `build_slides.ps1` — rebuild the lesson slide PDFs

The lesson slides are authored in LaTeX/beamer in the Overleaf project
**ECE447-faculty (Fall NN)**. That source is *not* in this repo — only the exported
PDFs in `book/_static/` are. This script rebuilds them locally so editing a deck
doesn't mean exporting 25 PDFs by hand from Overleaf.

### One-time setup

Install MiKTeX (installs per-user, no admin needed):

```powershell
winget install --id MiKTeX.MiKTeX -e
initexmf --set-config-value "[MPM]AutoInstall=1"
```

`AutoInstall=1` lets it fetch missing LaTeX packages mid-build instead of failing.
The first build pulls a fair number of packages and is slower than later ones.

> If `pdflatex` isn't found afterwards, that's expected in an already-open terminal —
> PATH changes only reach newly launched processes. The script falls back to MiKTeX's
> default per-user install path, so it works either way.

### Rebuilding

1. In Overleaf: **Menu → Download → Source (.zip)**
2. Extract it (e.g. to `Documents\ece447-slides-src`)
3. Run:

```powershell
.\tools\build_slides.ps1 -ProjectDir C:\Users\<you>\Documents\ece447-slides-src
```

PDFs land in `book/_static/` as `ECE447_Lesson<N>.pdf`. Build a subset with
`-Lessons 24,25`.

### What it does for you

- Discovers lesson numbers from `Lesson_Slides/Lsn*_Slides.tex`, so a new deck needs
  no edit here.
- Runs two `pdflatex` passes per deck — beamer needs the second for correct frame
  counts in the footer.
- **Refuses to overwrite** a published deck with one under 60% of its page count, and
  warns if a semester date reappears. Both guards exist because of real failures (see
  below).

### Two gotchas worth knowing

**Lesson 39 is skipped on purpose.** It's the only deck authored in PowerPoint rather
than beamer. Its `Lsn39` LaTeX source is a 2-frame schedule/admin placeholder, so
building it would replace the real 22-page OFDM/MIMO/CDMA deck with a stub. It carries
no semester date, so it never needs rebuilding. To edit it, edit the PowerPoint and
export over `book/_static/ECE447_Lesson39.pdf`.

**The decks are semester-agnostic by design.** `ECE447_Slides_Fa25.tex` has
`\def\thisterm{}` and `\date{}`, and titles are `\title[\thiscourse]` rather than
`\title[\thiscourse (\thisterm)]`. That keeps the term off the title slide and out of
every slide footer, so decks carry over between semesters without a rebuild. Don't
reintroduce `\thisterm` into `\title[...]` or `\date{}`.

### Slide numbering

Slide file names use the *original* lesson numbering, which no longer matches the
schedule everywhere (e.g. schedule Lesson 5 links to `ECE447_Lesson4.pdf`). The table
in `book/downloads.md` is aligned by topic and is the source of truth for which deck
goes with which lesson.
