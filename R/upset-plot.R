# upset-plot.R
#
# UpSet plot wrapper for procedure / set co-occurrence analysis. Backed by
# `ggupset::scale_x_upset()` (since v2.2.0; previously ComplexUpset).
#
# Why ggupset:
#  - Returns a single ggplot — themes apply via `+` like every other hvtiPlotR
#    plot, no more patchwork `&` workaround.
#  - `ggplot_build()` works, so test_example_plot_data.R can inspect rendered
#    layers like every other plot family.
#  - Light dep footprint (gtable, grid, tibble, rlang, scales).
#  - Actively maintained against current ggplot2; no theme-API drift warnings.
# ---------------------------------------------------------------------------

#' Sample Procedure Co-occurrence Data
#'
#' Generates a realistic cardiac-surgery procedure data set where each row is
#' a patient and each column is a logical indicator of a specific procedure.
#' Co-occurrence rates are modelled from a latent primary-procedure type so
#' that the UpSet plot shows meaningful overlap patterns (e.g. aortic valve
#' patients frequently have concomitant aorta work; mitral valve patients
#' frequently have concomitant TV repair).
#'
#' @param n    Number of patients. Default `500`.
#' @param seed Random seed for reproducibility. Default `42`.
#'
#' @return A data frame with `n` rows and the following logical columns:
#'   `AV_Replacement`, `AV_Repair`, `MV_Replacement`, `MV_Repair`,
#'   `TV_Repair`, `Aorta`, `CABG`.
#'
#' @seealso [hv_upset()]
#' @examples
#' dta <- sample_upset_data(n = 300, seed = 42)
#' head(dta)
#' colSums(dta)
#' @export
sample_upset_data <- function(n = 500, seed = 42L) {
  set.seed(seed)

  # Latent primary procedure drives realistic co-occurrence
  primary <- sample(
    c("av_replacement", "av_repair", "mv_replacement", "mv_repair", "cabg"),
    size    = n,
    replace = TRUE,
    prob    = c(0.30, 0.15, 0.15, 0.10, 0.30)
  )

  av_rep  <- primary == "av_replacement"
  av_rep2 <- primary == "av_repair"
  mv_rep  <- primary == "mv_replacement"
  mv_rep2 <- primary == "mv_repair"
  cabg    <- primary == "cabg"
  av_any  <- av_rep | av_rep2
  mv_any  <- mv_rep | mv_rep2

  data.frame(
    AV_Replacement = av_rep,
    AV_Repair      = av_rep2,
    MV_Replacement = mv_rep,
    MV_Repair      = mv_rep2,
    # TV repair is concomitant with MV procedures (~30%) or rare otherwise (5%)
    TV_Repair      = stats::rbinom(n, 1, ifelse(mv_any, 0.30, 0.05)) == 1L,
    # Aorta work accompanies AV procedures (~30%)
    Aorta          = av_any & stats::rbinom(n, 1, 0.30) == 1L,
    # CABG is primary or concomitant (12%) with any valve procedure
    CABG           = cabg | stats::rbinom(n, 1, 0.12) == 1L
  )
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare UpSet co-occurrence data for plotting
#'
#' Validates a set-membership data frame, checks all intersect columns are
#' binary (logical or 0/1 integer), computes per-set counts, and returns an
#' \code{hv_upset} object. Call \code{\link{plot.hv_upset}} on the result to
#' obtain a ggplot2 UpSet diagram (backed by
#' \code{\link[ggupset]{scale_x_upset}}).
#'
#' @param data      A data frame. Each set-membership column must be logical
#'   or integer (0/1).
#' @param intersect Character vector of column names to treat as sets. Must
#'   contain at least two names that exist in \code{data}.
#'
#' @return An object of class \code{c("hv_upset", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{The validated input data frame, plus a `.Procedures`
#'     list-column derived from the indicator matrix (consumed by
#'     `scale_x_upset()`).}
#'   \item{\code{$meta}}{Named list: \code{intersect}, \code{n_patients},
#'     \code{n_sets}.}
#'   \item{\code{$tables}}{List with one element: \code{set_counts} -- a
#'     named integer vector of per-set patient counts.}
#' }
#'
#' @seealso Worked recipe with rendered output:
#'   \url{https://ehrlinger.github.io/hvti_graphics/upset.html}.
#' @seealso \code{\link{plot.hv_upset}}, \code{\link{sample_upset_data}}
#'
#' @examples
#' sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
#'           "TV_Repair", "Aorta", "CABG")
#' dta <- sample_upset_data(n = 300, seed = 42)
#'
#' # 1. Build data object
#' up <- hv_upset(dta, intersect = sets)
#' up  # prints set counts
#'
#' # 2. Plot. The default (set_size = TRUE) returns a patchwork composite,
#' # so apply themes with `&` to theme every sub-panel. Use `+` for
#' # set_size = FALSE (a plain ggplot).
#' plot(up) & theme_hv_poster()
#' plot(up, set_size = FALSE) + theme_hv_poster()
#'
#' @importFrom rlang .data
#' @export
hv_upset <- function(data, intersect) {
  .check_df(data)
  if (!(is.character(intersect) && length(intersect) >= 2L))
    stop("`intersect` must be a character vector of at least 2 column names.",
         call. = FALSE)
  .check_cols(data, intersect)
  non_binary <- intersect[!vapply(data[intersect], function(x)
    is.logical(x) || (is.numeric(x) && all(x %in% c(0, 1, NA))),
    logical(1))]
  if (length(non_binary) > 0L)
    stop("hv_upset requires binary (0/1 or logical) columns. ",
         "Non-binary column(s): ", paste(non_binary, collapse = ", "), ".",
         call. = FALSE)

  data <- as.data.frame(data)

  if (".Procedures" %in% names(data))
    stop("`data` already has a column named `.Procedures`. hv_upset() ",
         "stores its list-column under that name internally. Rename or ",
         "drop the existing column before calling hv_upset().",
         call. = FALSE)

  # Pre-compute the list-column scale_x_upset() consumes. Stored on $data so
  # the constructor owns the data shape; plot.hv_upset() doesn't recompute.
  # NA indicators are treated as FALSE (set not present) so the list-column
  # entries are always plain character vectors of set names.
  ind <- as.matrix(data[intersect])
  mode(ind) <- "logical"
  ind[is.na(ind)] <- FALSE
  data$.Procedures <- lapply(seq_len(nrow(ind)),
                             function(i) intersect[ind[i, ]])

  set_counts <- colSums(ind, na.rm = TRUE)

  new_hv_data(
    data = data,
    meta = list(
      intersect  = intersect,
      n_patients = nrow(data),
      n_sets     = length(intersect)
    ),
    tables   = list(set_counts = set_counts),
    subclass = "hv_upset"
  )
}


#' Print an hv_upset object
#'
#' @param x   An \code{hv_upset} object from \code{\link{hv_upset}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_upset <- function(x, ...) {
  m  <- x$meta
  sc <- x$tables$set_counts
  cat("<hv_upset>\n")
  cat(sprintf("  N patients  : %d  (%d sets)\n", m$n_patients, m$n_sets))
  cat("  Set counts  :\n")
  for (s in names(sc)) {
    cat(sprintf("    %-20s %d\n", s, sc[[s]]))
  }
  invisible(x)
}


#' Plot an hv_upset object
#'
#' Draws an UpSet plot using \code{\link[ggupset]{scale_x_upset}}.
#'
#' When \code{set_size = TRUE} (the default) the function composes a
#' patchwork of two plots: a horizontal set-size sidebar and the intersection
#' bar chart. Apply themes to **all panels** with patchwork's \code{&}
#' operator:
#' \preformatted{plot(up) & theme_hv_poster()}
#'
#' Pass \code{set_size = FALSE} to get a single intersection-bar ggplot
#' for full customisation; themes then apply via \code{+}:
#' \preformatted{plot(up, set_size = FALSE) + theme_hv_poster()}
#'
#' @param x                   An \code{hv_upset} object.
#' @param n_intersections     Number of intersections to display, ordered by
#'   `sort_by`. Default `10`.
#' @param sort_by             How to order intersections: `"freq"` (default,
#'   by frequency) or `"degree"` (by number of sets in each combination).
#' @param fill_col            Optional column name in `x$data` to fill the
#'   intersection bars by (stacks bars by group). Default `NULL` (single
#'   colour, supplied via `bar_fill`).
#' @param bar_fill            Single fill colour for the intersection bars
#'   when `fill_col` is `NULL`. Default `"grey40"`.
#' @param set_size            Logical; if `TRUE` (default), compose a
#'   set-size sidebar as a patchwork. If `FALSE`, return only the
#'   intersection-bar ggplot.
#' @param set_size_position   `"right"` (default) or `"left"`.
#' @param set_size_sort       Sort order for the sidebar: `"descending"`
#'   (default), `"ascending"`, or `"none"` (preserve `intersect` order).
#' @param set_size_fill       Fill colour for the sidebar bars. Default
#'   `"steelblue"`.
#' @param width_ratio         Fraction of horizontal space given to the
#'   set-size sidebar (only used when `set_size = TRUE`). Default `0.3`.
#' @param ...                 Ignored; present for S3 consistency.
#'
#' @return A `ggplot` when `set_size = FALSE` (themes apply with `+`); a
#'   `patchwork` composite when `set_size = TRUE` (default; themes apply
#'   with `&` to cover all sub-panels).
#'
#' @seealso \code{\link{hv_upset}}, \code{\link{theme_hv_manuscript}}
#'
#' @examples
#' sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
#'           "TV_Repair", "Aorta", "CABG")
#' dta <- sample_upset_data(n = 300, seed = 42)
#' up  <- hv_upset(dta, intersect = sets)
#'
#' # Default: intersection bars + set-size sidebar (patchwork composite).
#' # Use `&` to theme every sub-panel.
#' plot(up) & theme_hv_poster()
#'
#' \dontrun{
#' # Intersection bars only — single ggplot, themes apply with `+`.
#' plot(up, set_size = FALSE) + theme_hv_poster()
#'
#' # Fill bars by an external grouping variable (e.g. era).
#' dta$era <- ifelse(seq_len(nrow(dta)) <= 150, "Early", "Recent")
#' up_era  <- hv_upset(dta, intersect = sets)
#' plot(up_era, fill_col = "era", set_size = FALSE) +
#'   ggplot2::scale_fill_manual(
#'     values = c(Early = "grey60", Recent = "steelblue"),
#'     name   = "Era"
#'   ) +
#'   theme_hv_poster()
#' }
#'
#' @importFrom ggupset scale_x_upset
#' @importFrom ggplot2 aes geom_bar geom_col ggplot labs scale_x_reverse element_blank theme
#' @export
plot.hv_upset <- function(x,
                          n_intersections   = 10L,
                          sort_by           = c("freq", "degree"),
                          fill_col          = NULL,
                          bar_fill          = "grey40",
                          set_size          = TRUE,
                          set_size_position = c("right", "left"),
                          set_size_sort     = c("descending", "ascending",
                                                "none"),
                          set_size_fill     = "steelblue",
                          width_ratio       = 0.3,
                          ...) {
  sort_by           <- match.arg(sort_by)
  set_size_position <- match.arg(set_size_position)
  set_size_sort     <- match.arg(set_size_sort)

  if (!is.null(fill_col)) .check_col(x$data, fill_col)

  # Intersection-size bar chart (single ggplot)
  bars <- if (is.null(fill_col)) {
    ggplot2::ggplot(x$data,
                    ggplot2::aes(x = .data$.Procedures)) +
      ggplot2::geom_bar(fill = bar_fill)
  } else {
    ggplot2::ggplot(x$data,
                    ggplot2::aes(x = .data$.Procedures,
                                 fill = .data[[fill_col]])) +
      ggplot2::geom_bar()
  }
  bars <- bars +
    ggupset::scale_x_upset(order_by = sort_by,
                           n_intersections = n_intersections) +
    ggplot2::labs(x = NULL, y = "Patients (n)")

  if (!isTRUE(set_size)) return(bars)

  # Set-size sidebar — manual composition since ggupset doesn't ship one.
  # NB the decreasing= inversion below is intentional: ggplot renders factor
  # levels bottom-to-top on a y-axis, so to display "descending" (largest at
  # top) we need to put the largest count at the LAST factor level, i.e. sort
  # values ascending (`decreasing = FALSE`).
  sc <- x$tables$set_counts
  set_order <- switch(set_size_sort,
                      descending = names(sort(sc, decreasing = FALSE)),
                      ascending  = names(sort(sc, decreasing = TRUE)),
                      none       = rev(x$meta$intersect))
  side_df <- data.frame(
    set = factor(names(sc), levels = set_order),
    n   = unname(as.integer(sc))
  )

  side <- ggplot2::ggplot(side_df,
                          ggplot2::aes(x = .data$n, y = .data$set)) +
    ggplot2::geom_col(fill = set_size_fill) +
    ggplot2::labs(x = "Set size", y = NULL)
  if (set_size_position == "right") {
    side <- side + ggplot2::scale_x_reverse()
    left <- bars
    right <- side
    widths <- c(1 - width_ratio, width_ratio)
  } else {
    left <- side
    right <- bars
    widths <- c(width_ratio, 1 - width_ratio)
  }

  patchwork::wrap_plots(left, right) +
    patchwork::plot_layout(widths = widths)
}
