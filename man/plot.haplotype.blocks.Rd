\name{plot.haplotype.blocks}
\alias{plot.haplotype.blocks}
\title{Given a genomic region, plot the haplotype blocks for a subset of strains.}
\description{
  This function can be used to examine the haplotype blocks in a QTL interval.  It should be used in cases where the trait is suspected to be dominant or recessive.  It may not be appropriate when the mode of inheritance is less clear.  For a recessive trait, the type argument should be set to homozygous, whereas for a dominant trait, it should be heterozygous.
}
\usage{
  plot.haplotype.blocks(probs, snps, chr, loc, strains, type = c("homozygous",
                        "heterozygous"), ...)
}
\arguments{
  \item{probs}{
    numeric 3D array: the 8 state founder probability array for all SNPs and samples. This is generated by \code{\link{condense.founder.probs}}. Samples in dim 1, 8 founders in dim 2 and SNPs in dim 3.
  }
  \item{snps}{
    data.frame: obtained from data(snps) with number of rows equal to dim[3] of probs.  Verify that the SNP order is the same in snps and probs.
  }
  \item{chr}{
    character: the chromosome to plot.
  }
  \item{loc}{
    numeric: Mb location of maximum QTL.
  }
  \item{strains}{
    character vector: the strains whose haplotypes to plot.  Must be the same names as in founder.cols[,2].
  }
  \item{type}{
    character: one of homozygous or heterozygous. Use homozygous for recessive traits and heterozygous or dominant traits.
  }
  \item{...}{
    Other options to be passed to plot().  Typically this would be xlim and would be used to limit the range to plot around the QTL.
  }
}
\value{
  No returned value.  Creates a plot with the haplotype blocks in the requested interval.
}
\author{
  Daniel Gatti
}
\seealso{
  \code{\link{condense.founder.probs}}
}
\examples{
  \dontrun{plot.haplotype.blocks(probs = probs, snps = snps, chr = 1,
           loc = 50.4, strains = c("CAST/EiJ"), type = "homozygous",
           xlim = c(45, 55))}
}
\keyword{ QTL }
\keyword{ haplotype }
