variantKeys <- function(x) paste0(x$location, x$alt)

matchVariants <- function(x, table) {
  .Deprecated("match,VRanges,VRanges")
  if (is.null(x$alt))
    stop("matchVariants requires an 'alt' metacolumn")
  hits <- findOverlaps(x, table)
  same.alt <- x$alt[queryHits(hits)] == table$alt[subjectHits(hits)]
  ans <- rep(NA, length(x))
  ans[queryHits(hits)[same.alt]] <- subjectHits(hits)[same.alt]
  ans
}

mergeVariantInfo <- function(x, info) {
  m <- matchVariants(x, info)
  info.cols <- setdiff(colnames(mcols(info)), colnames(mcols(x)))
  mcols(x)[info.cols] <- lapply(mcols(info)[info.cols], `[`, m)
  x
}

setGeneric("%variant_in%", function(x, table) standardGeneric("%variant_in%"))

setMethod("%variant_in%", c("GenomicRanges", "GenomicRanges"),
          function(x, table) {
            .Deprecated("%in%,VRanges,VRanges")
            !is.na(matchVariants(x, table))
          })

variant_setdiff <- function(x, y) {
  x[!x %variant_in% y]
}

## note this is asymmetric in that it keeps the metadata from 'x'
variant_intersect <- function(x, y) {
  x[x %variant_in% y]
}
