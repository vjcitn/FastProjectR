% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AnalysisFunctions.R
\name{analyzeProjections}
\alias{analyzeProjections}
\title{analyze projections}
\usage{
analyzeProjections(object, lean = object@lean, perm_wPCA = object@perm_wPCA,
  BPPARAM = NULL)
}
\arguments{
\item{object}{the FastProject object}

\item{lean}{if TRUE run a lean simulation. Else more robust pipeline
initiated. Default is FALSE}

\item{perm_wPCA}{If TRUE, apply permutation WPCA to calculate significant
number of PCs. Else not. Default FALSE.}

\item{BPPARAM}{the parallelization backend to use}
}
\value{
the FastProject object with values set for the analysis results
}
\description{
This is the main analysis function. For each filtered dataset, a set of
different projection onto low-dimensional space are computed, and the
consistency of the resulting space with the signature scores is computed
to find signals that are captured succesfully by the projections.
}
