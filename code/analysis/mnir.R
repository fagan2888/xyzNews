library(tidyverse)
library(textir)
rm(list=ls())

##################################################################################
# Storage
##################################################################################

# ADJUST PARAMS HERE
# select source_one to be the more liberal source i.e. Vox or PBS
# select source_two to be the more conservative i.e. PBS or Fox
source_one <- 'PBS'
source_two <- 'Fox'
ngrams <- 3

# must be in the working directory './project'
FILE_PATH = paste0('./data/R_data/', tolower(source_one), '_', tolower(source_two), '_', ngrams, '_gram_counts.rda')
TABLE_PATH = paste0('./paper/figures/', tolower(source_one), '_', tolower(source_two),'_contributions.tex')

##################################################################################
# Load data
##################################################################################

load(FILE_PATH)

##################################################################################
# Setup, adjust params
##################################################################################

# get the covar variable from 'source' 
covars <- data.frame(conserv = article_source$news_source == source_two)
rownames(covars) <- rownames(article_source)

# create a 1/0 vector of fox or not fox for later use
source_to_num <- function(news_source) {
  if (news_source == source_two) {
    return(1)
  } else {
    return(0)
  }
}
source_dummy <- sapply(article_source$news_source, source_to_num)

##################################################################################
# Fit mnir
##################################################################################

cl <- NULL 
fit <- dmr(cl, covars, article_ngram_counts, gamma=1, nlambda=10)

# explore features

# get notable words
B <- coef(fit)

contribution_left <- B[2,order(B[2,])[1:10]]
contribution_right <- B[2,order(-B[2,])[1:10]]
top_left <- as.data.frame(contribution_left)
top_right <- as.data.frame(contribution_right)

# transform into nice dataframe 
top_left[source_one] <- rownames(top_left)
row.names(top_left) <- 1:10
top_right[source_two] <- rownames(top_right)
row.names(top_right) <- 1:10
giveaway_phrases <- data.frame(top_left[c(2,1)], top_right[c(2,1)])

print(xtable(giveaway_phrases, type='latex'), file = TABLE_PATH)

#############################################################################

# look at fit
par(mfrow=c(1,2))
for (j in vocab[c(4, 53)]) {
  plot(fit[[j]], col=c("red"))
  mtext(j, line = 2)
}

# check sufficient reduction 
Z <- srproj(fit, article_ngram_counts)
par(mfrow=c(1,1))
plot(Z[,1], source_dummy, pch=21, 
     bg=c(2, 4)[article_source$news_source], main="Sufficient Reduction Projections", 
     ylab = "Vox                                                                     Fox", 
     xlab="Article Projection Score", yaxt='n')

# 'polarity' of articles
articles = c(1, 43, 1453, 1555)
rownames(Z)[articles]
Z[articles]

# check significance of SR in linear model 
summary(fwd <- lm(source_dummy ~ Z))
