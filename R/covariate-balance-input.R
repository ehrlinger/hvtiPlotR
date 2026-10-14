###############################################################################
## Input adapters for hv_balance(): turn a cobalt::bal.tab() result, an
## hvtiRpropensity ps_* object, or a list of either (one per imputation) into
## the long data frame hv_balance() plots. Structure is read directly; no
## cobalt or hvtiRpropensity functions are called.
###############################################################################

# bal.tab column stem for each stat, and the stats = argument that requests it.
.cb_baltab_cols <- c(smd = "Diff", variance_ratio = "V.Ratio", ks = "KS")
.cb_baltab_flag <- c(smd = "m", variance_ratio = "v", ks = "ks")

.cb_from_baltab <- function(x, stats, group_labels) {
  opts <- attr(x, "print.options")
  if (!identical(opts$binary, "std"))
    stop(paste(
      "`bal.tab()` reported raw differences for binary covariates, which cannot",
      "share an axis with standardized differences. Re-run `bal.tab()` with",
      "binary = \"std\"."), call. = FALSE)
  if (!is.null(opts$continuous) && !identical(opts$continuous, "std"))
    stop(paste(
      "`bal.tab()` reported raw differences for continuous covariates, which cannot",
      "share an axis with standardized differences. Re-run `bal.tab()` with",
      "continuous = \"std\"."), call. = FALSE)

  if (inherits(x, "bal.tab.multi")) {
    parts <- lapply(names(x$Pair.Balance), function(nm) {
      el <- x$Pair.Balance[[nm]]
      attr(el, "print.options") <- opts
      d <- .cb_from_baltab(el, stats, group_labels)
      d$pair <- nm
      d
    })
    out <- do.call(rbind, parts)
    attr(out, "no_unadjusted") <- any(vapply(parts, function(d) isTRUE(attr(d, "no_unadjusted")),
                                             logical(1)))
    return(out)
  }

  bal <- x$Balance
  if (!is.data.frame(bal))
    stop(paste(
      "This `bal.tab` variant has no `$Balance` table. For multiply imputed",
      "data, pass a list of per-imputation `bal.tab()` results."), call. = FALSE)

  groups <- c(Un = group_labels[1], Adj = group_labels[2])
  out <- list()
  no_un <- FALSE
  for (s in stats) {
    # The variance ratio is undefined for binary covariates, not missing.
    keep <- if (s == "variance_ratio") !(bal$Type %in% "Binary") else rep(TRUE, nrow(bal))
    col_seen <- FALSE
    drawn <- character(0)
    for (sfx in names(groups)) {
      cn <- paste0(.cb_baltab_cols[[s]], ".", sfx)
      if (!cn %in% names(bal)) next
      col_seen <- TRUE
      val <- bal[[cn]][keep]
      if (!length(val) || all(is.na(val))) next
      drawn <- c(drawn, sfx)
      out[[length(out) + 1L]] <- data.frame(
        variable = rownames(bal)[keep],
        group    = groups[[sfx]],
        stat     = s,
        pair     = NA_character_,
        std_diff = val * if (s == "smd") 100 else 1,
        stringsAsFactors = FALSE
      )
    }
    if (!length(drawn)) {
      if (col_seen && !any(keep))
        stop(sprintf(paste(
          "The variance ratio is undefined for binary covariates, and every covariate",
          "here is binary; drop \"%s\" from `stats`."), s), call. = FALSE)
      stop(sprintf(paste(
        "The `bal.tab()` result carries no %s. Re-run it with",
        "stats = c(\"m\", \"v\", \"ks\") (needs \"%s\")."),
        cb_stat_labels[[s]], .cb_baltab_flag[[s]]), call. = FALSE)
    }
    if (identical(drawn, "Adj")) no_un <- TRUE
  }
  out <- do.call(rbind, out)
  attr(out, "no_unadjusted") <- no_un
  out
}

# SMD tables written by ps_match() and ps_weight(): before/after pairs.
.cb_ps_tables <- list(c("smd_before", "smd_after"), c("smd_unweighted", "smd_weighted"))

.cb_from_ps <- function(x, stats, group_labels) {
  extra <- setdiff(stats, "smd")
  if (length(extra))
    stop(sprintf(paste(
      "A `%s` object carries standardized differences only, not %s. Build the",
      "balance table with cobalt::bal.tab(..., binary = \"std\",",
      "stats = c(\"m\", \"v\", \"ks\")) and pass that instead."),
      class(x)[1], paste(cb_stat_labels[extra], collapse = " or ")), call. = FALSE)

  hit <- Filter(function(nm) all(nm %in% names(x$tables)), .cb_ps_tables)
  if (!length(hit))
    stop(sprintf(paste(
      "The `%s` object has no SMD tables (expected smd_before/smd_after or",
      "smd_unweighted/smd_weighted in `$tables`)."), class(x)[1]), call. = FALSE)

  nm <- hit[[1]]
  do.call(rbind, lapply(1:2, function(i) {
    t <- x$tables[[nm[i]]]
    data.frame(
      variable = as.character(t$variable),
      group    = group_labels[i],
      stat     = "smd",
      pair     = NA_character_,
      std_diff = t$smd * 100,
      stringsAsFactors = FALSE
    )
  }))
}

.cb_is_source <- function(x) inherits(x, "bal.tab") || inherits(x, "ps_data")

.cb_one <- function(x, stats, group_labels) {
  if (inherits(x, "bal.tab")) .cb_from_baltab(x, stats, group_labels)
  else .cb_from_ps(x, stats, group_labels)
}

# Signed mean of each covariate x group x stat x pair across imputations.
# Every imputation must carry the same rows; the first fixes the order.
.cb_pool <- function(parts) {
  key  <- function(d) paste(d$variable, d$group, d$stat, d$pair, sep = "\r")
  ref  <- sort(key(parts[[1]]))
  same <- vapply(parts, function(d) identical(sort(key(d)), ref), logical(1))
  if (!all(same))
    stop(sprintf(paste(
      "Imputation(s) %s differ from the first in their covariates, groups or",
      "statistics; every imputation must have the same balance table rows."),
      paste(which(!same), collapse = ", ")), call. = FALSE)

  # Arithmetic mean for differences and KS; geometric mean for variance ratios
  # (the mean of their logs), so a ratio of 0.5 and one of 2 pool to 1. An NA in
  # any imputation makes the pooled value NA.
  fwd   <- function(d) {
    v <- d$std_diff
    i <- d$stat == "variance_ratio"
    v[i] <- log(v[i])
    v
  }
  all   <- do.call(rbind, parts)
  means <- tapply(fwd(all), key(all), mean)
  out   <- parts[[1]]
  pooled <- as.vector(means[key(out)])
  vr     <- out$stat == "variance_ratio"
  pooled[vr] <- exp(pooled[vr])
  out$std_diff <- pooled
  attr(out, "no_unadjusted") <- NULL
  out
}

# NULL when `x` is not an adapter input, so the data-frame path (and its
# existing error messages) handles it unchanged. A plain list such as
# list(variable = "x") is not an adapter input.
.cb_as_long <- function(x, stats, group_labels) {
  if (.cb_is_source(x)) {
    d <- .cb_one(x, stats, group_labels)
    .cb_note_no_unadjusted(isTRUE(attr(d, "no_unadjusted")))
    attr(d, "no_unadjusted") <- NULL
    return(list(data = d, n_imputations = 1L))
  }
  if (!is.list(x) || is.data.frame(x)) return(NULL)
  if (!length(x))
    stop("`data` is an empty list; pass one balance object per imputation.", call. = FALSE)

  is_src <- vapply(x, .cb_is_source, logical(1))
  if (!any(is_src)) return(NULL)
  if (!all(is_src))
    stop(paste(
      "When `data` is a list, every element must be a `bal.tab` or `ps_*`",
      "object (one per imputation)."), call. = FALSE)
  kinds <- unique(vapply(x, function(o) class(o)[1], character(1)))
  if (length(kinds) > 1L)
    stop(sprintf("Imputations must all be the same kind of object; got %s.",
                 paste(kinds, collapse = ", ")), call. = FALSE)

  parts <- lapply(x, .cb_one, stats = stats, group_labels = group_labels)
  .cb_note_no_unadjusted(any(vapply(parts, function(d) isTRUE(attr(d, "no_unadjusted")),
                                    logical(1))))
  list(data = .cb_pool(parts), n_imputations = length(x))
}

# One message per hv_balance() call when a bal.tab skipped its unadjusted group.
.cb_note_no_unadjusted <- function(flag) {
  if (flag)
    message("`bal.tab()` result has no unadjusted balance; re-run it with un = TRUE ",
            "to draw the Before group.")
}
