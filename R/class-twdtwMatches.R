###############################################################
#                                                             #
#   (c) Victor Maus <vwmaus1@gmail.com>                       #
#       Institute for Geoinformatics (IFGI)                   #
#       University of Muenster (WWU), Germany                 #
#                                                             #
#       Earth System Science Center (CCST)                    #
#       National Institute for Space Research (INPE), Brazil  #
#                                                             #
#                                                             #
#   R Package dtwSat - 2015-09-01                             #
#                                                             #
###############################################################


#' @title class "twdtwMatches"
#' @name twdtwMatches-class
#' @name twdtwMatches
#' @author Victor Maus, \email{vwmaus1@@gmail.com}
#'
#' @description Class for Time-Weighted Dynamic Time Warping results.
#' 
#' @param labels a vector with labels of the time series. 
#' @param x an object of class twdtwMatches.
#' @param object an object of class twdtwMatches.
#' @param timeseries a \code{\link[dtwSat]{twdtwTimeSeries}} object.
#' @param patterns a \code{\link[dtwSat]{twdtwTimeSeries}} object.
#' @param alignments an object of class list with the TWDTW results. It 
#' has the same length as \code{timeseries}.
#' 
#' @section Slots :
#' \describe{
#'  \item{\code{timeseries}:}{An object of class \code{\link[dtwSat]{twdtwTimeSeries-class}} with the satellite time series.}
#'  \item{\code{pattern}:}{An object of class \code{\link[dtwSat]{twdtwTimeSeries-class}} with the temporal patterns.}
#'  \item{\code{alignments}:}{A \code{\link[base]{list}} of TWDTW results with the same length as 
#'  the \code{timeseries}. Each element in this list has the following results for each temporal pattern 
#'  in \code{patterns}:
#'       \cr\code{from}: a vector with the starting dates of each match in the format "YYYY-MM-DD",
#'       \cr\code{to}: a vector with the ending dates of each match in the format "YYYY-MM-DD", 
#' 	     \cr\code{distance}: a vector with TWDTW dissimilarity measure, and
#' 	     \cr\code{K}: the number of matches of the pattern.
#'  }
#' 	\item{This list might have additional elements:}{ if \code{keep=TRUE} in the \code{twdtw} call 
#' 	the list is extended to include internal structures used during the TWDTW computation: 
#'       \cr\code{costMatrix}: cumulative cost matrix,
#'       \cr\code{directionMatrix}: directions of steps that would be taken from each element of matrix,
#'       \cr\code{startingMatrix}: the starting points of each element of the matrix,
#'       \cr\code{stepPattern}: \code{\link[dtw]{stepPattern}} used for the 
#'       computation, see package \code{\link[dtw]{dtw}},
#'       \cr\code{N}: the length of the \code{pattern}, 
#'       \cr\code{M}: the length of the time series \code{timeseries}, 
#'       \cr\code{timeWeight}: time weight matrix,
#'       \cr\code{localMatrix}: local cost matrix,
#' 	     \cr\code{matching}: A list whose elements have the matching points for 
#' 	     each match between pattern the time series, such that:
#'          \cr--\code{index1}: a vector with matching points of the pattern, and
#'          \cr--\code{index2}: a vector with matching points of the time series.
#'       }
#' }
#' 
#'  
#' @seealso   
#' \code{\link[dtwSat]{twdtwApply}}, 
#' \code{\link[dtwSat]{twdtwTimeSeries-class}}, and 
#' \code{\link[dtwSat]{twdtwRaster-class}}
#' 
#' @examples 
#' ts = twdtwTimeSeries(timeseries=example_ts.list)
#' patterns = twdtwTimeSeries(timeseries=patterns.list)
#' matches = twdtwApply(x = ts, y = patterns)
#' class(matches)
#' length(matches)
#' matches 
NULL
setOldClass("twdtwTimeSeries")
twdtwMatches = setClass(
  Class = "twdtwMatches",
  slots = c(timeseries="twdtwTimeSeries", 
            patterns = "twdtwTimeSeries", 
            alignments = "list"),
  validity = function(object){
    if(!is(object@alignments, "list")){
      stop("[twdtwMatches: validation] Invalid alignments object, class different from list.")
    }else{}
    if(!is(object@timeseries, "twdtwTimeSeries")){
      stop("[twdtwMatches: validation] Invalid timeseries object, class different from twdtwTimeSeries.")
    }else{}
    if(!is(object@patterns, "twdtwTimeSeries")){
      stop("[twdtwMatches: validation] Invalid patterns object, class different from list of twdtwTimeSeries.")
    }else{}
    return(TRUE)
  }
)

setMethod("initialize",
          signature = "twdtwMatches",
          definition = 
            function(.Object, timeseries, patterns, alignments){
              .Object@timeseries = new("twdtwTimeSeries")
              .Object@patterns = new("twdtwTimeSeries")
              .Object@alignments = list()
              if(!missing(alignments))
                .Object@alignments = alignments
              if(!missing(timeseries))
                .Object@timeseries = timeseries
              if(!missing(patterns))
                .Object@patterns = patterns
              validObject(.Object)
              return(.Object)
            }
)

setGeneric(name = "twdtwMatches", 
          def = function(...) standardGeneric("twdtwMatches")
)

#' @inheritParams twdtwMatches-class
#' @describeIn twdtwMatches Create object of class twdtwMatches.
#'
#' @examples 
#' # Creating objects of class twdtwMatches 
#' ts  = twdtwTimeSeries(example_ts.list)
#' patt = twdtwTimeSeries(patterns.list)
#' mat = twdtwMatches(ts, patterns=patt)
#' mat
#' 
#' @export
setMethod(f = "twdtwMatches", 
          definition = function(..., patterns, alignments){
              timeseries = list(...)
              if(length(timeseries)<1) timeseries = new("twdtwTimeSeries")
              new("twdtwMatches", timeseries = twdtwTimeSeries(timeseries), patterns=patterns, alignments = alignments)
          })

          
          
          