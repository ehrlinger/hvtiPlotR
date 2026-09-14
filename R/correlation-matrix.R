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
  a1c <- stats::rnorm(n, 6.5, 1.2)
  data.frame(
    a1c        = round(a1c, 1),
    glucose    = round(20 * a1c + stats::rnorm(n, 0, 25)),
    creatinine = round(stats::rlnorm(n, 0, 0.3), 2),
    albumin    = round(4 - 0.1 * a1c + stats::rnorm(n, 0, 0.4), 1),
    a1c_grp    = cut(a1c, c(-Inf, 6, 7, Inf), labels = c("<6", "6-7", ">7"))
  )
}

#' Prepare a scatter-plot matrix
#'
#' The plot half of SAS `proc corr ... plots=matrix`: one scatter panel per
#' unordered pair of `vars`, lower triangle only. Call [plot()] on the result
#' for a bare `ggplot`; the coefficient table with Fisher intervals is
#' `hvtiRtables::hv_correlation_table()`.
#'
#' Rows missing either coordinate are dropped panel by panel (pairwise
#' deletion, as `proc corr` does), so a variable with missing values thins
#' only the panels it appears in.
#'
#' @param data Data frame; one row per patient.
#' @param vars Character vector of at least two numeric columns, in display order.
#' @param labels Optional character vector of display labels, one per `vars`.
#' @param method Coefficient stored in `$tables$coefficients`: `"pearson"` or `"spearman"`.
#' @return An object of class `c("hv_correlation_matrix", "hv_data")`:
#'   `$data` (columns `col_var`, `row_var`, `x`, `y`), `$meta` (`vars`,
#'   `labels`, `method`, `n_obs`), and `$tables$coefficients`, the pairwise
#'   coefficient matrix.
#' @seealso [plot.hv_correlation_matrix()], [sample_correlation_data()]
#' @examples
#' d <- sample_correlation_data()
#' cm <- hv_correlation_matrix(d, c("a1c", "glucose", "creatinine", "albumin"))
#' plot(cm) + theme_hv_manuscript()
#' @export
hv_correlation_matrix <- function(data, vars, labels = NULL,
                                  method = c("pearson", "spearman")) {
  .check_df(data)
  method <- match.arg(method)
  if (!is.character(vars) || length(vars) < 2L)
    stop("`vars` needs at least two column names.", call. = FALSE)
  .check_cols(data, vars)
  not_num <- vars[!vapply(data[vars], is.numeric, logical(1))]
  if (length(not_num))
    stop("A scatter-plot matrix needs numeric columns; not numeric: ",
         paste(not_num, collapse = ", "), call. = FALSE)
  if (is.null(labels)) labels <- vars
  if (length(labels) != length(vars))
    stop("`labels` needs one label per `vars` entry (", length(vars), ").",
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
  ggplot2::ggplot(x$data, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_point(alpha = alpha, size = point_size) +
    ggplot2::facet_grid(rows = ggplot2::vars(.data$row_var),
                        cols = ggplot2::vars(.data$col_var),
                        scales = "free", switch = "both") +
    ggplot2::labs(x = NULL, y = NULL)
}
