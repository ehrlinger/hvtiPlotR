# upset-plot.R
#
# UpSet plot wrapper for procedure / set co-occurrence analysis.
# Ports the pattern from tp.complexUpset.R (template graph library) to
# hvtiPlotR, replacing hard-coded colours with scale_ composition and
# explicit theme calls with hvtiPlotR themes.
#
# Key differences from raw ComplexUpset::upset():
#  - encode_sets = FALSE by default so annotate() can reference set names
#  - set_sizes position exposed as a parameter
#  - No hard-coded fill colours; examples demonstrate scale_fill_manual()
#  - Theme applied via `&` operator (patchwork) in examples
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
#' @seealso [hvti_upset()]
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
#' \code{hvti_upset} object.  Call \code{\link{plot.hvti_upset}} on the result
#' to obtain the \pkg{ComplexUpset} UpSet diagram.  Apply a theme to all
#' panels with \code{&}:
#' \preformatted{plot(up) & hvti_theme("manuscript")}
#'
#' @param data      A data frame. Each set-membership column must be logical
#'   or integer (0/1).
#' @param intersect Character vector of column names to treat as sets.
#'   Must contain at least two names that exist in \code{data}.
#'
#' @return An object of class \code{c("hvti_upset", "hvti_data")}:
#' \describe{
#'   \item{\code{$data}}{The validated input data frame.}
#'   \item{\code{$meta}}{Named list: \code{intersect}, \code{n_patients},
#'     \code{n_sets}.}
#'   \item{\code{$tables}}{List with one element: \code{set_counts} — a
#'     named integer vector of per-set patient counts.}
#' }
#'
#' @seealso \code{\link{plot.hvti_upset}}, \code{\link{sample_upset_data}}
#'
#' @examples
#' sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
#'           "TV_Repair", "Aorta", "CABG")
#' dta <- sample_upset_data(n = 300, seed = 42)
#' up  <- hvti_upset(dta, intersect = sets)
#' up   # prints set counts
#'
#' \dontrun{
#' plot(up) & hvti_theme("manuscript")
#' }
#'
#' @importFrom rlang .data
#' @export
hvti_upset <- function(data, intersect) {
  .check_df(data)
  if (!(is.character(intersect) && length(intersect) >= 2L))
    stop("`intersect` must be a character vector of at least 2 column names.",
         call. = FALSE)
  .check_cols(data, intersect)
  non_binary <- intersect[!vapply(data[intersect], function(x)
    is.logical(x) || (is.numeric(x) && all(x %in% c(0, 1, NA))),
    logical(1))]
  if (length(non_binary) > 0L)
    stop("ComplexUpset requires binary (0/1 or logical) columns. ",
         "Non-binary column(s): ", paste(non_binary, collapse = ", "), ".",
         call. = FALSE)

  set_counts <- colSums(data[intersect], na.rm = TRUE)

  new_hvti_data(
    data = as.data.frame(data),
    meta = list(
      intersect  = intersect,
      n_patients = nrow(data),
      n_sets     = length(intersect)
    ),
    tables   = list(set_counts = set_counts),
    subclass = "hvti_upset"
  )
}


#' Print an hvti_upset object
#'
#' @param x   An \code{hvti_upset} object from \code{\link{hvti_upset}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hvti_upset <- function(x, ...) {
  m  <- x$meta
  sc <- x$tables$set_counts
  cat("<hvti_upset>\n")
  cat(sprintf("  N patients  : %d  (%d sets)\n", m$n_patients, m$n_sets))
  cat("  Set counts  :\n")
  for (s in names(sc)) {
    cat(sprintf("    %-20s %d\n", s, sc[[s]]))
  }
  invisible(x)
}


#' Plot an hvti_upset object
#'
#' Draws an UpSet plot using \code{\link[ComplexUpset]{upset}}.
#' Apply a theme to \strong{all panels} with \code{&}:
#' \preformatted{plot(up) & hvti_theme("manuscript")}
#' Apply scales or annotations to the intersection panel via
#' \code{base_annotations}.
#'
#' @param x                   An \code{hvti_upset} object.
#' @param min_size             Minimum intersection size to display.
#'   Default \code{1}.
#' @param width_ratio          Fraction of horizontal space given to the
#'   set-size bar. Default \code{0.3}.
#' @param encode_sets          Logical; when \code{FALSE} (default) set names
#'   are used verbatim, required for \code{\link[ggplot2]{annotate}} to
#'   reference a specific set by name.
#' @param sort_sets            Sort order for set-size bar:
#'   \code{"descending"}, \code{"ascending"}, or \code{FALSE}.
#'   Default \code{"descending"}.
#' @param sort_intersections   Sort order for intersection size bars.
#'   Default \code{"descending"}.
#' @param set_size_position    Position of the set-size bar: \code{"right"}
#'   (default) or \code{"left"}.
#' @param ...                  Additional arguments forwarded to
#'   \code{\link[ComplexUpset]{upset}}, e.g. \code{base_annotations},
#'   \code{annotations}, \code{set_sizes}.
#'
#' @return A patchwork / ggplot composite. Use \code{&} to apply a theme to
#'   all panels.
#'
#' @seealso \code{\link{hvti_upset}}, \code{\link{hvti_theme}}
#'
#' @examples
#' sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
#'           "TV_Repair", "Aorta", "CABG")
#' dta <- sample_upset_data(n = 300, seed = 42)
#' up  <- hvti_upset(dta, intersect = sets)
#'
#' # Build the plot object (render interactively with print(p))
#' p <- plot(up)
#'
#' \dontrun{
#' # Manuscript theme applied to all panels via &
#' plot(up) & hvti_theme("manuscript")
#'
#' # Custom intersection bar colour
#' plot(up,
#'   base_annotations = list(
#'     "Intersection size" = ComplexUpset::intersection_size(
#'       mapping = ggplot2::aes(fill = "n")
#'     ) +
#'       ggplot2::scale_fill_manual(
#'         values = c("n" = "steelblue"),
#'         guide  = "none"
#'       ) +
#'       ggplot2::labs(y = "Patients (n)")
#'   )
#' ) &
#'   hvti_theme("manuscript")
#' }
#'
#' @importFrom ComplexUpset upset upset_set_size intersection_size
#' @importFrom ggplot2 aes
#' @export
plot.hvti_upset <- function(x,
                             min_size           = 1,
                             width_ratio        = 0.3,
                             encode_sets        = FALSE,
                             sort_sets          = "descending",
                             sort_intersections = "descending",
                             set_size_position  = "right",
                             ...) {
  ComplexUpset::upset(
    data               = x$data,
    intersect          = x$meta$intersect,
    min_size           = min_size,
    width_ratio        = width_ratio,
    encode_sets        = encode_sets,
    sort_sets          = sort_sets,
    sort_intersections = sort_intersections,
    set_sizes          = ComplexUpset::upset_set_size(
      position = set_size_position
    ),
    ...
  )
}
