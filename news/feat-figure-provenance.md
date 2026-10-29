* `save_manuscript()` gains `footnote`, which prints a figure's provenance in a
  strip reserved below the plot, in `file` and `draft_file` alike, PDF, PNG and
  TIFF. The plot keeps its `width` x `height`; the file is taller by the strip,
  and the saved dimensions come back in the `"dims"` attribute of the returned
  path (`"draft_dims"` for the draft). The note is measured with each output
  device's own metrics, set at 8 pt and shrunk to fit one line down to a 6 pt
  floor; past the floor it wraps, between fields first and then inside the job
  path at `/` and `.`, never inside the commit ID, and is never clipped.
  `footnote = NULL`, the default, writes exactly what it wrote before
  (hvtiR figure-provenance design, section 3 and R4).
* New `provenance_footnote()` builds the note's fields from the parts it is
  given, the render commit first:
  `<commit 7> · <job path> · R x.y.z · hvtiPlotR a.b.c · hvtiRtemplates d.e.f · YYYY-MM-DD HH:MM`.
  hvtiPlotR knows nothing of git or studies and takes no new dependency.
* `make_footnote()` no longer says to omit provenance from publication
  figures: a saved figure, publication included, takes it from
  `save_manuscript(footnote =)`.
