
rm(list = ls())

setwd("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome")

library(caret)
library(readr)
library(pROC)
library(mltools)
library(precrec)
library(patchwork)

#########################
## ERG performance on the testing data
summary_ERG <- read_csv("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_ERG_512_NatHist_MBsmall_B32SVM_lvl0new_s1/summary.csv")
mean(summary_ERG$test_auc)
mean(summary_ERG$test_acc)

#########################
## PTEN performance on the testing data
summary_pten <- read_csv("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_pten_512_NatHist_mbSmall_B32CE_lvl0new_s1/summary.csv")
mean(summary_pten$test_auc)
mean(summary_pten$test_acc)

#########################
## ETV1 performance on the testing data
summary_ETV1 <- read_csv("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_ETV1_256_s1/summary.csv")
mean(summary_ETV1$test_auc)
mean(summary_ETV1$test_acc)

#########################
## ETV4 performance on the testing data
summary_ETV4 <- read_csv("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_ETV4_256_s1/summary.csv")
mean(summary_ETV4$test_auc)
mean(summary_ETV4$test_acc)


#########################
## SPOP performance on the testing data
summary_SPOP <- read_csv("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_SPOP_256_s1/summary.csv")
mean(summary_SPOP$test_auc)
mean(summary_SPOP$test_acc)

#########################################################################################
## load the metrics of each testing fold: ERG
temp_ERG = list.files(path = "/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_ERG_512_NatHist_MBsmall_B32SVM_lvl0new_s1/", pattern="*.csv", full.names = T)
temp_ERG = temp_ERG[-grep('summary.csv', temp_ERG)]

folds_ERG = lapply(temp_ERG, read.delim, sep = ',')
names(folds_ERG) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

# get the scores
scores_ERG <- lapply(folds_ERG, function(x){
  score <- x[,'p_1']
})

# get the labels
labels_ERG <- lapply(folds_ERG, function(x){
  label <- x[,'Y']
})

# join scores
scores_ERG <- join_scores(scores_ERG, chklen = F)

# join labels
labels_ERG <- join_labels(labels_ERG, chklen = F)

# combine together
data_ERG <- mmdata(scores_ERG, labels_ERG, modnames = names(folds_ERG), dsids = 1:10)

# plot the curves
ERG_curves <- evalmod(data_ERG)

ERG <- autoplot(ERG_curves, 'roc', show_legend = F) + labs(title = "ERG fusion") 

# get the confusion matrix
perf_ERG <- lapply(folds_ERG, function(x){
  label <- x[,'Y']
  
  ####
  # change threshold 
  pred <- as.numeric(x$p_1 > 0.4)
  pred <- factor(pred, levels = c(0,1))
  
  ####
  #pred <- x[,'Y_hat']
  
  # get the confusion matrix
  CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
  Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  Perf
})

perf_ERG <- do.call('rbind', perf_ERG)
rownames(perf_ERG) <- names(labels_ERG)

# get the average
for (i in colnames(perf_ERG)){
  print(paste('average', i, mean(perf_ERG[, i])))
}

#######################################################################################
## load the metrics of each testing fold: PTEN
temp_pten = list.files(path = "/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_pten_128_s1/", pattern="*.csv", full.names = T)
temp_pten = temp_pten[-grep('summary.csv', temp_pten)]

folds_pten = lapply(temp_pten, read.delim, sep = ',')
names(folds_pten) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

# get the scores
scores_pten <- lapply(folds_pten, function(x){
  score <- x[,'p_1']
})

# get the labels
labels_pten <- lapply(folds_pten, function(x){
  score <- x[,'Y']
})

# join scores
scores_pten <- join_scores(scores_pten, chklen = F)

# join labels
labels_pten <- join_labels(labels_pten, chklen = F)

# combine together
data_pten <- mmdata(scores_pten, labels_pten, modnames = names(folds_pten), dsids = 1:10)

# plot the curves
pten_curves <- evalmod(data_pten)

pten <- autoplot(pten_curves, 'roc', show_legend = F) + labs(title = "PTEN loss") 


# get the confusion matrix
perf_pten <- lapply(folds_pten, function(x){
  label <- x[,'Y']
  
  ####
  # change threshold 
  pred <- as.numeric(x$p_1 > 0.6)
  pred <- factor(pred, levels = c(0,1))
  
  ####
  #pred <- x[,'Y_hat']
  
  CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
  Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  Perf
})

perf_pten <- do.call('rbind', perf_pten)
rownames(perf_pten) <- names(labels_pten)

# get the average
for (i in colnames(perf_pten)){
  print(paste('average', i, mean(perf_pten[, i])))
}

################################################
## load the metrics of each testing fold: ETV1
temp_ETV1 = list.files(path = "/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_ETV1_256_s1/", pattern="*.csv", full.names = T)
temp_ETV1 = temp_ETV1[-grep('summary.csv', temp_ETV1)]

folds_ETV1 = lapply(temp_ETV1, read.delim, sep = ',')
names(folds_ETV1) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

# get the scores
scores_ETV1 <- lapply(folds_ETV1, function(x){
  score <- x[,'p_1']
})

# get the labels
labels_ETV1 <- lapply(folds_ETV1, function(x){
  score <- x[,'Y']
})

# join scores
scores_ETV1 <- join_scores(scores_ETV1, chklen = F)

# join labels
labels_ETV1 <- join_labels(labels_ETV1, chklen = F)

# combine together
data_ETV1 <- mmdata(scores_ETV1, labels_ETV1, modnames = names(folds_ETV1), dsids = 1:10)

# plot the curves
ETV1_curves <- evalmod(data_ETV1)

ETV1 <- autoplot(ETV1_curves, 'roc') + labs(title = "ETV1 fusion") 

# get the confusion matrix
perf_ETV1 <- lapply(folds_ETV1, function(x){
  label <- x[,'Y']
  
  ####
  # change threshold 
  pred <- as.numeric(x$p_1 > 0.08)
  pred <- factor(pred, levels = c(0,1))
  
  ####
  #pred <- x[,'Y_hat']
  
  CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
  Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  Perf
})

perf_ETV1 <- do.call('rbind', perf_ETV1)
rownames(perf_ETV1) <- names(labels_ETV1)

# get the average
for (i in colnames(perf_ETV1)){
  print(paste('average', i, mean(perf_ETV1[, i])))
}

#######################################
## load the metrics of each testing fold: ETV4
temp_ETV4 = list.files(path = "/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_ETV4_256_s1/", pattern="*.csv", full.names = T)
temp_ETV4 = temp_ETV4[-grep('summary.csv', temp_ETV4)]

folds_ETV4 = lapply(temp_ETV4, read.delim, sep = ',')
names(folds_ETV4) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

# get the scores
scores_ETV4 <- lapply(folds_ETV4, function(x){
  score <- x[,'p_1']
})

# get the labels
labels_ETV4 <- lapply(folds_ETV4, function(x){
  score <- x[,'Y']
})

# join scores
scores_ETV4 <- join_scores(scores_ETV4, chklen = F)

# join labels
labels_ETV4 <- join_labels(labels_ETV4, chklen = F)

# combine together
data_ETV4 <- mmdata(scores_ETV4, labels_ETV4, modnames = names(folds_ETV4), dsids = 1:10)

# plot the curves
ETV4_curves <- evalmod(data_ETV4)

ETV4 <- autoplot(ETV4_curves, 'roc') + labs(title = "ETV4 fusion")

# get the confusion matrix
perf_ETV4 <- lapply(folds_ETV4, function(x){
  label <- x[,'Y']
  
  ####
  # change threshold 
  pred <- as.numeric(x$p_1 > 0.1)
  pred <- factor(pred, levels = c(0,1))
  
  ####
  #pred <- x[,'Y_hat']
  
  CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
  Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  Perf
})

perf_ETV4 <- do.call('rbind', perf_ETV4)
rownames(perf_ETV4) <- names(labels_ETV4)

# get the average
for (i in colnames(perf_ETV4)){
  print(paste('average', i, mean(perf_ETV4[, i])))
}

#######################################
## load the metrics of each testing fold: SPOP
# temp_SPOP = list.files(path = "/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/eval_results/EVAL_pca_SPOP_256_s1/", pattern="*.csv", full.names = T)
# temp_SPOP = temp_SPOP[-grep('summary.csv', temp_SPOP)]
# 
# folds_SPOP = lapply(temp_SPOP, read.delim, sep = ',')
# names(folds_SPOP) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')
# 
# # get the scores
# scores_SPOP <- lapply(folds_SPOP, function(x){
#   score <- x[,'p_1']
# })
# 
# # get the labels
# labels_SPOP <- lapply(folds_SPOP, function(x){
#   score <- x[,'Y']
# })
# 
# # join scores
# scores_SPOP <- join_scores(scores_SPOP, chklen = F)
# 
# # join labels
# labels_SPOP <- join_labels(labels_SPOP, chklen = F)
# 
# # combine together
# data_SPOP <- mmdata(scores_SPOP, labels_SPOP, modnames = names(folds_SPOP), dsids = 1:10)
# 
# # plot the curves
# SPOP_curves <- evalmod(data_SPOP)
# 
# SPOP <- autoplot(SPOP_curves, 'roc') + labs(title = "SPOP fusion")
# 
# # get the confusion matrix
# perf_SPOP <- lapply(folds_SPOP, function(x){
#   label <- x[,'Y']
#   
#   ####
#   # change threshold 
#   pred <- as.numeric(x$p_1 > 0.2)
#   pred <- factor(pred, levels = c(0,1))
#   
#   ####
#   #pred <- x[,'Y_hat']
#   
#   CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
#   Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
#   colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
#   Perf
# })
# 
# perf_SPOP <- do.call('rbind', perf_SPOP)
# rownames(perf_SPOP) <- names(labels_SPOP)
# 
# # get the average
# for (i in colnames(perf_SPOP)){
#   print(paste('average', i, mean(perf_SPOP[, i])))
# }

#############################################################
## all in one figure

tiff('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/objs/clam/perf_figures/allROCs.tiff', width = 2000, height = 2000, res = 300)
((ERG / pten + plot_layout(tag_level = "new") & theme(plot.tag = element_text(size = 12))) 
#(ETV1 / ETV4 + plot_layout(tag_level = "new") & theme(plot.tag = element_text(size = 12)))
) +
  #plot_layout(widths = c(0.4, 1)) + 
  plot_annotation(
    title = 'The performance in the testing cohort',
    theme = theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5))
  ) +
  #guides(fill=guide_legend(ncol=2)) +
  plot_layout(guides = "collect") & theme(legend.position='bottom')

dev.off()



pdf('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/objs/clam/perf_figures/allROCs.pdf', width = 20, height = 15)
((ERG / pten + plot_layout(tag_level = "new") & theme(plot.tag = element_text(size = 12)))
    #(ETV1 / ETV4 + plot_layout(tag_level = "new") & theme(plot.tag = element_text(size = 12)))
) +
  #plot_layout(widths = c(0.4, 1)) + 
  plot_annotation(
    title = 'The performance in the testing cohort',
    theme = theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5))
  ) +
  plot_layout(guides = "collect") & theme(legend.position='bottom')

dev.off()





tiff('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/objs/clam/perf_figures/ERG_ROC.tiff', width = 1000, height = 1000, res = 300)
ERG
dev.off()


tiff('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/objs/clam/perf_figures/PTEN_ROC.tiff', width = 1000, height = 1000, res = 300)
pten
dev.off()







