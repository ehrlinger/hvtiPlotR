#' Sample data for hv_correlation_matrix()
#'
#' Simulated preoperative labs with a built-in dependence on HbA1c, shaped
#' like the correlation job it stands in for.
#'
#' @param n Number of patients.
#' @param seed Random seed.
#' @return A data frame with numeric `a1c`, `glucose`, `creatinine`,
#'   `albumin`, and a three-level factor `a1c_grp`.
#' @examples
#' head(sample_correlation_data(n = 10))
#' @export
sample_correlation_data <- function(n = 300, seed = 42) {
  set.seed(seed)
  a1c <- round(stats::rnorm(n, 6.5, 1.2), 1)
  data.frame(
    a1c        = a1c,
    glucose    = round(20 * a1c + stats::rnorm(n, 0, 25)),
    creatinine = round(stats::rlnorm(n, 0, 0.3), 2),
    albumin    = round(4 - 0.1 * a1c + stats::rnorm(n, 0, 0.4), 1),
    a1c_grp    = factor(
      ifelse(a1c < 6, "<6", ifelse(a1c <= 7, "6-7", ">7")),
      levels = c("<6", "6-7", ">7")
    )
  )
}

#' Prepare a scatter-plot matrix
#'
#' The scatter-plot-matrix analogue of SAS `proc corr ... plots=matrix`: one
#' scatter panel per unordered pair of `vars`, lower triangle only. It is the
#' plot half of the `dc-tables` job in the hvtiR job catalog. Call [plot()]
#' on the result for a bare `ggplot`; the coefficient table with Fisher
#' intervals is `hvtiRtables::hv_correlation_table()`.
#'
#' Rows missing either coordinate are dropped panel by panel (pairwise
#' deletion, as `proc corr` does), so a variable with missing values thins
#' only the panels it appears in.
#'
#' A single `warning()` names variables with fewer than 3 non-missing values or
#' no variation, and otherwise-usable pairs with fewer than 3 pairwise-complete
#' observations. These panels are sparse or flat, so their coefficients may be
#' unstable or `NA`.
#'
#' At large sizes (about 73 MB at 17 variables by 11,000 rows), write a raster
#' format such as PNG rather than PDF, since every point is a vector object in
#' a PDF, and lower `alpha` so overplotted panels stay legible.
#'
#' @param data Data frame; one row per patient.
#' @param vars Character vector of at least two numeric columns, in display order.
#' @param labels Optional character vector of display labels, one per `vars`.
#' @param method Coefficient stored in `$tables$coefficients`: `"pearson"` or `"spearman"`.
#' @return An object of class `c("hv_correlation_matrix", "hv_data")`:
#'   `$data` (columns `col_var`, `row_var`, `x`, `y`), `$meta` (`vars`,
#'   `labels`, `method`, `n_obs`, which is `nrow(data)` before any pairwise
#'   deletion, not a per-panel count), and `$tables$coefficients`, the
#'   pairwise coefficient matrix.
#' @seealso [plot.hv_correlation_matrix()], [sample_correlation_data()]
#' @references SAS template: `descriptive/dc.tables.ods.sas`.
#' @examples
#' d <- sample_correlation_data()
#' cm <- hv_correlation_matrix(d, c("a1c", "glucose", "creatinine", "albumin"))
#' plot(cm) + theme_hv_manuscript()
#' # strip.placement moves the variable names outside the axis
#' plot(cm) + ggplot2::theme(strip.placement = "outside")
#' @export
hv_correlation_matrix <- function(data, vars, labels = NULL,
                                  method = c("pearson", "spearman")) {
  .check_df(data)
  method <- match.arg(method)
  .check_cols(data, vars)
  if (!is.character(vars) || length(vars) < 2L)
    stop("`vars` needs at least two column names.", call. = FALSE)
  .check_no_duplicates(vars, "vars")
  not_num <- vars[!vapply(data[vars], is.numeric, logical(1))]
  if (length(not_num))
    stop("A scatter-plot matrix needs numeric columns; not numeric: ",
         paste(not_num, collapse = ", "), call. = FALSE)
  if (is.null(labels)) labels <- vars
  if (length(labels) != length(vars))
    stop("`labels` needs one label per `vars` entry (", length(vars), ").",
         call. = FALSE)
  if (!is.character(labels) || anyNA(labels) || anyDuplicated(labels))
    stop("`labels` must be unique, non-missing strings, one per `vars` entry.",
         call. = FALSE)

  idx <- utils::combn(seq_along(vars), 2L)
  long <- do.call(rbind, lapply(seq_len(ncol(idx)), function(p) {
    i <- idx[1L, p]
    j <- idx[2L, p]
    x <- data[[vars[i]]]
    y <- data[[vars[j]]]
    ok <- !is.na(x) & !is.na(y)
    data.frame(col_var = rep(labels[i], sum(ok)), row_var = rep(labels[j], sum(ok)),
               x = x[ok], y = y[ok], stringsAsFactors = FALSE)
  }))
  long$col_var <- factor(long$col_var, levels = labels)
  long$row_var <- factor(long$row_var, levels = labels)

  n_ok <- vapply(data[vars], function(x) sum(!is.na(x)), integer(1))
  const <- vapply(data[vars], function(x) {
    x <- x[!is.na(x)]
    length(x) >= 1L && length(unique(x)) == 1L
  }, logical(1))
  sparse <- vars[n_ok < 3L]
  flat <- vars[const]
  pair_n <- vapply(seq_len(ncol(idx)), function(p) {
    sum(stats::complete.cases(data[vars[idx[, p]]]))
  }, integer(1))
  pair_usable <- !vars[idx[1L, ]] %in% sparse & !vars[idx[2L, ]] %in% sparse
  sparse_pairs <- vapply(which(pair_n < 3L & pair_usable), function(p) {
    paste(vars[idx[, p]], collapse = " / ")
  }, character(1))
  warning_parts <- character()
  if (length(sparse)) {
    warning_parts <- c(warning_parts,
                       paste0("Fewer than 3 non-missing values (sparse): ",
                              paste(sparse, collapse = ", ")))
  }
  if (length(flat)) {
    warning_parts <- c(warning_parts,
                       paste0("No variation: ", paste(flat, collapse = ", ")))
  }
  if (length(sparse_pairs)) {
    warning_parts <- c(warning_parts,
                       paste0("Fewer than 3 pairwise-complete values (sparse overlap): ",
                              paste(sparse_pairs, collapse = ", ")))
  }
  if (length(warning_parts)) {
    warning(
      paste(warning_parts, collapse = "; "),
      ". Sparse or flat panels can have unstable or NA coefficients.",
      call. = FALSE
    )
  }

  coef <- suppressWarnings(stats::cor(data[vars], use = "pairwise.complete.obs",
                                      method = method))
  dimnames(coef) <- list(labels, labels)

  new_hv_data(
    data = long,
    meta = list(vars = vars, labels = labels, method = method,
                n_obs = nrow(data)),
    tables = list(coefficients = coef),
    subclass = "hv_correlation_matrix"
  )
}

#' Plot an hv_correlation_matrix object
#'
#' Bare scatter-plot matrix: points only, free scales per panel, variable
#' names in the strips. Decorate with a `theme_hv_*()` theme.
#'
#' @param x An `hv_correlation_matrix` object.
#' @param alpha Point transparency; large cohorts need it low.
#' @param point_size Point size.
#' @param ... Ignored.
#' @return A `ggplot` object.
#' @importFrom rlang .data
#' @export
plot.hv_correlation_matrix <- function(x, alpha = 0.3, point_size = 0.6, ...) {
  .check_alpha(alpha)
  ggplot2::ggplot(x$data, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_point(alpha = alpha, size = point_size) +
    ggplot2::facet_grid(rows = ggplot2::vars(.data$row_var),
                        cols = ggplot2::vars(.data$col_var),
                        scales = "free", switch = "both", drop = FALSE) +
    ggplot2::labs(x = NULL, y = NULL)
}
