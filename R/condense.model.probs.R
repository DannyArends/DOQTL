################################################################################
# Given the HMM 36 state genotype probability files, condense them to 8 founder
# states and optionally write out the large 3D array to a *.Rdata file.
# This requires that the genotype.probs.txt files have been converted to 
# genotype.probs.Rdata files.
# Daniel Gatti
# Dan.Gatti@jax.org
# Jan. 31, 2012
# Aug. 4, 2013: Added dominance and full model arrays.
################################################################################
# Arguments: path: character, full path to the directory where the
#                  *.genotype.probs.Rdata files are.
#            write: character, if missing, writes nothing and returns
#                   the large 3D array. Otherwise, the full path to a file to 
#                   write the founder probabilities out to.
#            model: character, one of "additive", "dominance" or "full", 
#                   indicating the type of array to return. 'Additive' condenses
#                   the 36 genotypes down to 8 founder allele dosages. 
#                   'Dominance' condenses them down to 16 values, the first 8
#                   are additive values and the last 8 are dominance values.
#                   'Full' returns all 36 states.
condense.model.probs = function(path = ".", write, model = c("additive",
                       "dominance", "full")) {

  model = match.arg(model)
  path  = add.slash(path)

  # Get the files that we need to process.
  files = dir(path, pattern = ".genotype.probs.Rdata$", full.names = T)
  # Get their sample IDs.
  samples = dir(path, pattern = "genotype.probs.Rdata$", full.names = F)
  samples = sub("\\.genotype\\.probs\\.Rdata$", "", samples)

  model.probs = NULL
  if(model == "additive") {
    model.probs = get.additive(files = files, samples = samples)
  } else if(model == "dominance") {
    model.probs = get.dominance(files = files, samples = samples)
  } else if(model == "full") {
    model.probs = get.full(files = files, samples = samples)
  } else {
    stop(paste("condense.model.probs:Invalid model '", model,"'. Please",
         "enter one of additive, dominance or full in the model argument."))
  } # else

  if(!missing(write)) {
    print("Writing data...")
    save(model.probs, file = write)
  } else {
    return(model.probs)
  } # else

} # condense.model.probs()


# Helper function to get the additive model probabilities, which condenses
# the 36 genotypes into additive allele dosages.
get.additive = function(files, samples) {

  # Create a large 3D array with samples/states/SNPs in dimensions 1,2,3.
  print(files[1])
  load(files[1]) # load in prsmth
  prsmth = t(exp(prsmth))
  founders = sort(unique(unlist(strsplit(rownames(prsmth), split = ""))))
  model.probs = array(0, c(length(files), length(founders), ncol(prsmth)),
                dimnames = list(samples, founders, colnames(prsmth)))

  # Create a matrix that we can use to multiply the 36 state probabilities.
  mat = matrix(0, length(founders), nrow(prsmth), dimnames = list(
               founders, rownames(prsmth)))
  m = sapply(founders, grep, colnames(mat))
  for(i in 1:nrow(mat)) {
    mat[i,m[i,]] = 0.5
  } # for(i)
  mat[matrix(c(1:length(founders), diag(m)), ncol = 2)] = 1

  # Place the founder probabilities in the matrix.
  model.probs[1,,] = mat %*% prsmth
  for(i in 2:length(files)) {
    print(files[i])
    load(files[i]) # load in prsmth
    prsmth = t(exp(prsmth))
    model.probs[i,,] = mat %*% prsmth
  } # for(i)

  return(model.probs)

} # get.additive()


# Helper function to get the additive model probabilities, which condenses
# the 36 genotypes into additive and dominant dosages.
get.dominance = function(files, samples) {

  # Create a large 3D array with samples/states/SNPs in dimensions 1,2,3.
  load(files[1]) # load in prsmth
  prsmth = t(exp(prsmth))
  founders = sort(unique(unlist(strsplit(rownames(prsmth), split = ""))))
  model.probs = array(0, c(length(files), 2 * length(founders), ncol(prsmth)),
                dimnames = list(samples, paste(rep(founders, 2), rep(c("add", "dom"), 
                each = length(founders), sep = ".")), colnames(prsmth)))

  # Create a matrix that we can use to multiply the 36 state probabilities
  # to get additive values.
  addmat = matrix(0, length(founders), nrow(prsmth), dimnames = list(
               founders, rownames(prsmth)))
  m = sapply(founders, grep, colnames(addmat))
  for(i in 1:nrow(addmat)) {
    addmat[i,m[i,]] = 0.5
  } # for(i)
  addmat[matrix(c(1:length(founders), diag(m)), ncol = 2)] = 1

  # Create a matrix that we can use to multiply the 36 state probabilities
  # to get additive values.
  dommat = matrix(0, length(founders), nrow(prsmth), dimnames = list(
               founders, rownames(prsmth)))
  m = sapply(founders, grep, colnames(dommat))
  for(i in 1:nrow(dommat)) {
    dommat[i,m[i,]] = 1.0
  } # for(i)
  dommat[matrix(c(1:length(founders), diag(m)), ncol = 2)] = 1

  # Place the founder probabilities in the matrix.
  model.probs[1,1:length(founders),] = addmat %*% prsmth
  model.probs[1,(length(founders) + 1):dim(model.probs)[[2]],] = dommat %*% prsmth
  for(i in 2:length(files)) {
    print(files[i])
    load(files[i]) # loadin prsmth
    prsmth = t(exp(prsmth))
    model.probs[i,1:length(founders),] = addmat %*% prsmth
    model.probs[i,(length(founders) + 1):dim(model.probs)[[2]],] = dommat %*% prsmth
  } # for(i)

  return(model.probs)

} # get.dominance()


# Helper function to get the full model probabilities, which just gathers
# the 36 states for each samples into one file.
get.full = function(files, samples) {

  # Create a large 3D array with samples/states/SNPs in dimensions 1,2,3.
  load(files[1]) # load in prsmth
  prsmth = t(exp(prsmth))
  founders = sort(unique(unlist(strsplit(rownames(prsmth), split = ""))))
  model.probs = array(0, c(length(files), nrow(prsmth), ncol(prsmth)),
                dimnames = list(samples, rownames(prsmth), colnames(prsmth)))

  # Place the probabilities in the matrix.
  model.probs[1,,] = prsmth
  for(i in 2:length(files)) {
    print(files[i])
    load(files[i]) # loadin prsmth
    prsmth = t(exp(prsmth))
    model.probs[i,,] = prsmth
  } # for(i)

  return(model.probs)

} # get.full()

