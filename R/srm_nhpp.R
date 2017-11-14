#' NHPP-based software reliability model
#'
#' Estimate model parameters for NHPP-based software reliability models.
#'
#' The control argument is a list that can supply any of the following components:
#' \describe{
#'   \item{maxiter}{An integer for the maximum number of iterations in the fitting algorithm.}
#'   \item{reltol}{A numeric value. The algorithm stops if the relative error is
#' less than \emph{reltol} and the absolute error is less than \emph{abstol}.}
#'   \item{abstol}{A numeric value. The algorithm stops if the relative error is
#' less than \emph{reltol} and the absolute error is less than \emph{abstol}.}
#'   \item{stopcond}{A character string. \emph{stopcond} gives the criterion
#' for the stop condition of the algorithm. Either llf or parameter is selected.}
#'   \item{printflag}{A logical. If TRUE, the intermediate parameters are printed.}
#'   \item{printsteps}{An integer for print.}
#' }
#'
#' @param time A numeric vector for time intervals.
#' @param fault An integer vector for the number of faults detected in time intervals.
#' The fault detected just at the end of time interal is not counted.
#' @param type Either 0 or 1. If 1, a fault is detected just at the end of corresponding time interval.
#' This is used to represent the fault time data. If 0, no fault is detected at the end of interval.
#' @param te A numeric value for the time interval from the last fault to the observation time.
#' @param srm.names A character vector, indicating the model (\code{\link{srm.models}}).
#' @param control A list of control parameters. See Details.
#' @param ... Other parameters.
#' @return A list with components;
#' \item{initial}{A vector for initial parameters.}
#' \item{srm}{A class of NHPP. The SRM with the estiamted parameters.}
#' \item{llf}{A numeric value for the maximum log-likelihood function.}
#' \item{df}{An integer for degrees of freedom.}
#' \item{convergence}{A boolean meaning the alorigthm is converged or not.}
#' \item{iter}{An integer for the number of iterations.}
#' \item{aerror}{A numeric value for absolute error.}
#' \item{rerror}{A numeric value for relative error.}
#' \item{ctime}{A numeric value for computation time.}
#' \item{call}{The method call.}
#' @export

fit.srm.nhpp <- function(time, fault, type, te, srm.names = srm.models, control = list(), ...) {
  data <- faultdata(time, fault, type, te)
  con <- srm.nhpp.options()
  nmsC <- names(con)
  con[(namc <- names(control))] <- control
  if (length(noNms <- namc[!namc %in% nmsC]))
  warning("unknown names in control: ", paste(noNms, collapse = ", "))

  if (length(srm.names) == 1) {
    m <- srm(srm.names)
    .fit.srm.nhpp(srm=m, data=data, con=con, ...)
  } else {
    lapply(srm(srm.names), function(m) .fit.srm.nhpp(srm=m, data=data, con=con, ...))
  }
}

.fit.srm.nhpp <- function(srm, data, con, ...) {
  pnames <- names(srm$params)
  tres <- system.time(result <- emfit(srm, data, initialize = TRUE,
    maxiter = con$maxiter, reltol = con$reltol, abstol = con$abstol,
    stopcond = con$stopcond, printflag=con$printflag, printsteps=con$printsteps))
  result <- c(result, list(ctime=tres[1], call=call))
  names(result$srm$params) <- pnames
  class(result) <- "srm.nhpp.result"
  result
}

#' Options for fit.srm.nhpp
#'
#' Generate a list of option values.
#'
#' @return A list of options.
#' @export

srm.nhpp.options <- function() {
  list(maxiter = 10000,
    reltol = sqrt(.Machine$double.eps),
    abstol = 1.0e+200,
    stopcond = "llf",
    printflag = FALSE,
    printsteps = 50)
}

#' Print a fit result of fit.srm.nhpp (S3 method)
#'
#' Print the fitting result.
#'
#' @param x An object of srm.logit.result.
#' @param ... Other parameters
#' @param digits The minimum number of significant digits.
#' @export

print.srm.nhpp.result <- function(x, digits = max(3, getOption("digits") - 3), ...) {
  if (!is.null(x$srm)) {
    print(x$srm, digits=digits, ...)
  }
  if (!is.null(x$llf))
  cat("Maximum LLF:", x$llf, "\n")
  if (!is.null(x$df))
  cat("AIC:", -2*x$llf+2*x$df, "\n")
  if (!is.null(x$convergence))
  cat("Convergence:", x$convergence, "\n\n")
  invisible(x)
}