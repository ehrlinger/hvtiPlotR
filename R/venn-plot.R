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
