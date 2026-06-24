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
