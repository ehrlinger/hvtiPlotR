###############################################################################
## consort-plot.R
##
## CONSORT patient-flow tracking and diagram for hvtiPlotR.
##
## Two S3 classes:
##   hv_consort_tracker  -- patient-level building object (built incrementally)
##   hv_consort          -- rendered grid diagram (from consort::consort_plot())
##
## Public API:
##   hv_consort_start()      -- initialise tracker
##   hv_consort_exclude()    -- add exclusion stage (pipe-friendly)
##   hv_consort_summary()    -- stage-level summary tibble
##   hv_consort_patients()   -- audit: patient IDs at a stage or by reason
##   hv_consort()            -- build diagram from tracker
##   plot.hv_consort()       -- render (grid.draw)
##   print.hv_consort()      -- one-screen summary
##   print.hv_consort_tracker() -- stage-by-stage summary
###############################################################################

# Suppress R CMD check note for bare symbol used in substitute() NSE call
# inside sample_consort_data().
utils::globalVariables("patient_id")

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Convert a label string to a safe snake_case column name.
# E.g. "Screened" -> "screened", "Eligible patients" -> "eligible_patients"
ct_snakify <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}

# Return the include (boolean) column name for the current (last) stage.
ct_current_include <- function(tracker) {
  n <- length(tracker$stages)
  tracker$stages[[n]]$include_col
}

# Validate that x is an hv_consort_tracker.
ct_validate_tracker <- function(x, arg = "tracker") {
  if (!inherits(x, "hv_consort_tracker"))
    stop(
      sprintf("`%s` must be an `hv_consort_tracker` object created by `hv_consort_start()`.", arg),
      call. = FALSE
    )
  invisible(x)
}

# ---------------------------------------------------------------------------
# hv_consort_tracker constructor
# ---------------------------------------------------------------------------

#' Initialise a CONSORT patient-flow tracker
#'
#' Creates an `hv_consort_tracker` object with one row per patient and a
#' boolean column indicating that every patient is in the initial (screened)
#' population.  Build the tracker incrementally with [hv_consort_exclude()],
#' then convert to a diagram with [hv_consort()].
#'
#' @param data       A data frame -- one row per patient.
#' @param patient_id <[`data-masking`][rlang::args_data_masking]> Unquoted
#'   name of the unique patient identifier column.
#' @param label      Character label for the initial population box.
#'   Default `"Screened"`.
#' @param pass_col   Column name for the initial boolean column.  Defaults to
#'   `ct_snakify(label)` (e.g. `"screened"` when `label = "Screened"`).
#'
#' @return An `hv_consort_tracker` object -- a list with:
#' \describe{
#'   \item{`$data`}{Patient-level data frame with boolean/character columns appended per stage.}
#'   \item{`$stages`}{Ordered list of stage descriptors (`label`, `include_col`, `excl_col`, `excl_label`).}
#'   \item{`$patient_id_col`}{Column name of the patient identifier.}
#' }
#'
#' @seealso [hv_consort_exclude()], [hv_consort()]
#'
#' @examples
#' cohort  <- data.frame(mrn = paste0("P", 1:100), age = sample(15:80, 100, TRUE))
#' tracker <- hv_consort_start(cohort, patient_id = mrn)
#' print(tracker)
#'
#' @export
hv_consort_start <- function(data, patient_id, label = "Screened",
                              pass_col = NULL) {
  .check_df(data)
  patient_id_col <- as.character(substitute(patient_id))
  .check_cols(data, patient_id_col)

  if (is.null(pass_col)) pass_col <- ct_snakify(label)
  if (!nzchar(pass_col))
    stop("`pass_col` / `label` produced an empty column name.", call. = FALSE)

  dat <- as.data.frame(data, stringsAsFactors = FALSE)
  dat[[pass_col]] <- TRUE

  structure(
    list(
      data           = dat,
      patient_id_col = patient_id_col,
      stages         = list(
        list(
          label       = label,
          include_col = pass_col,
          excl_col    = NULL,
          excl_label  = NULL
        )
      )
    ),
    class = "hv_consort_tracker"
  )
}


# ---------------------------------------------------------------------------
# Stage addition
# ---------------------------------------------------------------------------

#' Add an exclusion stage to a CONSORT tracker
#'
#' Evaluates formula-based exclusion rules against the currently-active patient
#' population and appends two new columns to the tracker's data frame:
#' a character column (`col`) recording the first-matching exclusion reason for
#' each patient, and a boolean column (`pass_col`) marking the survivors.
#' Patients already excluded by a prior stage are automatically gated out.
#'
#' @param tracker  An `hv_consort_tracker` from [hv_consort_start()].
#' @param label    Character label for the survivor box after this exclusion
#'   (e.g. `"Eligible"`, `"Analyzed"`).
#' @param col      Column name to store exclusion reasons (character).
#'   This column will contain a reason string for excluded patients and `NA`
#'   for survivors.  Required -- no default.
#' @param excl_label Character label for the side-box showing exclusion
#'   breakdown.  Default `"Excluded"`.
#' @param pass_col Column name for the survivor boolean column.  Defaults to
#'   `ct_snakify(label)` (e.g. `"eligible"` when `label = "Eligible"`).
#' @param ...  Two-sided formulas of the form
#'   `<condition> ~ "<reason string>"`.  Conditions are evaluated with data
#'   masking against the tracker's data frame.  The **first** matching formula
#'   assigns the reason; subsequent formulas are not evaluated for already-
#'   excluded patients.
#'
#' @return The updated `hv_consort_tracker` (invisibly -- pipe-safe).
#'
#' @seealso [hv_consort_start()], [hv_consort()]
#'
#' @examples
#' cohort <- data.frame(
#'   mrn  = paste0("P", 1:100),
#'   age  = sample(15:80, 100, TRUE),
#'   echo = sample(c(TRUE, FALSE), 100, TRUE, prob = c(0.9, 0.1))
#' )
#'
#' tracker <- hv_consort_start(cohort, patient_id = mrn) |>
#'   hv_consort_exclude(
#'     label    = "Eligible",
#'     col      = "excl_screen",
#'     age < 18 ~ "Age < 18"
#'   ) |>
#'   hv_consort_exclude(
#'     label  = "Analyzed",
#'     col    = "excl_eligible",
#'     !echo  ~ "Missing echocardiogram"
#'   )
#'
#' @importFrom rlang list2 f_lhs f_rhs eval_tidy as_data_mask
#' @export
hv_consort_exclude <- function(tracker, label, col, ...,
                                excl_label = "Excluded", pass_col = NULL) {
  ct_validate_tracker(tracker)

  if (missing(label) || !is.character(label) || length(label) != 1L || !nzchar(label))
    stop("`label` must be a non-empty character string.", call. = FALSE)
  if (missing(col) || !is.character(col) || length(col) != 1L || !nzchar(col))
    stop("`col` must be a non-empty character string naming the exclusion column.",
         call. = FALSE)
  if (col %in% names(tracker$data))
    stop(sprintf("Column '%s' already exists in tracker$data.", col), call. = FALSE)

  if (is.null(pass_col)) pass_col <- ct_snakify(label)
  if (!nzchar(pass_col))
    stop("`pass_col` / `label` produced an empty column name.", call. = FALSE)
  if (pass_col %in% names(tracker$data))
    stop(sprintf("Column '%s' already exists in tracker$data.", pass_col), call. = FALSE)

  formulas <- rlang::list2(...)
  if (length(formulas) == 0L)
    stop("Provide at least one formula `<condition> ~ \"<reason>\"`.", call. = FALSE)
  for (i in seq_along(formulas)) {
    if (!inherits(formulas[[i]], "formula") || !rlang::is_formula(formulas[[i]], lhs = TRUE))
      stop(sprintf("Argument %d is not a two-sided formula.", i), call. = FALSE)
    rhs <- rlang::f_rhs(formulas[[i]])
    if (!is.character(rhs) || length(rhs) != 1L)
      stop(sprintf("The right-hand side of formula %d must be a single reason string.", i),
           call. = FALSE)
  }

  dat          <- tracker$data
  prev_include <- ct_current_include(tracker)
  active       <- dat[[prev_include]]
  excl_reasons <- rep(NA_character_, nrow(dat))
  data_env     <- rlang::as_data_mask(dat)

  for (f in formulas) {
    condition <- rlang::eval_tidy(rlang::f_lhs(f), data = data_env)
    # Normalise to strict TRUE/FALSE: a patient with a missing value for the
    # exclusion criterion is treated as not matching the rule.
    condition <- !is.na(condition) & condition
    reason    <- rlang::f_rhs(f)
    to_excl   <- active & condition & is.na(excl_reasons)
    excl_reasons[to_excl] <- reason
  }

  dat[[col]]      <- excl_reasons
  dat[[pass_col]] <- active & is.na(excl_reasons)

  n                              <- length(tracker$stages)
  tracker$stages[[n]]$excl_col   <- col
  tracker$stages[[n]]$excl_label <- excl_label

  tracker$stages[[n + 1L]] <- list(
    label       = label,
    include_col = pass_col,
    excl_col    = NULL,
    excl_label  = NULL
  )

  tracker$data <- dat
  invisible(tracker)
}


#' Print an hv_consort_tracker object
#'
#' @param x   An `hv_consort_tracker` from [hv_consort_start()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.hv_consort_tracker <- function(x, ...) {
  cat("<hv_consort_tracker>\n")
  cat(sprintf("  Patients   : %d\n", nrow(x$data)))
  cat(sprintf("  ID column  : %s\n", x$patient_id_col))
  cat(sprintf("  Stages     : %d\n", length(x$stages)))
  for (s in x$stages) {
    n_in <- sum(x$data[[s$include_col]], na.rm = TRUE)
    cat(sprintf("    [%s] %s -- N = %d\n", s$include_col, s$label, n_in))
    if (!is.null(s$excl_col)) {
      n_excl <- sum(!is.na(x$data[[s$excl_col]]), na.rm = TRUE)
      cat(sprintf("      -> excl [%s]: %d\n", s$excl_col, n_excl))
    }
  }
  invisible(x)
}

# ---------------------------------------------------------------------------
# Audit helpers
# ---------------------------------------------------------------------------

#' Stage-level CONSORT summary table
#'
#' Returns a data frame with one row per stage showing patient counts
#' and the exclusion column name, suitable for a methods-section table.
#'
#' @param tracker An `hv_consort_tracker`.
#' @return A data frame with columns `label`, `include_col`, `n_included`,
#'   `excl_col`, `n_excluded`.  `n_excluded` and `excl_col` are `NA` for the
#'   final stage (no downstream exclusion defined yet).
#'
#' @seealso [hv_consort_patients()]
#' @export
hv_consort_summary <- function(tracker) {
  ct_validate_tracker(tracker)
  rows <- lapply(tracker$stages, function(s) {
    n_in   <- sum(tracker$data[[s$include_col]], na.rm = TRUE)
    n_excl <- if (!is.null(s$excl_col))
                sum(!is.na(tracker$data[[s$excl_col]]), na.rm = TRUE)
              else NA_integer_
    data.frame(
      label       = s$label,
      include_col = s$include_col,
      n_included  = n_in,
      excl_col    = if (!is.null(s$excl_col)) s$excl_col else NA_character_,
      n_excluded  = n_excl,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}


#' Retrieve patient IDs at a CONSORT stage
#'
#' Returns the IDs of patients who are active at a given stage (or who were
#' excluded for a specific reason at a given stage).
#'
#' @param tracker An `hv_consort_tracker`.
#' @param stage   Character -- either the `include_col` name (e.g. `"eligible"`)
#'   or the stage label (case-insensitive, e.g. `"Eligible"`).
#' @param reason  Optional character.  If supplied, returns patients excluded
#'   from *this* stage for the specified reason (the string must exactly match
#'   a value in the exclusion column).  The `stage` arg then refers to the
#'   stage *before* the exclusion (e.g. `"screened"` for `excl_screen`).
#'
#' @return A character vector of patient IDs (from the column named in
#'   `tracker$patient_id_col`).
#'
#' @examples
#' tracker <- hv_consort_start(data.frame(id = 1:10, age = c(rep(15,3), rep(30,7))),
#'                              patient_id = id) |>
#'   hv_consort_exclude(label = "Eligible", col = "excl_screen",
#'                       age < 18 ~ "Age < 18")
#' hv_consort_patients(tracker, "eligible")
#' hv_consort_patients(tracker, "screened", reason = "Age < 18")
#'
#' @export
hv_consort_patients <- function(tracker, stage, reason = NULL) {
  ct_validate_tracker(tracker)
  if (!is.character(stage) || length(stage) != 1L || !nzchar(stage))
    stop("`stage` must be a non-empty character string.", call. = FALSE)

  include_cols <- vapply(tracker$stages, `[[`, character(1L), "include_col")
  labels       <- vapply(tracker$stages, `[[`, character(1L), "label")

  idx <- which(include_cols == stage | tolower(labels) == tolower(stage))
  if (length(idx) == 0L)
    stop(
      sprintf("Stage '%s' not found. Available include_cols: %s; labels: %s",
              stage,
              paste(include_cols, collapse = ", "),
              paste(labels,       collapse = ", ")),
      call. = FALSE
    )
  idx <- idx[[1L]]
  s   <- tracker$stages[[idx]]
  dat <- tracker$data

  if (is.null(reason)) {
    as.character(dat[dat[[s$include_col]] == TRUE, tracker$patient_id_col])
  } else {
    if (is.null(s$excl_col))
      stop(
        sprintf("Stage '%s' has no downstream exclusion column.", stage),
        call. = FALSE
      )
    as.character(dat[!is.na(dat[[s$excl_col]]) & dat[[s$excl_col]] == reason,
                     tracker$patient_id_col])
  }
}

# ---------------------------------------------------------------------------
# Plot constructor
# ---------------------------------------------------------------------------

#' Build a CONSORT flow diagram from a tracker
#'
#' Reads the stage metadata stored in an `hv_consort_tracker`, auto-derives
#' the `orders` and `side_box` arguments for `consort::consort_plot()`, and
#' returns an `hv_consort` object wrapping the grid diagram.
#'
#' @param tracker  An `hv_consort_tracker` with at least two stages (call
#'   [hv_consort_exclude()] at least once after [hv_consort_start()]).
#' @param side_box Character vector of exclusion-reason column names to display
#'   as side boxes, or `"all"` (default) to include every exclusion column.
#' @param cex      Numeric; text size scaling passed to `consort::consort_plot()`.
#'   Default `0.9`.
#' @param width    Diagram width in inches.  Defaults to `7`.
#' @param height   Diagram height in inches.  Defaults to `2 + n_stages * 1.2`,
#'   where `n_stages` is the number of stages in the tracker.
#' @param ...      Additional arguments forwarded to `consort::consort_plot()`.
#'
#' @return An `hv_consort` object -- a list with:
#' \describe{
#'   \item{`$plot`}{The grid object returned by `consort::consort_plot()`.}
#'   \item{`$meta`}{Named list: `n_stages`, `width`, `height`, `orders`, `side_box`.}
#'   \item{`$tracker`}{The original `hv_consort_tracker`.}
#' }
#'
#' @seealso [hv_consort_start()], [hv_consort_exclude()], [plot.hv_consort()]
#'
#' @examples
#' cohort <- data.frame(
#'   mrn  = paste0("P", 1:100),
#'   age  = sample(15:80, 100, TRUE),
#'   echo = sample(c(TRUE, FALSE), 100, TRUE, prob = c(0.9, 0.1))
#' )
#' tracker <- hv_consort_start(cohort, patient_id = mrn) |>
#'   hv_consort_exclude(label = "Eligible", col = "excl_screen",
#'                       age < 18 ~ "Age < 18") |>
#'   hv_consort_exclude(label = "Analyzed", col = "excl_eligible",
#'                       !echo ~ "Missing echocardiogram")
#' fig <- hv_consort(tracker)
#' \dontrun{plot(fig)}
#'
#' @export
hv_consort <- function(tracker, side_box = "all", cex = 0.9,
                        width = NULL, height = NULL, ...) {
  ct_validate_tracker(tracker)

  stages   <- tracker$stages
  n_stages <- length(stages)
  if (n_stages < 2L)
    stop(
      "Tracker has only one stage. Call `hv_consort_exclude()` at least once before building the diagram.",
      call. = FALSE
    )

  # Build orders: interleave include_col and excl_col entries
  orders    <- character(0L)
  side_cols <- character(0L)

  for (s in stages) {
    orders[s$include_col] <- s$label
    if (!is.null(s$excl_col)) {
      excl_lbl              <- if (!is.null(s$excl_label)) s$excl_label else "Excluded"
      orders[s$excl_col]    <- excl_lbl
      side_cols             <- c(side_cols, s$excl_col)
    }
  }

  # Resolve side_box
  if (identical(side_box, "all")) {
    side_box <- side_cols
  } else {
    unknown <- setdiff(side_box, names(tracker$data))
    if (length(unknown))
      stop(sprintf("side_box column(s) not in tracker: %s",
                   paste(unknown, collapse = ", ")),
           call. = FALSE)
  }

  # Default dimensions
  if (is.null(width))  width  <- 7
  if (is.null(height)) height <- 2 + n_stages * 1.2

  # Render via consort package
  plot_obj <- consort::consort_plot(
    data     = tracker$data,
    orders   = orders,
    side_box = side_box,
    cex      = cex,
    ...
  )

  structure(
    list(
      plot    = plot_obj,
      meta    = list(
        n_stages = n_stages,
        width    = width,
        height   = height,
        orders   = orders,
        side_box = side_box
      ),
      tracker = tracker
    ),
    class = "hv_consort"
  )
}

# ---------------------------------------------------------------------------
# S3 methods for hv_consort
# ---------------------------------------------------------------------------

#' Print an hv_consort object
#'
#' @param x   An `hv_consort` from [hv_consort()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.hv_consort <- function(x, ...) {
  cat("<hv_consort>\n")
  cat(sprintf("  Stages     : %d\n", x$meta$n_stages))
  cat(sprintf("  Side boxes : %s\n",
              if (length(x$meta$side_box)) paste(x$meta$side_box, collapse = ", ")
              else "(none)"))
  cat(sprintf("  Dimensions : %.1f x %.1f in\n", x$meta$width, x$meta$height))
  invisible(x)
}


#' Render a CONSORT flow diagram
#'
#' Draws the grid-based diagram stored in an `hv_consort` object on a
#' new graphics page.
#'
#' @param x   An `hv_consort` from [hv_consort()].
#' @param ... Ignored; present for S3 consistency.
#' @return `x`, invisibly.
#'
#' @seealso [hv_consort()], [save_ppt()]
#'
#' @export
plot.hv_consort <- function(x, ...) {
  plot(x$plot, ...)
  invisible(x)
}

# ---------------------------------------------------------------------------
# Sample data generator
# ---------------------------------------------------------------------------

#' Generate a sample CONSORT tracker for demos and testing
#'
#' Simulates a cardiac surgery cohort and builds a three-stage
#' `hv_consort_tracker` suitable for testing [hv_consort()] and demonstrating
#' the tracker API.
#'
#' @param n    Integer. Total number of simulated patients.  Default `300`.
#' @param seed Integer random seed for reproducibility.  Default `42`.
#'
#' @return An `hv_consort_tracker` with three stages:
#'   *Screened* -> *Eligible* (excl: age < 18, no STS procedure) ->
#'   *Analyzed*  (excl: missing echocardiogram, prior trial).
#'
#' @examples
#' tracker <- sample_consort_data()
#' print(tracker)
#' hv_consort_summary(tracker)
#' \dontrun{
#'   hv_consort(tracker) |> plot()
#' }
#'
#' @importFrom stats runif rbinom
#' @export
sample_consort_data <- function(n = 300L, seed = 42L) {
  if (!is.numeric(n) || length(n) != 1L || n < 10L || n %% 1 != 0)
    stop("`n` must be a positive integer >= 10.", call. = FALSE)

  set.seed(seed)
  n <- as.integer(n)

  data <- data.frame(
    patient_id  = paste0("PT", sprintf("%04d", seq_len(n))),
    age         = as.integer(round(stats::runif(n, min = 5, max = 85))),
    has_sts_proc = stats::rbinom(n, 1L, prob = 0.92) == 1L,
    echo_avail  = stats::rbinom(n, 1L, prob = 0.88) == 1L,
    prior_trial = stats::rbinom(n, 1L, prob = 0.05) == 1L,
    stringsAsFactors = FALSE
  )

  hv_consort_start(data, patient_id = patient_id, label = "Screened") |>
    hv_consort_exclude(
      label        = "Eligible",
      col          = "excl_screen",
      age < 18     ~ "Age < 18",
      !has_sts_proc ~ "No qualifying STS procedure"
    ) |>
    hv_consort_exclude(
      label        = "Analyzed",
      col          = "excl_eligible",
      !echo_avail  ~ "Missing echocardiogram",
      prior_trial  ~ "Prior trial enrollment"
    )
}
