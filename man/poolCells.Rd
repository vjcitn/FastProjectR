% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AnalysisFunctions.R
\name{poolCells}
\alias{poolCells}
\title{create micro-clusters that reduce noise and complexity while maintaining
the overall signal in the data}
\usage{
poolCells(object, cellsPerPartition = object@cellsPerPartition,
  BPPARAM = SerialParam())
}
\arguments{
\item{object}{the FastProject object for which to cluster the cells}

\item{cellsPerPartition}{the minimum number of cells to put into a cluster}

\item{BPPARAM}{the parallelization backend to use}
}
\value{
the FastProject with pooled cells
}
\description{
create micro-clusters that reduce noise and complexity while maintaining
the overall signal in the data
}
