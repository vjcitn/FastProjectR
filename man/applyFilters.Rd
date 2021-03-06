% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Filters.R
\name{applyFilters}
\alias{applyFilters}
\title{Applies filters to the inputted expression data (may remove rows)}
\usage{
applyFilters(data, threshold, filterInput)
}
\arguments{
\item{data}{ExpressionData object}

\item{threshold}{minimum number of samples gene must be detected in to pass}

\item{filterInput}{list of filters to compute}
}
\value{
The updated ExpressionData object
}
\description{
Applies filters to the inputted expression data (may remove rows)
}
