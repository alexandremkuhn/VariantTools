calculateConcordanceMatrix <- function(variantFiles) {  
  if (length(variantFiles) < 2L) {
    stop("There must at least two variant files.")
  }
  if (!all(file.exists(variantFiles))) {
    stop("Some of the files of variants could not be found.")
  }
  
  ## initialize vcmat, pairwise variance concordant score between dirs
  n <- length(variantFiles)
  vcmat <- matrix(NA, nrow=n, ncol=n)
  rownames(vcmat) <- colnames(vcmat) <- variantFiles

  ## compute vcmat
  for (i in 1:(n - 1)) {
    avar <- try({
      get(load(variantFiles[i]))
    }, silent=TRUE)
    if (class(avar) == "try-error") {
      stop("error: cannot load filtered_variants_granges in ",
           variantFiles[i])
    }
  
    for (j in (i+1):n) {
      bvar <- try({
        get(load(variantFiles[j]))
      }, silent=TRUE)
      if (class(bvar) == "try-error") {
        stop("error: cannot load filtered_variants_granges in ",
             variantFiles[j])
      }
    
      ## compute variant concordance
      vc <- try(checkVariantConcordance(avar, bvar))
      if (class(vc) == "try-error") {
        stop("error: variantConcordance() didn't return a value")
      }

      ## output results
      vcmat[i, i] <- 1
      vcmat[j, j] <- 1
      vcmat[i, j] <- vc[1]$fraction
      vcmat[j, i] <- vc[1]$fraction

      if (getOption("verbose"))
        message(paste("variantConcordance:",
                      variantFiles[i],
                      variantFiles[j],
                      vc$fraction, vc$denominator, sep="\t"))
    }
  }
  return(vcmat)  
}

printConcordanceReport <- function(concordanceReport) {
  msg <- paste(names(concordanceReport), concordanceReport, sep="\t")
  cat(paste(msg, collapse="\n"))
}

calculateConcordanceReport <- function(concordanceMatrix,
                                       threshold) {
  concordantCliques <- .getConcordantCliques(concordanceMatrix,
                                             threshold)
  ## test if connected components are cliques of
  ##at least 2 vertices

  n <- sum(elementLengths(concordantCliques))
  vstate <- rep("non-concordant", n)
  names(vstate) <- unlist(concordantCliques)

  ##if there are multiple cliques of size 2 or greater, the entire set
  ##is undecidable
  numMultinodeCliques <- sum(elementLengths(concordantCliques) >= 2)
  if (numMultinodeCliques >= 2L) {
    vstate <- rep("undecidable", n)
  } else if (numMultinodeCliques == 1L) {
    ##if in the clique with at least two elements, is concordant
    multinodeCliqueElements <-
      concordantCliques[[which(elementLengths(concordantCliques) >= 2)]]
    vstate[multinodeCliqueElements] <- "concordant"
  }
  return(vstate)
}

idVerify <- function(variantFiles, threshold)
{
  concordanceMatrix <- calculateConcordanceMatrix(variantFiles)
  concordanceReport <- calculateConcordanceReport(concordanceMatrix,
                                                  threshold)
  printConcordanceReport(concordanceReport)
}

##################
##HELPER FUNCTIONS
##################

.getConcordantCliques <- function(concordanceMatrix, threshold) {
  adj <- concordanceMatrix > threshold
  if (is.null(colnames(adj)))
    colnames(adj) <- paste0("id", seq_len(ncol(adj)))
  V <- colnames(adj)
  edL <- vector("list", length=length(V))
  names(edL) <- V
  for (i in seq_along(V)) {
    indicesOfConnectedNodes <- which(adj[, i] == TRUE)
    edL[[i]] <- list(edges=indicesOfConnectedNodes)
  }
  gR <- graphNEL(nodes=V, edgeL=edL)
  connectedComp(gR)
}