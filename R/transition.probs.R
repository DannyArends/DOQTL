################################################################################
# Create initial transition matrices for each SNP.  These are based on code by
# Karl Broman that uses the distance between each SNP, the DO generation and
# the pre-CC progenitors used to create the DO.
# There are 9 unique transition cases in the DO on autosomes and the femaleX.
# There are 2 on the male X. We calculate the probability of seeing a 
# recombination between each SNP for each type of transition and then place 
# the probabilities in the correct cells of the SNP-specific transition matrix.
# WARNING: THIS FUNCTION IS COMPLETELY DO SPECIFIC BECAUSE IT USES THE DO 
#          PROGENITORS AND DO GENERATION!
# Arguments: states: a list of states that are two letter combinations of the
#                    founders.
#            snps: matrix with 4 columns and num.snps rows. column 1: SNPID,
#                     column 2: chr, column 3: base location, column 4: cM
#                     location.  These should only be the SNPs on the current
#                     chromosome.
#            do.gen: The DO outbreeding generation for each sample.
#            chr: one of "auto", "femaleX", "maleX", for each type of chr.
# Returns: list of transition probabilitry arrays, one for each DO generation
#          in the data set. Each list element is an array of transition
#          probabilties for each HMM state and each SNP on the current Chr.
#          Array dimensions: num.states x num.states x num.SNPs.
#          Probabilities are returned on a log scale. 
do.trans.probs = function(states, snps, chr = c(1:19, "X"), 
                 sex = c("M", "F"), do.gen) {

  chr = match.arg(chr)
  sex = match.arg(sex)

  # The original pre-CC lines used to create the DO (from K. Svenson).
  # The names are the CC generation number and the values are the number
  # of mice from that generation.
  alpha = c(21, 64, 24, 10, 5, 9, 5, 3, 3)
  alpha = alpha / sum(alpha)
  names(alpha) = c(4, 5, 6, 7, 8, 9, 10, 11, 12)

  # Get the unique DO generations.
  unique.gen = sort(unique(do.gen))
  unique.gen = unique.gen[!is.na(unique.gen)]

  # Create the return value list.
  retval = as.list(1:length(unique.gen))
  names(retval) = unique.gen

  # Create an empty list of transition probabilities.
  trans.prob = as.list(unique.gen)
  names(trans.prob) = unique.gen

  # This holds the cas ID of each type of transition probability.
  cases = matrix(0, length(states), length(states), dimnames = list(states,
                 states))

  # Females
  if(sex == "F") {
      cases = assign.autosome.femaleX.cases(states)

      for(i in 1:length(unique.gen)) {
        # Create an array of num.states x num.states x num.snps.  Each row is the
        # probability that the state in row i will transition to the state in 
        # column j.
        retval[[i]] = array(0, dim = c(length(states), length(states),
                       nrow(snps) - 1), dimnames = list(states, states,
                       snps[-nrow(snps),1]))
      } #for(i)

  } else {
    # Males
    # Autosomes
    if(chr %in% 1:19) {
      cases = assign.autosome.femaleX.cases(states)

      for(i in 1:length(unique.gen)) {
        # Create an array of num.states x num.states x num.snps.  Each row is the
        # probability that the state in row i will transition to the state in 
        # column j.
        retval[[i]] = array(0, dim = c(length(states), length(states),
                       nrow(snps) - 1), dimnames = list(states, states,
                       snps[-nrow(snps),1]))
      } #for(i)
    } else {

      # Male X chromosome.
      founders = sort(unique(unlist(strsplit(states, split = ""))))
      # There are only two possible changes since the male X Chr is hemizygous.
      cases = matrix(2, length(founders), length(founders))
      diag(cases) = 1

      # Create a transition probability array for each DO generation.
      for(i in 1:length(unique.gen)) {
        # Create an array of num.states x num.states x num.snps.  Each row is the
        # probability that the state in row i will transition to the state in 
        # column j.
        retval[[i]] = array(0, dim = c(length(founders), length(founders),
                      nrow(snps) - 1), dimnames = list(founders, founders,
                      snps[-1,1]))
      } #for(i)
    } # else
  } # else

  # Get the transition probabilities and place them in the correct locations.
  for(i in 1:length(unique.gen)) {
    r = diff(snps[,4]) * 1e-8
    r[r == 0] = 1e-8  # We can't have zero values here, so set them very small.
    trans.prob = get.trans.probs(r = r, do.gen = unique.gen[i], alpha, chr, sex)

    for(s in 1:(nrow(snps) - 1)) {
      retval[[i]][,,s] = trans.prob[s,cases]
    } # for(s)

    retval[[i]] = log(retval[[i]])

    # This takes care of probabilities that were = 0.
    retval[[i]][is.infinite(retval[[i]])] = -.Machine$double.xmax

  } #for(i)

  return(retval)

} # do.trans.probs()



# From Broman, KW, the Genomes of Recombinant Inbred Lines, Genetics, 
# Feb 2005, 169, 1133-1146.
cc.trans.probs = function(states, snps, chr = c(1:19, "X"), sex = c("M", "F")) {

  chr = match.arg(chr)
  sex = match.arg(sex)

  retval = NULL

  # Autosomes.
  if(chr %in% 1:19) {
    curr.snps = which(snps[,2] == chr)
    retval = array(0, c(length(states), length(states), length(curr.snps) - 1), dimnames = 
             list(states, states, snps[curr.snps[-1], 1]))
    r = diff(snps[curr.snps, 4])
    r[r == 0] = 1e-8  # We can't have zero values here, so set them very small.
    for(s in 1:(length(curr.snps)-1)) {
      retval[,,s] = (7 * r[s]) / (1 + 6 * r[s])
      diag(retval[,,s]) = 1.0 - retval[1,1,s]
    } # for(s)
  } else if(chr == "X") {

    curr.snps = which(snps[,2] == chr)
    retval = array(0, c(length(states), length(states), length(curr.snps) - 1), dimnames = 
             list(states, states, snps[curr.snps[-1], 1]))
    r = diff(snps[curr.snps, 4])
    r[r == 0] = 1e-8  # We can't have zero values here, so set them very small.
    for(s in 1:length(curr.snps)) {
      retval[,,s] = (14.0 / 3.0 * r[s]) / (1 + 4 * r[s])
      diag(retval[,,s]) = 1.0 - retval[1,1,s]
    } # for(s)

  } else {
    stop(paste("Bad chr", chr, "in cc.trans.probs()."))
  } # else

  return(retval)

} # cc.trans.probs()



# This function will requre more tuning. The sex chromosomes will need to be added too.
generic.trans.probs = function(states, snps, chr = c(1:19, "X"), sex = c("M", "F")) {

  tprob = matrix(0.01, length(states), length(states), dimnames = list(states, states))
  diag(tprob) = 1.0
  tprob = tprob / matrix(rowSums(tprob), nrow(tprob), ncol(tprob), byrow = T)
  return(tprob)

} # generic()


################################################################################
# Transition probabilities for DO.
# Daniel Gatti
# Dan.Gatti@jax.org
# October 12, 2011
# Original transition probability code written by Karl Broman.
################################################################################

################################################################################
# Transition probability for DO.
# We calculate 9 unique cases for autosomes and females and 2 unique cases for
# males.
#
# r: double vector of recombination fractions between SNPs.
# do.gen: integer, generation of DO.
# alpha: double vector, proportion of preCC progenitors at generation k.
#         Generation numbers in the names.
# chr: character, one of 1:19, X
# sex: character, either M or F.
#
# This calculates Pr(right | left)
#
# Returns: double matrix with length(r) rows and 9 columns.  Each column 
#          represents a different transition case, which is indicated in the
#          column names.
################################################################################
get.trans.probs = function(r, do.gen, alpha, chr = c(1:19, "X"), 
                           sex = c("M", "F")) {

  chr = match.arg(chr)
  sex = match.arg(sex)

  trans.prob = NULL

  # Autosomes.
  if(chr %in% c(1:19)) {
    # Probability of recombinant haplotype.
    recprob = rep(0.0, length(r))
    recprob = .C("DO_autosome_recomb_freq",
                 as.double(r),
                 as.integer(do.gen),
                 as.integer(length(alpha)),
                 as.integer(as.numeric(names(alpha))),
                 as.double(alpha),
                 as.integer(length(r)),
                 recprob = as.double(recprob))$recprob

     trans.prob = autosome.femaleX.trans.probs(recprob)
  } else {
    # X Chromosome
    if(sex == "M") {
      # Male X
      # Probability of recombinant haplotype.
      recprob = rep(0.0, length(r))
      recprob = .C("DO_maleX_recomb_freq",
                   as.double(r),
                   as.integer(do.gen),
                   as.integer(length(alpha)),
                   as.integer(as.numeric(names(alpha))),
                   as.double(alpha),
                   as.integer(length(r)),
                   recprob = as.double(recprob))$recprob
  
       trans.prob = maleX.trans.probs(recprob)
    } else {
      # Female X
      # Probability of recombinant haplotype.
      recprob = rep(0.0, length(r))
      recprob = .C("DO_femaleX_recomb_freq",
                   as.double(r),
                   as.integer(do.gen),
                   as.integer(length(alpha)),
                   as.integer(as.numeric(names(alpha))),
                   as.double(alpha),
                   as.integer(length(r)),
                   recprob = as.double(recprob))$recprob

      trans.prob = autosome.femaleX.trans.probs(recprob)
    } # else
  } # else

  return(trans.prob)

} # get.trans.probs() 


################################################################################
# Given a vector of recombination fractions between SNPs, return the transition
# probabilities for the 9 possible transtions on autosomes and the female X chr.
# Arguments:
# recprob: numeric vector of recombination probabilities from the family of 
# DO_XXX_recomb_freq functions in transition.c.
# Returns:
# trans.prob: matrix of transition probabilites for the 9 cases with SNPs in 
#             rows and cases in columns.  Columns are named by the type of 
#             transition.
autosome.femaleX.trans.probs = function(recprob) {

  trans.prob = matrix(0, length(recprob), 9)
  colnames(trans.prob) = c("AA_AA", "AA_BB", "AA_AB", "AA_BC", "AB_AA",
                           "AB_CC", "AB_AB", "AB_AC", "AB_CD")

  # AA -> AA 
  trans.prob[,1] = (1.0 - recprob) * (1.0 - recprob)

  # AA -> BB
  trans.prob[,2] = recprob * recprob / 49.0

  # AA -> AB
  trans.prob[,3] = 2.0 * recprob * (1.0 - recprob) / 7.0

  # AA -> BC
  trans.prob[,4] = recprob * recprob * 2.0 / 49.0

  # AB -> AA 
  trans.prob[,5] = recprob * (1.0 - recprob) / 7.0 

  # AB -> CC 
  trans.prob[,6] = recprob * recprob / 49.0

  # AB -> AB 
  trans.prob[,7] = recprob * recprob / 49.0 + (1.0 - recprob) * (1.0 - recprob)

  # AB -> AC 
  trans.prob[,8] = recprob * (1.0 - recprob) / 7.0 + recprob * recprob / 49.0
		  
  # AB -> CD 
  trans.prob[,9] = recprob * recprob * 2.0 / 49.0

  return(trans.prob)
} # autosome.femaleX.trans.probs()


################################################################################
# Transition probability for DO, autosome
# We calculate 9 unique cases and return them.
#
# r = double vector of recombination fractions between SNPs.
# do.gen = integer, generation of DO.
# alpha = double vector, proportion of preCC progenitors at generation k.
#         Generation numbers in the names.
#
# This calculates Pr(right | left)
#
# Returns: double matrix with length(r) rows and 9 columns.  Each column 
#          represents a different transition case, which is indicated in the
#          column names.
################################################################################
maleX.trans.probs = function(recprob) {

  trans.prob = matrix(0, length(recprob), 2)
  colnames(trans.prob) = c("A_A", "A_B")

  # A -> A
  trans.prob[,1] = 1.0 - recprob
  # A -> B
  trans.prob[,2] = recprob / 7.0

  return(trans.prob)

} # maleX_trans_probs()

