#' Dot plot
#'
#' @param pm_df_list A named list of performance metric data frames from
#'   [get_probs()]. The names will be used as the plot labels.
#'   Can also be a single data frame from [get_probs()].
#' @param type The type of plot. Multipanel `"facet"` vs. single panel
#'   `"single"`. In the single panel version, a line segment represents the
#'   upper and lower values across the scenarios and the dot represents the
#'   mean.
#' @param custom_pal An optional custom color palette. Should be a named
#'   character vector
#' @param dodge The amount to separate or "dodge" the dots.
#' @param bar_alpha Background bar transparency. 0 will omit.
#' @param pt_size Point size.
#' @param french French?
#' @return A ggplot2 object
#' @export
#' @examples
#' probs <- get_probs(mse_example, "P40", "P100", "PNOF", "LTY", "AAVY")
#' pm <- list()
#' pm[[1]] <- get_probs(mse_example, "P40", "P100", "PNOF", "LTY", "AAVY")
#' pm[[2]] <- get_probs(mse_example, "P40", "P100", "PNOF", "LTY", "AAVY")
#' names(pm) <- c("Scenario 1", "Scenario 2")
#' plot_dots(pm)
#' plot_dots(pm, type = "facet")
plot_dots <- function(pm_df_list, type = c("single", "facet"),
  custom_pal = NULL, dodge = 0.6, bar_alpha = 0.2,
  pt_size = 2.25,
  french = isTRUE(getOption("french"))) {

  if (!is.data.frame(pm_df_list)) {
    df <- bind_rows(pm_df_list, .id = "scenario")
  } else {
    df <- pm_df_list
    df$scenario <- ""
  }

  type <- match.arg(type)
  if (type == "single") {
    pm_avg <- condense_func(df, mean, label = "prob")
    pm_min <- condense_func(df, min, label = "min")
    pm_max <- condense_func(df, max, label = "max")
    pm_min2 <- condense_func(df, skater_min, label = "skater_min")
    pm_max2 <- condense_func(df, skater_max, label = "skater_max")
    pm <- dplyr::left_join(pm_avg, pm_min, by = c("MP", "pm")) %>%
      dplyr::left_join(pm_max, by = c("MP", "pm")) %>%
      dplyr::left_join(pm_min2, by = c("MP", "pm")) %>%
      dplyr::left_join(pm_max2, by = c("MP", "pm"))
  } else {
    pm <- reshape2::melt(df,
      id.vars = c("MP", "scenario"),
      value.name = "prob",
      variable.name = "pm"
    )
  }
  pm$`Reference` <- ifelse(grepl("ref", pm$MP), "True", "False")

  n_mp <- length(unique(pm$MP))
  ref_or_not <- dplyr::select(pm, .data$MP, .data$Reference) %>% dplyr::distinct()
  mp_shapes <- vector(mode = "numeric", length = n_mp)
  mp_shapes <- ifelse(ref_or_not$Reference == "True", 21, 19)
  names(mp_shapes) <- ref_or_not$MP

  g <- ggplot(pm, aes_string("pm", "prob", group = "MP", colour = "MP")) +
    theme_pbs() +
    theme(panel.border = element_blank()) +
    annotate(geom = "segment", y = Inf, yend = Inf, x = -Inf, xend = Inf, colour = "grey70") +
    annotate(geom = "segment", y = 0, yend = 0, x = -Inf, xend = Inf, colour = "grey70") +
    annotate(geom = "segment", y = -Inf, yend = Inf, x = Inf, xend = Inf, colour = "grey70") +
    annotate(geom = "segment", y = -Inf, yend = Inf, x = -Inf, xend = -Inf, colour = "grey70")

  if (type == "single") {
    g <- g + geom_linerange(aes_string(ymin = "min", ymax = "max"),
      position = position_dodge(width = dodge), alpha = 0.8, lwd = 0.4
    )
    g <- g + geom_linerange(aes_string(ymin = "skater_min", ymax = "skater_max"),
      position = position_dodge(width = dodge), alpha = 0.8, lwd = 0.85
    )
  }

  g <- g +
    ggplot2::scale_shape_manual(values = mp_shapes) +
    ylab(en2fr("Probability", french, allow_missing = TRUE)) +
    xlab(en2fr("Performance metric", french, allow_missing = TRUE)) +
    theme(
      panel.grid.major.y = element_line(colour = "grey85"),
      panel.grid.minor.y = element_line(colour = "grey96"),
      axis.ticks.x.bottom = element_blank()
    )

  if (type == "facet") {
    g <- g + facet_wrap(~scenario)
  }

  g <- g + geom_point(aes_string(x = "pm", y = "prob", shape = "MP"),
    position = position_dodge(width = dodge), size = pt_size,
  )

  temp <- ggplot2::ggplot_build(g)$data
  d <- temp[[length(temp)]] %>% dplyr::filter(.data$PANEL == 1)

  a <- sort(abs(sort(unique(round(diff(d$x), 9))))) # minimum gap
  g <- g + annotate(
    geom = "rect", xmin = d$x - a[[1]] / 2, xmax = d$x + a[[1]] / 2,
    ymin = -Inf, ymax = Inf, fill = "grey75", alpha = bar_alpha
  ) + labs(colour = en2fr("MP", french), shape = en2fr("MP", french),
    fill = en2fr("MP", french))

  g <- g + coord_cartesian(
    expand = FALSE, ylim = c(0, 1),
    xlim = range(d$x) + c(-a[1], a[1]), clip = "off"
  )

  if (!is.null(custom_pal)) {
    g <- g + scale_color_manual(values = custom_pal)
  }

  g
}

skater_min <- function(x, ...) {
  x <- x[!is.na(x)]
  x <- sort(x)[-1]
  min(x)
}

skater_max <- function(x, ...) {
  x <- x[!is.na(x)]
  x <- rev(sort(x))[-1]
  max(x)
}
