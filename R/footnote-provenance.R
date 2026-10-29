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
.FOOTNOTE_SEP <- " · "
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
#' The commit comes first and is cut to its first 7 characters, so the
#' shortest line that survives a crop still finds the render record, which
#' names the job. Only the R, hvtiPlotR and hvtiRtemplates versions are
#' printed; the full package list belongs in the render provenance.
#'
#' hvtiPlotR does not know about studies or git. It formats the parts it is
#' given; the commit and the job path come from the caller.
#'
#' @param commit The render commit ID, a single string. Only the first 7
#'   characters are printed.
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
#'   commit   = "3f9c2a1d8e4b",
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
      anyNA(versions) || !all(nzchar(names(versions))))
    stop("`versions` must be a named character vector.", call. = FALSE)
  if (!inherits(time, "POSIXct") || length(time) != 1L || is.na(time))
    stop("`time` must be a single POSIXct time.", call. = FALSE)
  c(substr(commit, 1L, 7L), job, paste(names(versions), versions),
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
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop(sprintf("`%s` must be a single non-empty string.", arg), call. = FALSE)
  invisible(x)
}

# A footnote given as one string is split into fields at the separator, so it
# can still wrap between them.
.footnote_fields <- function(footnote) {
  if (!is.character(footnote) || !length(footnote) || anyNA(footnote))
    stop("`footnote` must be a character vector of fields, or NULL.", call. = FALSE)
  if (length(footnote) == 1L) footnote <- strsplit(footnote, .FOOTNOTE_SEP, fixed = TRUE)[[1L]]
  footnote <- trimws(footnote)
  footnote <- footnote[nzchar(footnote)]
  if (!length(footnote))
    stop("`footnote` must not be empty.", call. = FALSE)
  footnote
}

# Fit the fields to `avail` inches on the current device: the largest size
# from the start size down to the floor that holds them on one line, else the
# floor, wrapped. Returns the font size and the lines.
.fit_footnote <- function(fields, avail) {
  one <- paste(fields, collapse = .FOOTNOTE_SEP)
  width_at <- function(s, fs) {
    grid::convertWidth(grid::grobWidth(grid::textGrob(s, gp = grid::gpar(fontsize = fs))),
                       "in", valueOnly = TRUE)
  }
  w <- width_at(one, .FOOTNOTE_START_PT)
  if (w <= avail) return(list(fontsize = .FOOTNOTE_START_PT, lines = one))
  # Width is near linear in size; step down in 0.1 pt from the estimate in
  # case the device's hinting is not.
  fs <- floor(10 * .FOOTNOTE_START_PT * avail / w) / 10
  while (fs >= .FOOTNOTE_FLOOR_PT) {
    if (width_at(one, fs) <= avail) return(list(fontsize = fs, lines = one))
    fs <- round(fs - 0.1, 1)
  }
  fs <- .FOOTNOTE_FLOOR_PT
  list(fontsize = fs,
       lines = .wrap_footnote(fields, avail, function(s) width_at(s, fs)))
}

# Greedy wrap. Each field is a piece, joined to the one before by the
# separator. A field other than the first that is too wide for a line alone is
# cut after each `/` and `.`; its pieces join with nothing, so the lines read
# back as the whole path. A piece with no such break that is still too wide is
# cut between characters as a last resort, so nothing is ever clipped.
.wrap_footnote <- function(fields, avail, width) {
  pieces <- list()
  for (i in seq_along(fields)) {
    f <- fields[[i]]
    parts <- if (i == 1L || width(f) <= avail) f else .split_field(f, avail, width)
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
  parts <- regmatches(f, gregexpr("[^/.]*[/.]|[^/.]+$", f))[[1L]]
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

# Unit conversion to inches, as ggsave() does it.
.to_inches <- function(x, units, dpi) {
  x / switch(units, `in` = 1, cm = 2.54, mm = 25.4, px = dpi)
}

# Save `plot` with the footnote in a strip below it. Two passes through
# ggsave(), so the measuring runs on the very device, dpi and arguments the
# file is written with: the first draws only a probe that fits the note and
# reports the lines it needs; the second writes the figure at its own height
# plus the strip. Returns the saved dimensions in the caller's units.
.save_with_footnote <- function(path, plot, fields, device, width, height, units, dpi, dots) {
  width_in  <- .to_inches(width, units, dpi)
  height_in <- .to_inches(height, units, dpi)
  avail <- width_in - 2 * .FOOTNOTE_MARGIN_IN
  # ggsave() takes the background from a ggplot but not from a grob, so pass
  # the plot's own, and the strip matches the figure.
  if (is.null(dots$bg)) {
    fill <- tryCatch(
      ggplot2::calc_element("plot.background", ggplot2::complete_theme(plot$theme))$fill,
      error = function(e) NULL
    )
    dots$bg <- if (is.null(fill)) "transparent" else fill
  }
  save <- function(filename, grob, h) {
    do.call(ggplot2::ggsave,
            c(list(filename = filename, plot = list(grob), device = device,
                   width = width_in, height = h, units = "in", dpi = dpi), dots))
  }

  # recordGrob() evaluates its expression in the list with grid's namespace
  # around it, so the fitting function travels in the list.
  fit <- new.env()
  fit_fn <- .fit_footnote
  probe <- grid::recordGrob(assign("value", fit_fn(fields, avail), envir = fit),
                            list(fit = fit, fit_fn = fit_fn, fields = fields, avail = avail))
  ext <- .file_ext(path)
  probe_file <- tempfile(fileext = if (nzchar(ext)) paste0(".", ext) else "")
  on.exit(unlink(probe_file), add = TRUE)
  save(probe_file, probe, height_in)
  note <- fit$value

  strip_in <- length(note$lines) * note$fontsize * .FOOTNOTE_LINEHEIGHT / 72 +
    2 * .FOOTNOTE_MARGIN_IN
  composite <- grid::gTree(children = grid::gList(
    grid::gTree(children = grid::gList(ggplot2::ggplotGrob(plot)),
                vp = grid::viewport(y = 1, height = grid::unit(1, "npc") - grid::unit(strip_in, "in"),
                                    just = "top")),
    grid::textGrob(paste(note$lines, collapse = "\n"),
                   x = grid::unit(.FOOTNOTE_MARGIN_IN, "in"),
                   y = grid::unit(strip_in - .FOOTNOTE_MARGIN_IN, "in"),
                   just = c("left", "top"),
                   gp = grid::gpar(fontsize = note$fontsize, lineheight = .FOOTNOTE_LINEHEIGHT,
                                   col = grDevices::gray(0.3)),
                   name = "hv_footnote")
  ))
  save(path, composite, height_in + strip_in)

  to_units <- function(x) x * switch(units, `in` = 1, cm = 2.54, mm = 25.4, px = dpi)
  list(width = width, height = to_units(height_in + strip_in), units = units)
}
