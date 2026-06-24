# at-risk-table.R
# Numbers-at-risk table harness: a shared empirical count helper, a renderer
# that turns a risk table into a bare ggplot panel, and a composer that stacks
# a survival curve over the table with aligned x-axes.
#
# `n.risk`, `report_time`, and `strata` are columns in the tidy risk table;
# suppress R CMD check notes about undefined globals used in aes().
utils::globalVariables(c("n.risk", "report_time", "strata"))

# ---------------------------------------------------------------------------
# Internal: empirical numbers-at-risk from subject-level data.
# n.risk at time t = number of subjects whose follow-up time is >= t.
# `status` is accepted for signature symmetry / future per-time event counts;
# v1 uses only `time` and `group`.
# NA `time` values are excluded from counts (via na.rm = TRUE in sum()) — intentional.
.atrisk_table <- function(time, status = NULL, group = NULL, report_times) {
  if (!is.numeric(time) || length(time) == 0L)
    stop("`time` must be a non-empty numeric vector.", call. = FALSE)
  if (!(is.numeric(report_times) && length(report_times) > 0L))
    stop("`report_times` must be a non-empty numeric vector.", call. = FALSE)
  if (is.null(group)) group <- rep("Overall", length(time))
  if (length(group) != length(time))
    stop("`group` must be the same length as `time`.", call. = FALSE)
  grp_chr       <- as.character(group)
  strata_levels <- if (is.factor(group)) levels(droplevels(group)) else
    sort(unique(grp_chr))

  rows <- lapply(strata_levels, function(st) {
    t_st <- time[grp_chr == st]
    do.call(rbind, lapply(report_times, function(rt) {
      data.frame(strata = st, report_time = rt,
                 n.risk = sum(t_st >= rt, na.rm = TRUE),
                 stringsAsFactors = FALSE)
    }))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
