# tools

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
