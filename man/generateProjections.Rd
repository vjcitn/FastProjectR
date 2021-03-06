% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Projections.R
\name{generateProjections}
\alias{generateProjections}
\title{Projects data into 2 dimensions using a variety of linear and non-linear methods.}
\usage{
generateProjections(expr, weights, filterName = "", inputProjections = c(),
  lean = FALSE, perm_wPCA = FALSE, BPPARAM = BiocParallel::bpparam())
}
\arguments{
\item{expr}{ExpressionData object}

\item{weights}{weights estimated from FNR curve}

\item{filterName}{name of filter, to extract correct data for projections}

\item{inputProjections}{Precomputed projections}

\item{lean}{If TRUE, diminished number of algorithms applied,
if FALSE all algorithms applied. Default is FALSE}

\item{perm_wPCA}{If TRUE, apply permutation wPCA to determine significant
number of components. Default is FALSE.}

\item{BPPARAM}{the backend to use for parallelization}
}
\value{
list:
\itemize{
    \item projections: a list of Projection objects
    \item geneNames: a character vector of the genes involved in the analsis
    \item fullPCA: the full PCA matrix of the data
    \item loadings: the loading vectors for the fullPCA matrix
    \item permMats: a list of permuted and projected data matrices, used for
    downstream permutation tests
}
}
\description{
Projects data into 2 dimensions using a variety of linear and non-linear methods.
}
