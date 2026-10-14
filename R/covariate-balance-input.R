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
  if (!identical(attr(x, "print.options")$binary, "std"))
    stop(paste(
      "`bal.tab()` reported raw differences for binary covariates, which cannot",
      "share an axis with standardized differences. Re-run `bal.tab()` with",
      "binary = \"std\"."), call. = FALSE)

  if (inherits(x, "bal.tab.multi")) {
    parts <- lapply(names(x$Pair.Balance), function(nm) {
      el <- x$Pair.Balance[[nm]]
      attr(el, "print.options") <- attr(x, "print.options")
      d <- .cb_from_baltab(el, stats, group_labels)
      d$pair <- nm
      d
    })
    return(do.call(rbind, parts))
  }

  bal <- x$Balance
  if (!is.data.frame(bal))
    stop(paste(
      "This `bal.tab` variant has no `$Balance` table. For multiply imputed",
      "data, pass a list of per-imputation `bal.tab()` results."), call. = FALSE)

  groups <- c(Un = group_labels[1], Adj = group_labels[2])
  out <- list()
  for (s in stats) {
    for (sfx in names(groups)) {
      cn <- paste0(.cb_baltab_cols[[s]], ".", sfx)
      if (!cn %in% names(bal) || all(is.na(bal[[cn]]))) next
      # The variance ratio is undefined for binary covariates, not missing.
      keep <- if (s == "variance_ratio") bal$Type != "Binary" else rep(TRUE, nrow(bal))
      out[[length(out) + 1L]] <- data.frame(
        variable = rownames(bal)[keep],
        group    = groups[[sfx]],
        stat     = s,
        pair     = NA_character_,
        std_diff = bal[[cn]][keep] * if (s == "smd") 100 else 1,
        stringsAsFactors = FALSE
      )
    }
    if (!any(vapply(out, function(d) identical(d$stat[1], s), logical(1))))
      stop(sprintf(paste(
        "The `bal.tab()` result carries no %s. Re-run it with",
        "stats = c(\"m\", \"v\", \"ks\") (needs \"%s\")."),
        cb_stat_labels[[s]], .cb_baltab_flag[[s]]), call. = FALSE)
  }
  do.call(rbind, out)
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

# NULL when `x` is not an adapter input, so the data-frame path (and its
# existing error messages) handles it unchanged.
.cb_as_long <- function(x, stats, group_labels) {
  if (.cb_is_source(x))
    return(list(data = .cb_one(x, stats, group_labels), n_imputations = 1L))
  NULL
}
