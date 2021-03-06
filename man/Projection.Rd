% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods-Projection.R
\name{Projection}
\alias{Projection}
\title{Initialize a Projection object
Should not be called directly, instead use the `new` syntax}
\usage{
Projection(name, pData = NULL, weights = matrix(NA, 1, 1))
}
\arguments{
\item{name}{Name of the projection}

\item{pData}{Coordinates of each sample in the projection
(NUM_SAMPLES x NUM_COMPONENTS)}

\item{weights}{a matrix of weights indicatng distances from each point
to its closest neighbors}
}
\value{
Projection object
}
\description{
Initialize a Projection object
Should not be called directly, instead use the `new` syntax
}
