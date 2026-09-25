# eda-pages.R
#
# A paginated EDA section: one hv_eda() panel per variable of one class,
# laid out as patchwork pages. The postage-stamp and EDA-report templates in
# hvtiRtemplates both draw through this, so a section in the combined report
# is the same figure as the standalone job. Pagination used to live in the
# template, where a second template would have had to copy it.
#
# Design: hvtiRtemplates dev/specs/2026-09-25-eda-composite-design.md, section 5.
# ---------------------------------------------------------------------------

#' Prepare a paginated EDA section
#'
#' Classifies each variable with [eda_classify_var()], keeps the ones that
#' belong to `section`, and prepares one [hv_eda()] panel for each. Call
#' [plot.hv_eda_pages()] on the result to lay the panels out as pages.
#'
#' The three sections split one dataset by variable class:
#'
#' - `"continuous"`: variables classified `"Cont"`, drawn as scatter plots
#'   against `x_col`.
#' - `"percent"`: categorical variables (`"Cat_Num"`, `"Cat_Char"`), drawn as
#'   bars filled to 100% in each bin of `x_col`.
#' - `"count"`: the same categorical variables, drawn as stacked counts.
#'
#' **The percent and count sections use the same bins.** Categorical panels
#' need a discrete x, so `x_col` is binned once, here, and every categorical
#' panel reads that bin. A whole-valued `x_col` (a calendar year) is used as
#' it is. A fractional one (years since an origin) is binned by `floor()`, so
#' each bar is one whole year, and `meta$x_binned` records that it was.
#' Continuous panels always use `x_col` unbinned.
#'
#' @param data Data frame; one row per patient.
#' @param x_col Name of the reference column, usually the year of operation.
#'   Default `"year"`.
#' @param section One of `"continuous"`, `"percent"` or `"count"`.
#' @param vars Character vector of the variables to consider, in page order.
#'   `NULL` (the default) means every column except `x_col`. Every name is
#'   checked at once, and the error lists all that are missing.
#' @param labels Optional named character vector of display labels, names
#'   being column names. A variable without a label is shown by its name.
#' @param unique_limit,unique_bound,type_overrides Passed to
#'   [eda_classify_var()].
#'
#' @return An object of class `c("hv_eda_pages", "hv_data")`:
#' \describe{
#'   \item{`$data`}{One row per variable in the section, in page order:
#'     `variable`, `label`, `var_type`.}
#'   \item{`$meta`}{Named list: `x_col`, `section`, `x_binned`, `n_vars`,
#'     `n_obs`, and `n_other`, the number of considered variables that belong
#'     to other sections.}
#'   \item{`$tables`}{`panels`, a named list of [hv_eda()] objects, one per
#'     variable.}
#' }
#'
#' @seealso [plot.hv_eda_pages()], [hv_eda()], [eda_classify_var()]
#'
#' @examples
#' dta <- sample_eda_data(n = 300, seed = 42)
#'
#' # Continuous variables, four panels to a page
#' cont <- hv_eda_pages(dta, x_col = "year", section = "continuous")
#' cont
#' pages <- plot(cont, ncol = 2, nrow = 2)
#' length(pages)
#' attr(pages[[1]], "variables")
#'
#' # Categorical variables as percentages, decorated across the whole page
#' pct <- hv_eda_pages(dta, x_col = "year", section = "percent",
#'                     labels = c(male = "Male", nyha = "NYHA class"))
#' plot(pct)[[1]] &
#'   ggplot2::scale_fill_brewer(palette = "Set1", na.value = "grey80") &
#'   theme_hv_manuscript(base_size = 8)
#' @export
hv_eda_pages <- function(data,
                         x_col          = "year",
                         section        = c("continuous", "percent", "count"),
                         vars           = NULL,
                         labels         = NULL,
                         unique_limit   = 6L,
                         unique_bound   = 100,
                         type_overrides = NULL) {
  .check_df(data)
  section <- match.arg(section)
  .check_cols(data, x_col)
  if (is.null(vars)) {
    vars <- setdiff(names(data), x_col)
  } else if (!is.character(vars) || anyNA(vars) || anyDuplicated(vars)) {
    stop("`vars` must be NULL or a character vector of distinct column names.", call. = FALSE)
  }
  .check_cols(data, vars)
  vars <- setdiff(vars, x_col)
  if (!is.null(labels) && (!is.character(labels) || is.null(names(labels)))) {
    stop("`labels` must be a named character vector.", call. = FALSE)
  }

  var_type <- vapply(vars, function(v) {
    eda_classify_var(data[[v]], unique_limit = unique_limit, unique_bound = unique_bound,
                     var_name = v, type_overrides = type_overrides)
  }, character(1))
  keep <- if (section == "continuous") var_type == "Cont" else var_type != "Cont"
  section_vars <- vars[keep]

  # One binning for every categorical panel, so the percent and count
  # sections of the same data put their bars in the same places.
  x <- data[[x_col]]
  x_binned <- FALSE
  if (section != "continuous" && is.numeric(x) && any(x != floor(x), na.rm = TRUE)) {
    x <- floor(x)
    x_binned <- TRUE
  }
  panel_data <- data
  panel_data[[x_col]] <- x

  label_of <- function(v) {
    if (!is.null(labels) && v %in% names(labels) && !is.na(labels[[v]])) labels[[v]] else v
  }
  panels <- lapply(section_vars, function(v) {
    hv_eda(panel_data, x_col = x_col, y_col = v, y_label = label_of(v),
           unique_limit = unique_limit, unique_bound = unique_bound,
           type_overrides = type_overrides, show_percent = section == "percent")
  })
  names(panels) <- section_vars

  new_hv_data(
    data = data.frame(
      variable = section_vars,
      label    = vapply(section_vars, label_of, character(1), USE.NAMES = FALSE),
      var_type = unname(var_type[keep]),
      stringsAsFactors = FALSE
    ),
    meta = list(
      x_col    = x_col,
      section  = section,
      x_binned = x_binned,
      n_vars   = length(section_vars),
      n_obs    = nrow(data),
      n_other  = sum(!keep)
    ),
    tables   = list(panels = panels),
    subclass = "hv_eda_pages"
  )
}


#' Print an hv_eda_pages object
#'
#' @param x   An `hv_eda_pages` object from [hv_eda_pages()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.hv_eda_pages <- function(x, ...) {
  m <- x$meta
  cat("<hv_eda_pages>\n")
  cat(sprintf("  Section     : %s\n", m$section))
  cat(sprintf("  Variables   : %d (%d in other sections)\n", m$n_vars, m$n_other))
  cat(sprintf("  x col       : %s%s\n", m$x_col, if (m$x_binned) " (binned by whole year)" else ""))
  cat(sprintf("  N obs       : %d\n", m$n_obs))
  invisible(x)
}


#' Plot an hv_eda_pages object
#'
#' Lays the section's panels out as pages of `ncol` by `nrow` panels. Nothing
#' is printed or saved; the caller prints, saves or captions each page.
#'
#' Colours and themes are left to the caller, as everywhere in this package.
#' Apply them to every panel of a page at once with patchwork's `&`:
#' `page & theme_hv_manuscript(base_size = 8)`.
#'
#' @param x An `hv_eda_pages` object.
#' @param ncol,nrow Panels across and down each page. Default 4 by 4.
#' @param alpha Point transparency for continuous panels. Default `0.5`,
#'   which keeps a dense cohort readable as a distribution.
#' @param ... Passed to [plot.hv_eda()], for example `smooth_span`.
#'
#' @return A list of patchwork pages, possibly empty. Each page carries the
#'   names of the variables on it as `attr(page, "variables")`, so a report
#'   can caption it.
#'
#' @seealso [hv_eda_pages()], [plot.hv_eda()]
#'
#' @examples
#' dta <- sample_eda_data(n = 300, seed = 42)
#' pages <- plot(hv_eda_pages(dta, section = "count"), ncol = 3, nrow = 2)
#' for (page in pages) message(paste(attr(page, "variables"), collapse = ", "))
#' @export
plot.hv_eda_pages <- function(x, ncol = 4L, nrow = 4L, alpha = 0.5, ...) {
  for (value in list(ncol, nrow)) {
    if (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value < 1 || value != floor(value)) {
      stop("`ncol` and `nrow` must be positive whole numbers.", call. = FALSE)
    }
  }
  .check_alpha(alpha)
  panels <- x$tables$panels
  if (!length(panels)) return(list())

  plots <- lapply(panels, plot, alpha = alpha, ...)
  groups <- split(seq_along(plots), ceiling(seq_along(plots) / (ncol * nrow)))
  unname(lapply(groups, function(i) {
    page <- patchwork::wrap_plots(plots[i], ncol = ncol, nrow = nrow)
    attr(page, "variables") <- names(panels)[i]
    page
  }))
}
