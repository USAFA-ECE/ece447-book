# tools

Instructor-side helpers. Nothing here is part of the student bundle, and nothing
here is built into the book — `_toc.yml` only covers `book/`.

## `usrp_transmit.m` — run a Lab 6/7/8 transmitter on the USRP

Only the instructor transmits in Labs 6, 7 and 8; students receive. The transmit
models live with the desktopSDR support files under `digital/usrp_tx/`, not in this
repo. They work, but several saved settings make them fail in ways that read as broken
hardware, so this wrapper corrects them at run time and leaves the `.slx` files
alone — which also keeps them from being re-saved out of R2021a.

### If you have never run this before, read this bit

You need **two MATLAB sessions**: one transmits, one receives. MATLAB is single
threaded, so the transmit call blocks. Both radios live on the same machine happily.

In the transmit session:

```matlab
addpath('C:\path\to\ece447-book\tools')
usrp_transmit('lab6a1', 0)       % DRY RUN: prints what it would do, never transmits
usrp_transmit('lab6a1', 900)     % for real, 15 minutes
```

**`secs = 0` is a dry run.** It configures everything and reports it without touching
the radio. Use it to check a setup before class, and to get the numbers you have to
announce.

Every call prints an `ANNOUNCE TO THE CLASS` block before going on air. Read it out —
it carries the transmit frequency, and for Lab 8 the image checksum that the students
are asked to compare against. It also reminds you to tell them to set `Tuner Gain (dB)`
to about 40 and to enter their Lab 2 ppm figure, which are the two things that most
often make a student's receiver look broken.

### What to type, per lab

| lab | command | notes |
|---|---|---|
| Lab 6 Activity 1 | `usrp_transmit('lab6a1', 900)` | |
| Lab 6 Activity 2 | `usrp_transmit('lab6a2', 900)` | students also set `Additional Freq Offset (Hz)` to 700 |
| Lab 6 Activity 3 | — | runs from a recording; no transmission needed |
| Lab 7 | `usrp_transmit('lab7', 1800, [], [], 'Go Falcons!')` | 5th argument is the message, max 50 chars |
| Lab 8 | `usrp_transmit('lab8', 1800, [], [], 'image3.mat')` | 5th argument picks the image |

The empty `[]`s are gain and frequency, left at their defaults (50 dB, whatever the
model ships with, which is 433.5 MHz on all five). To move frequency — say the band is
busy — pass it as the 4th argument: `usrp_transmit('lab7', 1800, 50, 915e6, 'Hi')`.

For Lab 7 the generator appends a space and a three-digit frame counter to your
message, so the class sees `Go Falcons! 001` … `Go Falcons! 100` repeating. Tell them
so: consecutive counters are how a student confirms frames are arriving in order.

For Lab 8, **run it for at least ten minutes.** One image is 100 frames at about half
a second each, so a complete pass takes ~50 s, and a student who starts late sees a
part-white image until the next pass fills it in.

### What it corrects at run time

**Transmit gain.** The models ship at 10 dB. USRP gain counts *upward* (B200 range
0–89.75), the opposite of the PLUTO these were converted from, so 10 dB is nearly
silent — measured undetectable at 6 ft, while ~50 dB works and 70 dB saturates the
receiver. The wrapper defaults to 50.

The gain constant is **named differently between models**: `Transmitter Gain (dB)` in
the Lab 6 models but `Transmit Power (dB)` in the Lab 7 and 8 ones. An earlier version
of this wrapper matched on the name and so silently left Labs 7 and 8 transmitting at
10 dB, i.e. not at all. It now finds the constant by following the wire into the
radio's gain port. (The `Gain` on the SDRu block's own dialog — 25 in the Lab 7/8
models — is ignored, because `gainSource` is `Input port`.)

**Source frame size — Activity 1 only.** That model's Bernoulli generator ships at
`SamplesPerFrame = 2` against `SampleTime = 1/100e3`, a 20 µs frame, forcing 50,000
Simulink steps per second to deliver 4 samples each. That starves the radio: 529 UHD
underruns and 2.6× slower than real time. Raising the frame to 2000 — same data rate
— gave 14 underruns and 4 dB more signal at the receiver.

**The other models must not get this treatment.** Their sources run 50× slower
(`SampleTime = 1/2e3`), so the shipped 2-bit frame is already only 1000 steps/s and is
fine. Forcing 2000 there would make a *one second* frame feeding a Tx Prep stage that
already buffers 2.7 s — a good way to stop a receiver's timing and carrier loops ever
settling. Labs 7 and 8 have no Bernoulli source at all.

So the wrapper only touches the frame when a model's measured step rate exceeds its
threshold, and then scales to a 20 ms frame rather than a fixed count. Measured
behaviour:

| model | source rate | action |
|---|---:|---|
| `raised_cosine` (Act 1) | 50,000 steps/s | frame 2 → 2000 |
| `coarse_synch` (Act 2) | 1,000 steps/s | left alone |
| `carrier_timing` (Act 3) | 1,000 steps/s | left alone |
| `ascii_message`, `image_transfer` | no Bernoulli source | left alone |

The wrapper also forces Accelerator mode; Normal mode cannot keep up.

**Modulation, Lab 7.** That transmit model has a Manual Switch choosing a QPSK or a
DQPSK modulator, and the student receiver has a matching switch. They must agree or
the text decodes as garbage. Both ship on QPSK and the wrapper forces the transmit
side there, so a stray click can't leave the class unable to decode. (Measured: on a
Manual Switch, `sw = '1'` passes input 1, and input 1 is QPSK on both sides.) Lab 8 is
DQPSK end to end with no switch on either side, which is why its captures are named
`dqpsk_image*.mat`.

**I/Q mirror, Labs 7 and 8.** See the section below — this is the one that matters.

### Verified status

Measured 2026-10-21, B200 → RTL-SDR at 6 ft, MATLAB R2023b.

| | status |
|---|---|
| Lab 6 Activity 1 | **works live.** Signal 28.8 dB over the noise floor. |
| Lab 6 Activity 2 | **works live**, at *receive* tuner gain 40 and injected offset 700. At the shipped gain of 10 the estimator reports 0 Hz. |
| Lab 6 Activity 3 | **runs from a recording.** Live acquisition resolved four clusters on only 6 of 16 validated runs; the recording locks every time. No transmission needed. |
| Lab 7 | **runs from a recording.** The live link does not decode — see below. On `qpsk_ascii_msg.mat` the receiver decodes 460 frames cleanly. |
| Lab 8 | **runs from a recording.** Same reason. On `dqpsk_image1.mat` it reconstructed the image and published it to the base workspace. |

> Receiver gain is a separate trap. If a student leaves the receiving dongle at the
> models' default `Tuner Gain (dB)` — 10 in most models, 20 in the Lab 8 one — the
> coarse frequency estimator locks onto the dongle's DC spike and reports 0 Hz however
> good the transmission is. The labs tell them to use about 40.

### Why Labs 7 and 8 run from recordings: the I/Q mirror

**Symptom.** Over the air, the Lab 7 receiver produces a textbook-perfect
constellation — `Rx Rotated` lock 0.984, EVM 6.4%, as good as the textbook's own
recording — and decodes *nothing*. The frame strobe never fires once in 44,000
symbols. Nothing on screen suggests a fault. This is the most misleading failure in
the whole lab sequence, so it is worth knowing about even if you never fix it.

**Cause.** Our transmitted QPSK is conjugated (I and Q swapped) relative to what the
textbook's receive models expect. Framing works by correlating against a known 39-bit
preamble and firing a strobe when the correlation reaches `preamble_len - 6` = 33.
Conjugating a Gray-coded QPSK stream inverts one bit of every pair, and the correlator
sums two matched filters over the even and odd bit streams, so one inverted stream
turns +39 into roughly half of it. The constellation is untouched, because a mirrored
QPSK constellation still shows four clean clusters.

Measured, using the receive model itself as the oracle:

| source | peak correlation | frame strobes | decodes |
|---|---:|---:|---|
| textbook `qpsk_ascii_msg.mat`, as recorded | **39** | 284 | yes |
| the same recording, conjugated | 17 | 0 | no |
| our live capture, as received | 13 | 0 | no |
| our live capture, conjugated | **39** | 131 | framing restored |

**It is not the radios.** A complex tone transmitted at +20019.5 Hz came back at
+20852 Hz — the 832 Hz being the dongle's ~2 ppm error. The hardware chain preserves
handedness, so the conjugation is in the models, most likely from converting them off
the PLUTO blocks they shipped on.

**What the wrapper does about it.** For the Lab 7 and 8 models it inserts a conjugate
on the baseband symbol path, at the transmit filter's input, so that student receivers
would need no changes. Turn it off or on explicitly with the 7th argument:

```matlab
usrp_transmit('lab7', 600, 50, [], 'Hi', [], 'off')   % as the model ships
usrp_transmit('lab7', 600, 50, [], 'Hi', [], 'on')    % force the fix
```

The Lab 6 models deliberately **don't** get it: nothing in that lab can see a mirror,
since a mirrored constellation still shows four clusters and a mirrored spectrum still
has the right bandwidth. The one visible trace is that Lab 6 Activity 2's coarse
estimate comes back with the opposite sign to the induced peak's position.

**This fix has not yet been confirmed on air.** The lab text therefore runs Labs 7 and
8 from the recordings, which are proven. If you want to confirm it, the honest test is:
transmit with `'on'`, capture to a `.mat`, then run the receiver on that file offline
and check whether it decodes *without* conjugating. Two cautions, both of which cost
me hours:

- **Don't test it by checking which side of DC the signal lands on.** The QPSK signal
  sits on the carrier, so mirroring it about the carrier leaves it exactly where it
  was. That test looks decisive and proves nothing. Only an *offset* tone reveals the
  chain's handedness; only the correlation, or the decode itself, reveals the mapping.
- **Don't trust a single live capture.** Acquisition is marginal here as in Lab 6
  Activity 3, so a capture that happens not to lock gives the same middling
  correlation either way and reads as a null result. Check that `Rx Rotated` lock
  exceeds 0.9 before believing anything, and prefer capturing once to a file and
  re-running offline, which is deterministic.

To capture to a file the models can read (format per `import_rtlsdr_data.m`): save a
variable `rtlsdr_data`, a `timeseries` whose `.data` is `[nFrames × frameSize]` and
whose `TimeInfo.Increment` is `frameSize/fs`.

### Traps that will bite you

**Two MATLAB sessions.** MATLAB is single threaded, so a blocking transmit loop
cannot also run a receiver. Transmit from one session, receive from another. Both
radios share one machine fine.

**The radio serial is baked into the models.** On a different USRP, open the SDRu
Transmitter block and set Platform and serial to match, or `findsdru` reports
"No devices found".

**UHD intermittently reports "No devices found"** for a radio that is plainly
attached — usually the first access after plug-in, while the B200 loads its FPGA
image, but it has happened mid-session too. It clears by itself, and the wrapper
retries automatically. Don't start debugging configuration in front of a class.

**`matlab -batch` segfaults on exit** after any session that opened the USRP (access
violation in `mnFullExitFcn`, exit code 5). It happens strictly after all work and
output, is harmless, and doesn't occur interactively. Check for the `[tx] done:` line
to confirm the transmission itself completed — a healthy run reports about 1.02×
real time.

**Block names in these models carry leading spaces and embedded newlines** —
`' ASCII Transfer Binary Source'`, `"RTL-SDR\nReceiver"`. An exact-name lookup
(`find_system(...,'Name','RTL-SDR Receiver')`) silently returns nothing, which is how
a script can report that it tuned a receiver while leaving it on the shipped 602 MHz.
Match on the whitespace-collapsed, trimmed name.

**All five receive models ship tuned to 602 MHz**, as do the textbook's original PLUTO
transmit models and the pre-conversion `.slx.r2021a` backups. The 433.5 MHz in the
current USRP transmit models came from our conversion. Note that 602–608 MHz is UHF
TV channel 36, so which frequency is appropriate is a spectrum-authorization question,
not a technical one.

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
