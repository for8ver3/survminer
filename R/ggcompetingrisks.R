#' Cumulative Incidence Curves for Competing Risks
#' @importFrom cmprsk cuminc
#' @importFrom survival survfit
#' @description This function plots Cumulative Incidence Curves. For \code{cuminc} objects it's a \code{ggplot2} version of \code{plot.cuminc}.
#' For \code{survfitms} objects a different geometry is used, as suggested by \code{@@teigentler}.
#' @param fit an object of a class \link{cuminc} - created with \link{cuminc} function or \code{survfitms} created with \link{survfit} function.
#' @param gnames a vector with group names. If not supplied then will be extracted from \code{fit} object (\code{cuminc} only).
#' @param gsep a separator that extracts group names and event names from \code{gnames} object (\code{cuminc} only).
#' @param multiple_panels if \code{TRUE} then groups will be plotted in different panels (\code{cuminc} only).
#' @param ggtheme function, \code{ggplot2} theme name. Default value is \link{theme_survminer}.
#'  Allowed values include ggplot2 official themes: see \code{\link[ggplot2]{theme}}.
#'@param ... further arguments passed to the function \code{\link[ggpubr]{ggpar}} for customizing the plot.
#' @return Returns an object of class \code{gg}.
#'
#' @author Przemyslaw Biecek, \email{przemyslaw.biecek@@gmail.com}
#'
#' @examples
#' set.seed(2)
#' ss <- rexp(100)
#' gg <- factor(sample(1:3,100,replace=TRUE),1:3,c('BRCA','LUNG','OV'))
#' cc <- factor(sample(0:2,100,replace=TRUE),0:2,c('no event', 'death', 'progression'))
#' strt <- sample(1:2,100,replace=TRUE)
#'
#' # handles cuminc objects
#' print(fit <- cmprsk::cuminc(ss,cc,gg,strt))
#' ggcompetingrisks(fit)
#' ggcompetingrisks(fit, multiple_panels = FALSE)
#'
#' # handles survfitms objects
#' library(survival)
#' df <- data.frame(time = ss, group = gg, status = cc, strt)
#' fit2 <- survfit(Surv(time, status, type="mstate") ~ 1, data=df)
#' ggcompetingrisks(fit2)
#' fit3 <- survfit(Surv(time, status, type="mstate") ~ group, data=df)
#' ggcompetingrisks(fit3)
#' \dontrun{
#'   library(ggsci)
#'   library(cowplot)
#'   ggcompetingrisks(fit3) + theme_cowplot() + scale_fill_jco()
#' }
#' @export

ggcompetingrisks <- function(fit, gnames = NULL, gsep=" ",
                             multiple_panels = TRUE,
                             ggtheme = theme_survminer(), ...) {
  stopifnot(any(class(fit) %in% c("cuminc", "survfitms")))

  if (any(class(fit) == "cuminc")) {
   pl <- ggcompetingrisks.cuminc(fit = fit, gnames=gnames,
                                  gsep=gsep, multiple_panels=multiple_panels)
  }
  if (any(class(fit) == "survfitms")) {
    pl <- ggcompetingrisks.survfitms(fit = fit)
  }

  pl <- pl + ggtheme +
    ylab("Probability of an event") + xlab("Time") +
    ggtitle("Cumulative incidence functions")
  ggpubr::ggpar(pl, ...)
}


ggcompetingrisks.cuminc <- function(fit, gnames = NULL, gsep=" ",
                                    multiple_panels = TRUE) {
  if (!is.null(fit$Tests))
    fit <- fit[names(fit) != "Tests"]
  fit2 <- lapply(fit, `[`, 1:2)
  if (is.null(gnames)) gnames <- names(fit2)
  fit2_list <- lapply(seq_along(gnames), function(ind) {
    df <- as.data.frame(fit2[[ind]])
    df$name <- gnames[ind]
    df
  })
  time <- est <- event <- group <- NULL
  df <- do.call(rbind, fit2_list)
  df$event <- sapply(strsplit(df$name, split=gsep), `[`, 2)
  df$group <- sapply(strsplit(df$name, split=gsep), `[`, 1)
  pl <- ggplot(df, aes(time, est, color=event))
  if (multiple_panels) {
    pl <- ggplot(df, aes(time, est, color=event)) + facet_wrap(~group)
  } else {
    pl <- ggplot(df, aes(time, est, color=event, linetype=group))
  }
  pl +
    geom_line()
}

ggcompetingrisks.survfitms <- function(fit) {
  times <- fit$time
  psta <- as.data.frame(fit$pstate)
  colnames(psta) <- fit$states
  if (is.null(fit$strata)) {
    psta$strata <- "all"
  } else {
    psta$strata <- rep(names(fit$strata), fit$strata)
  }
  psta$times <- times

  event <- value <- strata <- NULL
  pstal <- gather(psta, event, value, -strata, -times)

  ggplot(pstal, aes(times, value, fill=event)) +
    geom_area() + facet_wrap(~strata)

}
