# cluster-sankey-plot.R
# `node` and `freq` are computed stats provided by ggsankey::StatSankey
# inside after_stat(); suppress R CMD check notes about global variables.
utils::globalVariables(c("node", "freq"))
#
# Cluster stability Sankey diagram.
# Ports the cluster assignment flow chart from the PAM clustering analysis,
# showing how patients move between labelled clusters as the number of
# clusters K increases from 2 to 9.
#
# Key differences from the original script:
#  - No hard-coded column names or ordering vectors; caller supplies
#    cluster_cols and node_levels
#  - Colour palette is passed via node_colours (default: RColorBrewer Set1)
#  - NSE-free internal reshape (.make_sankey_long) avoids ggsankey::make_long()
#    non-standard evaluation
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
#' Sample Cluster Stability Sankey Data
#'
#' Generates a synthetic dataset with one row per patient and columns
#' `C2`–`C9` holding letter-labelled cluster assignments at successive values
#' of K (number of clusters). The hierarchical merge structure follows the
#' pattern from the HVTI PAM clustering analysis:
#'
#' | C9 label | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 |
#' |---|---|---|---|---|---|---|---|---|
#' | A | A | A | A | A | A | A | A | A |
#' | B | B | B | B | B | B | B | B | B |
#' | C | A | C | C | C | C | C | C | C |
#' | D | B | B | D | D | D | D | D | D |
#' | E | A | C | C | E | E | E | E | E |
#' | F | B | B | B | B | F | F | F | F |
#' | G | A | A | A | A | A | G | G | G |
#' | H | B | B | B | B | F | F | H | H |
#' | I | B | B | D | D | D | D | D | I |
#'
#' @param n     Number of patients. Default `300`.
#' @param probs Named numeric vector of C9-level cluster probabilities (must
#'   sum to 1), in the order `c(B, F, H, D, I, C, E, G, A)`. Default uses
#'   approximate equal-area proportions.
#' @param seed  Random seed. Default `42L`.
#'
#' @return A data frame with `n` rows and columns `C2`–`C9`, each a factor
#'   ordered by the hierarchical cluster labels.
#'
#' @seealso [hv_sankey()]
#'
#' @examples
#' dta <- sample_cluster_sankey_data(n = 200, seed = 42)
#' head(dta)
#' table(dta$C9)
#' @importFrom stats runif
#' @export
sample_cluster_sankey_data <- function(
    n     = 300L,
    probs = c(B = 0.18, F = 0.12, H = 0.06, D = 0.12, I = 0.04,
              C = 0.14, E = 0.11, G = 0.08, A = 0.15),
    seed  = 42L) {

  set.seed(seed)

  # Hierarchical merge table: each row is C2:C3:C4:C5:C6:C7:C8:C9
  merge_tree <- list(
    A = c("A", "A", "A", "A", "A", "A", "A", "A"),
    B = c("B", "B", "B", "B", "B", "B", "B", "B"),
    C = c("A", "C", "C", "C", "C", "C", "C", "C"),
    D = c("B", "B", "D", "D", "D", "D", "D", "D"),
    E = c("A", "C", "C", "E", "E", "E", "E", "E"),
    F = c("B", "B", "B", "B", "F", "F", "F", "F"),
    G = c("A", "A", "A", "A", "A", "G", "G", "G"),
    H = c("B", "B", "B", "B", "F", "F", "H", "H"),
    I = c("B", "B", "D", "D", "D", "D", "D", "I")
  )

  # Factor level orderings at each K
  levels_list <- list(
    C2 = c("B", "A"),
    C3 = c("B", "C", "A"),
    C4 = c("B", "D", "C", "A"),
    C5 = c("B", "D", "C", "E", "A"),
    C6 = c("B", "F", "D", "C", "E", "A"),
    C7 = c("B", "F", "D", "C", "E", "G", "A"),
    C8 = c("B", "F", "H", "D", "C", "E", "G", "A"),
    C9 = c("B", "F", "H", "D", "I", "C", "E", "G", "A")
  )

  # Normalise probs
  probs <- probs[names(probs) %in% names(merge_tree)]
  probs <- probs / sum(probs)

  # Assign each patient to a C9 cluster
  c9_assign <- sample(names(probs), size = n, replace = TRUE, prob = probs)

  # Build the full matrix from the merge tree
  col_names <- paste0("C", 2:9)
  mat       <- matrix(NA_character_, nrow = n, ncol = 8L,
                      dimnames = list(NULL, col_names))
  for (i in seq_len(n)) {
    mat[i, ] <- merge_tree[[c9_assign[i]]]
  }

  out <- as.data.frame(mat, stringsAsFactors = FALSE)
  for (col in col_names) {
    out[[col]] <- factor(out[[col]], levels = levels_list[[col]])
  }
  out
}

# ---------------------------------------------------------------------------
# Internal reshape helper — avoids ggsankey::make_long() NSE
.make_sankey_long <- function(data, cols) {
  k   <- length(cols)
  lst <- vector("list", k)
  for (i in seq_len(k)) {
    next_i    <- if (i < k) i + 1L else NA_integer_
    next_x    <- if (!is.na(next_i)) cols[next_i]                    else NA_character_
    next_node <- if (!is.na(next_i)) as.character(data[[cols[next_i]]]) else NA_character_
    lst[[i]] <- data.frame(
      x         = cols[i],
      node      = as.character(data[[cols[i]]]),
      next_x    = next_x,
      next_node = next_node,
      stringsAsFactors = FALSE
    )
  }
  out         <- do.call(rbind, lst)
  out$x       <- factor(out$x,       levels = cols)
  out$next_x  <- factor(out$next_x,  levels = cols)
  out
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare cluster stability Sankey data for plotting
#'
#' Validates a wide cluster-assignment data frame, resolves node level
#' ordering, computes default node colours if not supplied, and pre-computes
#' the long-format Sankey data.  Call \code{\link{plot.hv_sankey}} on the
#' result to obtain a bare \code{ggplot2} Sankey diagram using
#' \pkg{ggsankey} geoms.
#'
#' @param data          Data frame; one row per patient. Must contain all
#'   columns named in \code{cluster_cols}.
#' @param cluster_cols  Character vector of column names giving the cluster
#'   assignments at each value of K, in ascending K order. Default
#'   \code{paste0("C", 2:9)}.
#' @param node_levels   Character vector giving the display order of node
#'   labels (bottom to top within each column). If \code{NULL} (default),
#'   the existing factor levels of the first cluster column are used.
#' @param node_colours  Named character vector mapping node labels to fill
#'   colours. If \code{NULL} (default), colours are drawn from
#'   \code{RColorBrewer::brewer.pal(9, "Set1")} in the order
#'   \code{c(2, 6, 8, 4, 3, 5, 7, 1, 9)}.
#'
#' @return An object of class \code{c("hv_sankey", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{The long-format Sankey data frame (four columns:
#'     \code{x}, \code{node}, \code{next_x}, \code{next_node}).}
#'   \item{\code{$meta}}{Named list: \code{cluster_cols}, \code{node_levels},
#'     \code{node_colours}, \code{n_patients}, \code{n_k}.}
#'   \item{\code{$tables}}{Empty list.}
#' }
#'
#' @seealso \code{\link{plot.hv_sankey}},
#'   \code{\link{sample_cluster_sankey_data}}
#'
#' @examples
#' dta <- sample_cluster_sankey_data(n = 300, seed = 42)
#'
#' if (requireNamespace("ggsankey", quietly = TRUE)) {
#'   # 1. Build data object
#'   sn <- hv_sankey(dta)
#'   sn  # prints cluster cols and node count
#'
#'   # 2. Bare plot -- undecorated ggplot returned by plot.hv_sankey
#'   p <- plot(sn)
#'
#'   # 3. Decorate: axis labels and theme
#'   p +
#'     ggplot2::labs(x = NULL, title = "Cluster Stability: K = 2 to 9") +
#'     hv_theme("poster")
#' }
#'
#' @importFrom rlang .data
#' @export
hv_sankey <- function(data,
                         cluster_cols = paste0("C", 2:9),
                         node_levels  = NULL,
                         node_colours = NULL) {
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  missing_cols <- setdiff(cluster_cols, names(data))
  if (length(missing_cols) > 0L)
    stop("Column(s) not found in `data`: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  if (length(cluster_cols) < 2L)
    stop("`cluster_cols` must name at least two columns.", call. = FALSE)

  # Node ordering
  if (is.null(node_levels)) {
    first_col   <- data[[cluster_cols[1L]]]
    node_levels <- if (is.factor(first_col)) levels(first_col) else
      unique(as.character(first_col))
  }

  # Default colours
  if (is.null(node_colours)) {
    n_nodes  <- length(node_levels)
    set1     <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00",
                  "#FFFF33", "#A65628", "#F781BF", "#999999")
    set1_idx <- c(2L, 6L, 8L, 4L, 3L, 5L, 7L, 1L, 9L)
    pal      <- set1[set1_idx[seq_len(min(n_nodes, length(set1_idx)))]]
    if (n_nodes > length(pal)) pal <- rep_len(pal, n_nodes)
    node_colours <- stats::setNames(pal, node_levels[seq_along(pal)])
  }

  # Reshape to long format
  san_dta           <- .make_sankey_long(data, cluster_cols)
  san_dta$node      <- factor(san_dta$node,      levels = node_levels)
  san_dta$next_node <- factor(san_dta$next_node, levels = node_levels)

  new_hv_data(
    data = san_dta,
    meta = list(
      cluster_cols = cluster_cols,
      node_levels  = node_levels,
      node_colours = node_colours,
      n_patients   = nrow(data),
      n_k          = length(cluster_cols)
    ),
    tables   = list(),
    subclass = "hv_sankey"
  )
}


#' Print an hv_sankey object
#'
#' @param x   An \code{hv_sankey} object from \code{\link{hv_sankey}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_sankey <- function(x, ...) {
  m <- x$meta
  cat("<hv_sankey>\n")
  cat(sprintf("  Patients    : %d\n", m$n_patients))
  cat(sprintf("  K values    : %d  (%s)\n",
              m$n_k, paste(m$cluster_cols, collapse = ", ")))
  cat(sprintf("  Nodes       : %d  (%s)\n",
              length(m$node_levels), paste(m$node_levels, collapse = " ")))
  invisible(x)
}


#' Plot an hv_sankey object
#'
#' Draws a cluster stability Sankey diagram using \pkg{ggsankey} geoms.
#' \strong{Requires the \pkg{ggsankey} package.}  Install with:
#' \preformatted{remotes::install_github("davidsjoberg/ggsankey")}
#'
#' @param x           An \code{hv_sankey} object.
#' @param alpha       Transparency applied to flow bands and node labels.
#'   Default \code{0.8}.
#' @param label_size  Font size for node labels in points. Default \code{8}.
#' @param label_hjust Horizontal justification offset for node labels.
#'   Default \code{-0.05}.
#' @param ...         Ignored; present for S3 consistency.
#'
#' @return A \code{\link[ggplot2]{ggplot}} object using \pkg{ggsankey} geoms.
#'   Compose with \code{scale_fill_manual()}, \code{labs()}, \code{theme()},
#'   and \code{\link{hv_theme}}.
#'
#' @seealso \code{\link{hv_sankey}}, \code{\link{hv_theme}}
#'
#' @examples
#' dta <- sample_cluster_sankey_data(n = 300, seed = 42)
#'
#' if (requireNamespace("ggsankey", quietly = TRUE)) {
#'   plot(hv_sankey(dta)) +
#'     ggplot2::labs(x = NULL, title = "Cluster Stability: K = 2 to 9") +
#'     hv_theme("poster")
#'
#'   # Subset to K = 2 to 6
#'   plot(hv_sankey(dta, cluster_cols = paste0("C", 2:6))) +
#'     ggplot2::labs(x = NULL) +
#'     hv_theme("poster")
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_vline labs scale_fill_manual theme
#'   element_blank
#' @importFrom rlang .data
#' @export
plot.hv_sankey <- function(x,
                              alpha       = 0.8,
                              label_size  = 8,
                              label_hjust = -0.05,
                              ...) {
  if (!requireNamespace("ggsankey", quietly = TRUE)) {
    stop(
      "Package 'ggsankey' is required for plot.hv_sankey().\n",
      "Install it with: remotes::install_github(\"davidsjoberg/ggsankey\")",
      call. = FALSE
    )
  }

  san_dta      <- x$data
  node_colours <- x$meta$node_colours

  p <- ggplot2::ggplot(
    san_dta,
    ggplot2::aes(
      x         = .data$x,
      next_x    = .data$next_x,
      node      = .data$node,
      next_node = .data$next_node,
      fill      = .data$node
    )
  ) +
    ggplot2::geom_vline(
      ggplot2::aes(xintercept = as.numeric(.data$x)),
      linetype = "dashed",
      alpha    = alpha
    ) +
    ggsankey::geom_sankey(alpha = alpha) +
    ggsankey::geom_sankey_label(
      ggplot2::aes(
        label = ggplot2::after_stat(
          paste0(node, "\nn = ", freq)
        ),
        fill  = .data$node
      ),
      alpha  = alpha,
      hjust  = label_hjust,
      size   = label_size / ggplot2::.pt,
      colour = "black"
    ) +
    ggsankey::theme_sankey(base_size = 12) +
    ggplot2::scale_fill_manual(values = node_colours) +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(x = NULL)

  p
}
