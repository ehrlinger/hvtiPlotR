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
#' @seealso [upset_plot()]
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

#' UpSet Plot for Set Co-occurrence Analysis
#'
#' Wraps [ComplexUpset::upset()] to produce a structured UpSet plot for
#' visualising overlapping set memberships — most commonly surgical procedure
#' co-occurrences. Returns a bare patchwork / ggplot object so callers can
#' compose colour scales and themes.
#'
#' Apply a theme to **all panels** with `&`:
#' ```r
#' upset_plot(dta, intersect = sets) & hvti_theme("manuscript")
#' ```
#' Apply scales or annotations to the intersection panel via `base_annotations`.
#'
#' @param data              A data frame. Each set-membership column must be
#'   logical or integer (0/1).
#' @param intersect         Character vector of column names to treat as sets.
#'   Must contain at least two names that exist in `data`.
#' @param min_size          Minimum intersection size to display. Default `1`.
#' @param width_ratio       Fraction of horizontal space given to the set-size
#'   bar. Default `0.3`.
#' @param encode_sets       Logical; when `FALSE` (default) set names are used
#'   verbatim, which is required for [ggplot2::annotate()] to reference a
#'   specific set by name.
#' @param sort_sets         Sort order for set-size bar: `"descending"`,
#'   `"ascending"`, or `FALSE`. Default `"descending"`.
#' @param sort_intersections Sort order for intersection size bars. Default
#'   `"descending"`.
#' @param set_size_position Position of the set-size bar: `"right"` (default)
#'   or `"left"`.
#' @param ...               Additional arguments forwarded to
#'   [ComplexUpset::upset()], e.g. `base_annotations`, `annotations`,
#'   `set_sizes`.
#'
#' @return A patchwork / ggplot composite. Use `&` to apply a theme to all
#'   panels; use `+` within `base_annotations` list entries for per-panel
#'   customisation.
#'
#' @seealso [ComplexUpset::upset()], [sample_upset_data()], [hvti_theme()]
#'
#' @examples
#' sets <- c("AV_Replacement", "AV_Repair", "MV_Replacement", "MV_Repair",
#'           "TV_Repair", "Aorta", "CABG")
#' dta <- sample_upset_data(n = 300, seed = 42)
#'
#' # --- Build the plot object (render interactively with print(p)) ----------
#' p <- upset_plot(dta, intersect = sets)
#'
#' \dontrun{
#' # --- Manuscript theme applied to all panels via & ------------------------
#' upset_plot(dta, intersect = sets) &
#'   hvti_theme("manuscript")
#'
#' # --- Custom intersection bar colour via scale_fill_manual ----------------
#' upset_plot(
#'   dta,
#'   intersect = sets,
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
#' # --- Colour bars by a stratum (e.g. era) ---------------------------------
#' \dontrun{
#' dta$era <- ifelse(seq_len(nrow(dta)) <= 150, "Early", "Recent")
#'
#' upset_plot(
#'   dta,
#'   intersect = sets,
#'   base_annotations = list(
#'     "Intersection size" = ComplexUpset::intersection_size(
#'       counts   = FALSE,
#'       mapping  = ggplot2::aes(fill = era)
#'     ) +
#'       ggplot2::scale_fill_manual(
#'         values = c("Early" = "grey60", "Recent" = "steelblue"),
#'         name   = "Era"
#'       ) +
#'       ggplot2::labs(y = "Patients (n)")
#'   )
#' ) &
#'   hvti_theme("manuscript")
#' }
#'
#' # --- Annotate a specific set bar and add count labels --------------------
#' \dontrun{
#' upset_plot(
#'   dta,
#'   intersect = sets,
#'   set_sizes = (
#'     ComplexUpset::upset_set_size(position = "right") +
#'       ggplot2::geom_text(
#'         ggplot2::aes(label = ggplot2::after_stat(count)),
#'         hjust  = 1.1,
#'         stat   = "count",
#'         colour = "white"
#'       ) +
#'       ggplot2::annotate(
#'         geom  = "text",
#'         label = "\u2713",
#'         x     = "CABG",
#'         y     = 175,
#'         size  = 3
#'       ) +
#'       ggplot2::expand_limits(y = 300)
#'   )
#' ) &
#'   hvti_theme("manuscript")
#' }
#'
#' # --- Save ----------------------------------------------------------------
#' \dontrun{
#' p <- upset_plot(dta, intersect = sets) & hvti_theme("manuscript")
#' ggplot2::ggsave("upset.pdf", p, width = 12, height = 8)
#' }
#'
#' @importFrom ComplexUpset upset upset_set_size intersection_size
#' @importFrom ggplot2 aes
#' @export
upset_plot <- function(data,
                       intersect,
                       min_size             = 1,
                       width_ratio          = 0.3,
                       encode_sets          = FALSE,
                       sort_sets            = "descending",
                       sort_intersections   = "descending",
                       set_size_position    = "right",
                       ...) {

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

  ComplexUpset::upset(
    data                 = data,
    intersect            = intersect,
    min_size             = min_size,
    width_ratio          = width_ratio,
    encode_sets          = encode_sets,
    sort_sets            = sort_sets,
    sort_intersections   = sort_intersections,
    set_sizes            = ComplexUpset::upset_set_size(
      position = set_size_position
    ),
    ...
  )
}
