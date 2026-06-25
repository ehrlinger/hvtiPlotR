# venn-plot.R
# Venn diagram for 2-3 sets. The small-set-count sibling of hv_upset(): reads
# the same logical / 0-1 set-membership columns and renders overlapping circles
# via ggvenn. Use hv_upset() when there are more than three sets.
#
# `region` and `n` are columns of the region-count table; suppress R CMD check
# notes about undefined globals.
utils::globalVariables(c("region", "n"))

# ---------------------------------------------------------------------------
# Internal: enumerate the 2^k - 1 non-empty Venn regions and count the rows
# matching each exact in/out membership pattern. NA membership counts as
# absent (FALSE), matching hv_upset().
.venn_regions <- function(data, sets) {
  ind <- as.matrix(data[sets])
  mode(ind) <- "logical"
  ind[is.na(ind)] <- FALSE

  k        <- length(sets)
  patterns <- expand.grid(rep(list(c(FALSE, TRUE)), k))
  names(patterns) <- sets
  patterns <- patterns[rowSums(patterns) > 0, , drop = FALSE]  # drop all-absent

  key_pat <- apply(patterns, 1L, function(r) paste(as.integer(r), collapse = ""))
  key_row <- apply(ind,      1L, function(r) paste(as.integer(r), collapse = ""))
  counts  <- as.integer(table(factor(key_row, levels = key_pat)))

  region <- vapply(seq_len(nrow(patterns)), function(i) {
    inset <- sets[unlist(patterns[i, ], use.names = FALSE)]
    if (length(inset) == 1L) paste0(inset, " only")
    else paste(inset, collapse = " & ")
  }, character(1L))

  out <- data.frame(patterns, region = region, n = counts,
                    stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

#' Prepare a Venn diagram for plotting
#'
#' Validates a wide set-membership data frame and returns an \code{hv_venn}
#' object carrying a region-count table. Call \code{\link{plot.hv_venn}} on the
#' result for a bare \pkg{ggplot2} Venn diagram. \code{hv_venn()} is the
#' small-set-count companion to \code{\link{hv_upset}}, reading the same input;
#' for more than three sets use \code{\link{hv_upset}}.
#'
#' @param data A data frame; one row per patient. Each set column must be
#'   logical or 0/1 numeric.
#' @param sets Character vector of \strong{2 to 3} column names to draw as sets.
#'
#' @return An object of class \code{c("hv_venn", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{The input data frame.}
#'   \item{\code{$meta}}{Named list: \code{sets}, \code{n_patients},
#'     \code{n_sets}.}
#'   \item{\code{$tables$regions}}{A data frame with one logical column per set
#'     (the in/out membership pattern), a \code{region} label, and \code{n}
#'     (patients in that exact region).}
#' }
#'
#' @seealso Worked recipe with rendered output:
#'   \url{https://ehrlinger.github.io/hvti_graphics/upset.html}.
#' @seealso \code{\link{plot.hv_venn}}, \code{\link{hv_upset}},
#'   \code{\link{sample_upset_data}}
#'
#' @examples
#' dta <- sample_upset_data(n = 300, seed = 42)
#' v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
#' v$tables$regions
#'
#' @export
hv_venn <- function(data, sets) {
  .check_df(data)
  if (!(is.character(sets) && length(sets) >= 2L))
    stop("`sets` must be a character vector of at least 2 column names.",
         call. = FALSE)
  if (length(sets) > 3L)
    stop("`hv_venn()` supports at most 3 sets; use `hv_upset()` for more.",
         call. = FALSE)
  .check_cols(data, sets)
  non_binary <- sets[!vapply(data[sets], function(x)
    is.logical(x) || (is.numeric(x) && all(x %in% c(0, 1, NA))),
    logical(1))]
  if (length(non_binary) > 0L)
    stop("hv_venn requires binary (0/1 or logical) columns. ",
         "Non-binary column(s): ", paste(non_binary, collapse = ", "), ".",
         call. = FALSE)

  data <- as.data.frame(data)
  new_hv_data(
    data = data,
    meta = list(
      sets       = sets,
      n_patients = nrow(data),
      n_sets     = length(sets)
    ),
    tables   = list(regions = .venn_regions(data, sets)),
    subclass = "hv_venn"
  )
}

#' Plot an hv_venn object
#'
#' Draws a 2-3 set Venn diagram using \code{ggvenn::ggvenn()} and returns a
#' bare \pkg{ggplot2} object you can finish with \code{+}.
#'
#' @param x An \code{hv_venn} object.
#' @param show_percentage Logical; show each region's percentage. Default
#'   \code{TRUE}.
#' @param show_counts Logical; show each region's count. Default \code{TRUE}.
#' @param fill Optional vector of fill colours, one per set. \code{NULL}
#'   (default) uses \pkg{ggvenn}'s palette.
#' @param text_size Region label text size. Default \code{4}.
#' @param set_name_size Set name text size. Default \code{6}.
#' @param ... Forwarded to \code{ggvenn::ggvenn()} for finer styling (unlike
#'   most \code{plot.hv_*} methods, which ignore \code{...}; \pkg{ggvenn} bakes
#'   labels into its geoms, so forwarding is the only way to reach them).
#'
#' @return A \code{\link[ggplot2]{ggplot}} object, already styled by
#'   \pkg{ggvenn} and \strong{coordinate-free} (no axes). Tune it through this
#'   method's arguments (\code{fill}, \code{text_size}, \code{set_name_size},
#'   \code{...}). Do \emph{not} add an axis-bearing house theme such as
#'   \code{theme_hv_manuscript()}: a Venn has no meaningful x/y, and the theme
#'   would paste spurious axes onto it.
#'
#' @seealso \code{\link{hv_venn}}
#'
#' @examples
#' dta <- sample_upset_data(n = 300, seed = 42)
#' v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
#' plot(v)
#'
#' @export
plot.hv_venn <- function(x, show_percentage = TRUE, show_counts = TRUE,
                         fill = NULL, text_size = 4, set_name_size = 6, ...) {
  dots     <- list(...)
  reserved <- intersect(names(dots), c("data", "columns"))
  if (length(reserved) > 0L)
    stop("Cannot pass ", paste(sprintf("`%s`", reserved), collapse = ", "),
         " via `...`; ", if (length(reserved) > 1L) "they are" else "it is",
         " supplied from the hv_venn object.", call. = FALSE)
  if (!is.null(fill)) {
    if ("fill_color" %in% names(dots))
      stop("Pass fill colours via `fill`, not `fill_color`.", call. = FALSE)
    if (length(fill) != length(x$meta$sets))
      stop("`fill` must give one colour per set (", length(x$meta$sets),
           ").", call. = FALSE)
  }
  args <- c(
    list(
      data            = x$data,
      columns         = x$meta$sets,
      show_percentage = show_percentage,
      show_counts     = show_counts,
      text_size       = text_size,
      set_name_size   = set_name_size
    ),
    dots
  )
  if (!is.null(fill)) args$fill_color <- fill
  do.call(ggvenn::ggvenn, args)
}

#' Print an hv_venn object
#'
#' @param x An \code{hv_venn} object from \code{\link{hv_venn}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_venn <- function(x, ...) {
  m <- x$meta
  cat("<hv_venn>\n")
  cat(sprintf("  N patients  : %d  (%d sets)\n", m$n_patients, m$n_sets))
  cat(sprintf("  Sets        : %s\n", paste(m$sets, collapse = ", ")))
  cat(sprintf("  Regions     : %d\n", nrow(x$tables$regions)))
  invisible(x)
}
