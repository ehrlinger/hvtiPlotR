# footnote-provenance.R
#
# The provenance note save_manuscript() prints below a figure, and the fitting
# that keeps it whole. The note identifies the version of the job that drew the
# figure: the render commit first, so even the shortest surviving line finds the
# render record, then the job path, the R, hvtiPlotR and hvtiRtemplates
# versions and the time. hvtiPlotR only formats strings it is given; the study's
# git lives in hvtiRutilities and the call in hvtiRtemplates.
#
# Design: hvtiR dev/specs/2026-10-29-figure-provenance-design.md, section 3 and
# resolution R4 ("measure, shrink to a floor, then wrap; never clip").

# Spaced middle dot between fields.
.FOOTNOTE_SEP <- " \u00b7 "
.FOOTNOTE_START_PT <- 8
.FOOTNOTE_FLOOR_PT <- 6
.FOOTNOTE_LINEHEIGHT <- 1.2
.FOOTNOTE_MARGIN_IN <- 2 / 25.4

#' Build the provenance footnote for a saved figure
#'
#' Formats the fields [save_manuscript()] prints below a figure to identify
#' the version of the job that drew it: the commit, the job path, the R,
#' hvtiPlotR and hvtiRtemplates versions and the time, which
#' [save_manuscript()] joins with a middle dot.
#'
#' The commit comes first, so the shortest line that survives a crop still
#' finds the render record, which names the job. It is printed as given and
#' never shortened here: hvtiPlotR cannot know which abbreviation is unique in
#' the study's repository, so pass one that git verified, such as the output
#' of `git rev-parse --short`, or the full ID. A marker the caller uses when
#' no commit could be made, such as `"uncommitted"`, prints whole too.
#'
#' Only the R, hvtiPlotR and hvtiRtemplates versions are
#' printed; the full package list belongs in the render provenance.
#'
#' hvtiPlotR does not know about studies or git. It formats the parts it is
#' given; the commit and the job path come from the caller.
#'
#' @param commit The render commit ID, a single string printed as given: a
#'   unique abbreviation, the full ID, or a marker such as `"uncommitted"`.
#' @param job The job path, a single string, such as
#'   `"30_analyses/survival.qmd"`.
#' @param versions A named character vector of versions, printed as
#'   `"<name> <version>"` in the order given. The default is R, the installed
#'   hvtiPlotR and, when it is installed, hvtiRtemplates.
#' @param time The time of the render, a `POSIXct` printed as
#'   `"%Y-%m-%d %H:%M"`. Default `Sys.time()`.
#'
#' @return A character vector of fields: the commit, the job, one field per
#'   version and the time. Pass it to the `footnote` argument of
#'   [save_manuscript()], which joins and fits it.
#'
#' @seealso [save_manuscript()], which prints the note in a strip below the
#'   figure.
#'
#' @examples
#' provenance_footnote(
#'   commit   = "3f9c2a1",
#'   job      = "30_analyses/rfs.explain.long_term_survival.primary.qmd",
#'   versions = c(R = "4.5.1", hvtiPlotR = "2.8.19", hvtiRtemplates = "1.5.3"),
#'   time     = as.POSIXct("2026-10-29 14:40")
#' )
#' @export
provenance_footnote <- function(commit, job, versions = .default_versions(),
                                time = Sys.time()) {
  .check_single_string(commit, "commit")
  .check_single_string(job, "job")
  if (!is.character(versions) || is.null(names(versions)) ||
      anyNA(versions) || anyNA(names(versions)) ||
      !all(nzchar(names(versions))))
    stop("`versions` must be a named character vector.", call. = FALSE)
  if (!inherits(time, "POSIXct") || length(time) != 1L || is.na(time))
    stop("`time` must be a single POSIXct time.", call. = FALSE)
  c(commit, job, paste(names(versions), versions),
    format(time, "%Y-%m-%d %H:%M"))
}

# R, hvtiPlotR and, when it is installed, hvtiRtemplates.
.default_versions <- function() {
  v <- c(R = as.character(getRversion()),
         hvtiPlotR = as.character(utils::packageVersion("hvtiPlotR")))
  tmpl <- tryCatch(as.character(utils::packageVersion("hvtiRtemplates")),
                   error = function(e) NULL)
  if (!is.null(tmpl)) v <- c(v, hvtiRtemplates = tmpl)
  v
}

.check_single_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x)))
    stop(sprintf("`%s` must be a single non-empty string.", arg), call. = FALSE)
  invisible(x)
}

# A footnote given as one string is split into fields at the separator, so it
# can still wrap between them.
.footnote_fields <- function(footnote) {
  if (!is.character(footnote) || !length(footnote) || anyNA(footnote))
    stop("`footnote` must be a character vector of fields, or NULL.", call. = FALSE)
  # A line break of the caller's would draw a line the strip has no room for.
  if (any(grepl("[\r\n]", footnote)))
    stop("`footnote` must not contain line breaks; give the parts as fields.", call. = FALSE)
  if (length(footnote) == 1L) footnote <- strsplit(footnote, .FOOTNOTE_SEP, fixed = TRUE)[[1L]]
  footnote <- trimws(footnote)
  footnote <- footnote[nzchar(footnote)]
  if (!length(footnote))
    stop("`footnote` must not be empty.", call. = FALSE)
  footnote
}

# Fit the fields to `avail` inches on the current device: the largest size
# from the start size down to the floor that holds them on one line, else the
# floor, wrapped. `scaling` is ragg's: it enlarges what is drawn, so the sizes
# here are divided by it and the note stays 6 to 8 pt on the page. Returns the
# font size and the lines.
.fit_footnote <- function(fields, avail, scaling = 1) {
  start <- .FOOTNOTE_START_PT / scaling
  floor_pt <- .FOOTNOTE_FLOOR_PT / scaling
  one <- paste(fields, collapse = .FOOTNOTE_SEP)
  width_at <- function(s, fs) {
    grid::convertWidth(grid::grobWidth(grid::textGrob(s, gp = grid::gpar(fontsize = fs))),
                       "in", valueOnly = TRUE)
  }
  w <- width_at(one, start)
  if (w <= avail) return(list(fontsize = start, lines = one))
  # Width is near linear in size; step down in 0.1 pt from the estimate in
  # case the device's hinting is not.
  fs <- floor(10 * start * avail / w) / 10
  while (fs >= floor_pt) {
    if (width_at(one, fs) <= avail) return(list(fontsize = fs, lines = one))
    fs <- round(fs - 0.1, 1)
  }
  fs <- floor_pt
  list(fontsize = fs,
       lines = .wrap_footnote(fields, avail, function(s) width_at(s, fs)))
}

# Greedy wrap. Each field is a piece, joined to the one before by the
# separator, so a field that fits on a line is never broken; a full 40-character
# commit fits at the floor on a figure about 2 in wide or more. A field too wide for a line alone is
# cut after each `/`, `.` and space; its pieces join with nothing, so the lines
# read back as the whole path. A piece with no such break that is still too
# wide is cut between characters as a last resort, so nothing is ever clipped.
.wrap_footnote <- function(fields, avail, width) {
  pieces <- list()
  for (i in seq_along(fields)) {
    f <- fields[[i]]
    parts <- if (width(f) <= avail) f else .split_field(f, avail, width)
    for (j in seq_along(parts))
      pieces[[length(pieces) + 1L]] <- list(text = parts[[j]],
                                            sep = if (i > 1L && j == 1L) .FOOTNOTE_SEP else "")
  }
  lines <- character()
  cur <- ""
  for (p in pieces) {
    cand <- if (nzchar(cur)) paste0(cur, p$sep, p$text) else p$text
    if (!nzchar(cur) || width(cand) <= avail) {
      cur <- cand
    } else {
      lines <- c(lines, cur)
      cur <- p$text
    }
  }
  c(lines, cur)
}

.split_field <- function(f, avail, width) {
  parts <- regmatches(f, gregexpr("[^/. ]*[/. ]|[^/. ]+$", f))[[1L]]
  unlist(lapply(parts, function(p) {
    if (width(p) <= avail) return(p)
    chars <- strsplit(p, "")[[1L]]
    out <- character()
    cur <- ""
    for (ch in chars) {
      if (nzchar(cur) && width(paste0(cur, ch)) > avail) {
        out <- c(out, cur)
        cur <- ""
      }
      cur <- paste0(cur, ch)
    }
    c(out, cur)
  }), use.names = FALSE)
}

# The theme that sets a plot's background: a patchwork's plot_annotation(theme =)
# draws over its own.
.plot_theme <- function(plot) {
  annotation <- if (inherits(plot, "patchwork")) plot$patches$annotation$theme
  if (inherits(annotation, "theme")) ggplot2::theme() + plot$theme + annotation else plot$theme
}

# Unit conversion to inches, as ggsave() does it.
.to_inches <- function(x, units, dpi) {
  x / switch(units, `in` = 1, cm = 2.54, mm = 25.4, px = dpi)
}

# Formats a raster device writes. Its height is a whole number of pixels.
.RASTER_EXT <- c("png", "tif", "tiff", "jpg", "jpeg", "bmp")

# Save `plot` with the footnote in a strip below it. Two passes through
# ggsave(), so the measuring runs on the very device, dpi and arguments the
# file is written with: the first draws only a probe that fits the note and
# reports the lines it needs; the second writes the figure at its own height
# plus the strip. Returns the saved dimensions in the caller's units.
.save_with_footnote <- function(path, plot, fields, device, width, height, units, dpi, dots) {
  # ggsave() multiplies the size by `scale`. Apply it here instead, so the note
  # is fitted to, and the dims report, the size actually written.
  scale <- if (is.null(dots$scale)) 1 else dots$scale
  .check_scalar_positive(scale, "scale")
  dots$scale <- NULL
  ext <- .file_ext(path)
  # Devices round the page to whole units, and not all the same way: a raster
  # to pixels (on Linux 1277.9 px came out 1277, on macOS 1278), R's pdf() to
  # whole points, truncating. A function says nothing of what it writes, so the
  # file's extension decides for it. Ask for a whole number of units plus a
  # quarter, which any rounding takes to that whole number, so the reported
  # size is the size written.
  raster <- if (is.character(device)) device %in% .RASTER_EXT else ext %in% .RASTER_EXT
  per_in <- if (raster) dpi else 72
  page <- function(n) (n + 0.25) / per_in
  width_n   <- round(.to_inches(width, units, dpi) * scale * per_in)
  width_in  <- width_n / per_in
  height_in <- .to_inches(height, units, dpi) * scale
  # ragg's `scaling` makes a device inch that many inches on the page. The note
  # is measured and placed in device inches; the page is sized in real ones.
  scaling <- if (is.null(dots$scaling)) 1 else dots$scaling
  margin <- .FOOTNOTE_MARGIN_IN / scaling
  avail <- width_in / scaling - 2 * margin
  # ggsave() takes the background from a ggplot but not from a grob, so pass
  # the plot's own, and the strip matches the figure.
  if (is.null(dots$bg)) {
    fill <- tryCatch(
      ggplot2::calc_element("plot.background", ggplot2::complete_theme(.plot_theme(plot)))$fill,
      error = function(e) NULL
    )
    dots$bg <- if (is.null(fill)) "transparent" else fill
  }
  save <- function(filename, grob, h) {
    do.call(ggplot2::ggsave,
            c(list(filename = filename, plot = list(grob), device = device,
                   width = page(width_n), height = h, units = "in", dpi = dpi), dots))
  }

  # recordGrob() evaluates its expression in the list with grid's namespace
  # around it, so the functions it calls travel in the list.
  fit <- new.env()
  fit_fn <- .fit_footnote
  probe <- grid::recordGrob(assign("value", fit_fn(fields, avail, scaling), envir = fit),
                            list(fit = fit, fit_fn = fit_fn, fields = fields, avail = avail,
                                 scaling = scaling))
  probe_file <- tempfile(fileext = if (nzchar(ext)) paste0(".", ext) else "")
  on.exit(unlink(probe_file), add = TRUE)
  save(probe_file, probe, height_in)
  note <- fit$value

  strip_device <- length(note$lines) * note$fontsize * .FOOTNOTE_LINEHEIGHT / 72 + 2 * margin
  strip_in <- strip_device * scaling
  # The plot's gtable is built at draw time, on the output device: built here,
  # ggplot2 would lay it out on the caller's device, or open R's default one
  # and leave an Rplots.pdf behind. A patchwork needs patchworkGrob(), which
  # .hv_plot_gtable() picks.
  gtable_fn <- .hv_plot_gtable
  composite <- grid::gTree(children = grid::gList(
    grid::recordGrob(grid::grid.draw(gtable_fn(plot)),
                     list(gtable_fn = gtable_fn, plot = plot),
                     vp = grid::viewport(y = 1, height = grid::unit(1, "npc") - grid::unit(strip_device, "in"),
                                         just = "top")),
    grid::textGrob(paste(note$lines, collapse = "\n"),
                   x = grid::unit(margin, "in"),
                   y = grid::unit(strip_device - margin, "in"),
                   just = c("left", "top"),
                   gp = grid::gpar(fontsize = note$fontsize, lineheight = .FOOTNOTE_LINEHEIGHT,
                                   col = grDevices::gray(0.3)),
                   name = "hv_footnote")
  ))

  n <- ceiling((height_in + strip_in) * per_in)
  save(path, composite, page(n))
  total_in <- n / per_in

  to_units <- function(x) x * switch(units, `in` = 1, cm = 2.54, mm = 25.4, px = dpi)
  list(width = to_units(width_in), height = to_units(total_in), units = units)
}
