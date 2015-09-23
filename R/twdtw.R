#' @title Multidimensional Time-Weighted DTW analysis
#' 
#' @description This function performs a multidimensional Time-Weighted DTW 
#' analysis and retrieves one or more possible alignments of a query within 
#' a time series.
#' 
#' @param query A zoo object with the multidimensional time series.
#' @param template A zoo object with the template time series. The index of 
#' the zoo object must be of class \code{\link[base]{Date}}.
#' It must be iguel or be equal or longer than the length of the query and 
#' the same number of dimensions. The index of the zoo object must be of 
#' class \code{\link[base]{Date}}.
#' @param weight A character. ''linear'' for linear weight or ''logistic'' 
#' for logistic weight. Default is NULL that runs the original dtw method.
#' @param dist.method A character. Method to derive the local cost matrix.
#' Default is ''Euclidean'' See \code{\link[proxy]{dist}} in package 
#' \pkg{proxy}
#' @param theta A real. Parameter for linear weight. It is the slope 
#' of the linear TWDTW. For theta equal 1 the time weight is equal to the 
#' number of elapsed days. Default is NULL.
#' @param alpha A real. The steepness of logistic method. Default is NULL.
#' @param beta A real. The midpoint of logistic method. Default is NULL.
#' @param alignments An integer. The maximun number of alignments to 
#' perform. Default is NULL to return all possible alignment. 
#' @param step.matrix see \code{\link[dtw]{stepPattern}} in package \pkg{dtw}
#' @param window.function see parameter window.type in \code{\link[dtw]{dtw}} 
#' @param keep preserve the cost matrix, inputs, and other internal structures. 
#' Default is FALSE
#' @param ... other parameters
#' @docType methods
#' @return object of class \code{\link[dtwSat]{dtwSat}} 
#' @examples
#' names(query.list)
#' alig = twdtw(query.list[["Soybean"]], template, weight = "logistic", alpha = 0.1, beta = 50, alignments=4)
#' alig
#' @export
twdtw =  function(query, template, weight=NULL, dist.method="Euclidean",
                  theta=NULL, alpha=NULL, beta=NULL, alignments=NULL, 
                  step.matrix = symmetric1, window.function = noWindow,
                  keep=FALSE, ...)
{

  if(!is.zoo(query))
    stop("query should be of class zoo.")
  if(!is.zoo(template))
    stop("template should be of class zoo")
  if(ncol(query)!=ncol(template))
    stop("Number of columns in query and in template don't match.")
  if(!is(index(query),"Date"))
    stop("Index in query should be of class Date.")
  if(!is(index(template),"Date"))
    stop("Index in template should be of class Date.")

  .twdtw(query, template, weight, dist.method, theta, alpha, 
         beta, alignments, step.matrix, window.function, keep, ...)
  
}

#' @title Performs multiple Time-Weighted DTW 
#' 
#' @description The function performs the Time-Weighted DTW for a list 
#' of queries
#' 
#' @param query A zoo object with the multidimensional time series.
#' @param template A zoo object with the template time series. The index of 
#' the zoo object must be of class \code{\link[base]{Date}}.
#' It must be iguel or be equal or longer than the length of the query and 
#' the same number of dimensions. The index of the zoo object must be of 
#' class \code{\link[base]{Date}}.
#' @param ... see \code{\link[dtwSat]{dtwSat}}
#' @docType methods
#' @export
#' @examples
#' alig = mtwdtw(query.list, template, weight = "logistic", alpha = 0.1, beta = 50)
#' alig
#' @return data.frame see \code{\link[dtwSat]{dtwSat-class}}
mtwdtw = function(query, template, ...){
  if(!is.list(query))
    stop("Missing a list of zoo objects. The query must be a list zoo objects.")
  query.names = names(query)
  if(is.null(query.names))
    query.names = seq_along(query)
  res = do.call("rbind", lapply(query.names, function(i){
    data.frame(query=i, twdtw(query[[i]], template)@alignments)
  }))
  return(res)
}

.twdtw =  function(query, template, weight=NULL, dist.method="Euclidean",
                  theta=NULL, alpha=NULL, beta=NULL, alignments=NULL, 
                  step.matrix = symmetric1, window.function = noWindow,
                  keep=FALSE, ...)
{

  # Local cost
  delta = proxy::dist(query, template, method=dist.method)
  # Elapsed time
  phi = 0
  if(!is.null(weight)){
    phi = .timeCostMatrix(query, template, dist.method)
    phi = switch(weight, 
                 linear   = .linearweight(phi, theta),
                 logistic = .logisticweight(phi, alpha, beta)
    )
  }
  delta = delta + phi
  
  # Cost matrix
  delta = rbind(0, delta)
  n = nrow(delta)
  m = ncol(delta)
  cm = matrix(NA, nrow=n, ncol=m)
  cm[1,] = 0
  wm = matrix(FALSE, nrow = n, ncol = m)
  wm[window.function(row(wm), col(wm), query.size = n, reference.size = m)] = TRUE
  internals = .Call("computeCM_Call", PACKAGE="dtw", wm, delta, cm, step.matrix)
  internals$stepPattern = step.matrix
  internals$costMatrix = internals$costMatrix[-1,]
  internals$directionMatrix = internals$directionMatrix[-1,]
  internals$stepPattern = step.matrix
  internals$N = n-1
  internals$M = m
  internals$query = query
  internals$template = template
  
  
  # WRITE FUNCTION FOR MINIMUM POINTS 
  
  # Porform alignments 
  d = internals$costMatrix[internals$N,1:internals$M]
  NonNA = which(!is.na(d))
  diffd = diff(d[NonNA])
  endPoints = NonNA[which(diffd[-length(diffd)] < 0 & diffd[-1] >= 0)] + 1
  if(tail(diffd,1) < 0)
    endPoints = c(endPoints,length(d))
  if( length(endPoints) < 1 ){
    alignments = list(quey=numeric(0),from=numeric(0), to=numeric(0), distance=numeric(0), normalizedDistance=numeric(0))
    mapping = list(index1 = numeric(0), index2 = numeric(0))
  }else{
    endPoints = endPoints[order(d[endPoints])]
    if(is.null(alignments))
      alignments = length(endPoints)
    if(length(endPoints) > alignments)
      endPoints = endPoints[1:alignments]
    # Map low cost paths (k-th paths)
    mapping = lapply(endPoints, function(b){
      return(.kthbacktrack(internals, b))
    })
    
    # Get the starting point of each path
    startPoints = unlist(lapply(mapping, function(map){
      return(map$index2[1])
    }))
    
    alignments = list(from  = startPoints,
                      to    = endPoints,
                      distance           = d[endPoints],
                      normalizedDistance = d[endPoints] / length(query),                      
                      stringsAsFactors = FALSE)
  }
  
  if(keep) return(new("dtwSat", call=match.call(), alignments=alignments, mapping=mapping, internals=internals))
  
  return(new("dtwSat", call=match.call(), alignments=alignments, mapping=mapping))
}

.timeCostMatrix = function(query, template, dist.method){ 
  tx = as.numeric(format(index(query), "%j"))
  ty = as.numeric(format(index(template), "%j"))
  phi = proxy::dist(tx, ty, method=dist.method)
  phi[phi>(366/2)] = abs(366 - phi[phi>(366/2)])
  return(phi)
}

.logisticweight = function(x, alpha, beta){
  return( 1 / (1 + exp(1)^(-alpha*(x-beta))) )
}

.linearweight = function(x, theta){
  return( theta * x / 366 )
}




#' @title DTW backtrack
#' 
#' @description This function preforms the backtrack starting from  
#' a given index of the last line in the global cost matrix. 
#' 
#' @param alignment A twdtw or dtw alignment object. 
#' @param jmin An integer. The index of the last line in the 
#' global cost matrix. 
#' @docType methods
.kthbacktrack = function(alignment, jmin=NULL) {
  
  dir = alignment$stepPattern
  npat = attr(dir,"npat")
  
  n = nrow(alignment$costMatrix)
  m = ncol(alignment$costMatrix)
  
  i = n
  j = jmin
  if(is.null(jmin))
    j = alignment$jmin
  
  nullrows = dir[,2]==0 & dir[,3]==0
  tmp = dir[!nullrows,,drop=FALSE]
  
  stepsCache = list()  
  for(k in 1:npat) {
    sbs = tmp[,1]==k  
    spl = tmp[sbs,-1,drop=FALSE]
    nr = nrow(spl)
    stepsCache[[k]] = spl[nr:1,,drop=FALSE]
  }
  
  ii<-c(i)
  jj<-c(j)
  
  repeat {
    if(i==1)
      break	
    s = alignment$directionMatrix[i,j]
    if(is.na(s))
      break
    
    steps = stepsCache[[s]]
    ns = nrow(steps)
    
    for(k in 1:ns) {
      if(i-steps[k,1] > 0) {
        ii = c(i-steps[k,1],ii)
        jj = c(j-steps[k,2],jj)
      }                         
    }
    
    i = ii[1]
    j = jj[1]
  }
  
  internals = list()
  internals$index1 = ii
  internals$index2 = jj
  return(internals)
}






