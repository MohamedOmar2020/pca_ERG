
rm(list = ls())

#setwd("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome")

library(caret)
library(readr)
library(pROC)
library(mltools)
library(precrec)
library(patchwork)
library(tidyverse)

#########################
## ERG performance in the training data
summary_ERG_train_tcga <- read_csv("./results/eval/EVAL_pca_ERG_512_TCGA_MBbig_B16CE_size512_mag10x_trTCGA_evTCGA_train/summary.csv")
mean(summary_ERG_train_tcga$test_auc)
sd(summary_ERG_train_tcga$test_auc)

mean(summary_ERG_train_tcga$test_acc)
sd(summary_ERG_train_tcga$test_acc)

####
## ERG performance in the testing data (TCGA)
summary_ERG_test_tcga <- read_csv("./results/eval/EVAL_pca_ERG_512_TCGA_MBbig_B16CE_size512_mag10x_trTCGA_evTCGA_test/summary.csv")
mean(summary_ERG_test_tcga$test_auc)
mean(summary_ERG_test_tcga$test_acc)

####
## ERG performance in the testing data (nat. hist)
summary_ERG_test_natHist <- read_csv("./results/eval/EVAL_pca_ERG_512_TCGA_MBbig_B16CE_mag10x_s1_evnatHist2/summary.csv")
mean(summary_ERG_test_natHist$test_auc)
mean(summary_ERG_test_natHist$test_acc)

#########################################################################################
## load the metrics of each fold: train tcga
temp_ERG_train_tcga = list.files(path = "./results/eval/EVAL_pca_ERG_512_TCGA_MBbig_B16CE_size512_mag10x_trTCGA_evTCGA_train/", pattern="*.csv", full.names = T)
temp_ERG_train_tcga = temp_ERG_train_tcga[-grep('summary.csv', temp_ERG_train_tcga)]

folds_ERG_train_tcga = lapply(temp_ERG_train_tcga, read.delim, sep = ',')
names(folds_ERG_train_tcga) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

# get the scores
scores_ERG_train_tcga <- lapply(folds_ERG_train_tcga, function(x){
  score <- x[,'p_1']
})

# get the labels
labels_ERG_train_tcga <- lapply(folds_ERG_train_tcga, function(x){
  label <- x[,'Y']
})

# join scores
scores_ERG_train_tcga <- join_scores(scores_ERG_train_tcga, chklen = F)

# join labels
labels_ERG_train_tcga <- join_labels(labels_ERG_train_tcga, chklen = F)

# combine together
data_ERG_train_tcga <- mmdata(scores_ERG_train_tcga, labels_ERG_train_tcga, modnames = names(folds_ERG_train_tcga), dsids = 1:10)

# plot the curves
ERG_curves_train_tcga <- evalmod(data_ERG_train_tcga)

ERG_train_tcga_plot <- autoplot(ERG_curves_train_tcga, 'roc', show_legend = T) + labs(title = "Predicting ERG fusion: performance in the training data") + theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5))

#############
# save the ROC plot: training all folds
tiff('./figures/training_ROC.tiff', width = 3000, height = 3000, res = 400)
ERG_train_tcga_plot
dev.off()

#######
# get the confusion matrix
perf_ERG_train_tcga <- lapply(folds_ERG_train_tcga, function(x){
  label <- x[,'Y']
  
  ####
  # change threshold 
  #pred <- as.numeric(x$p_1 > 0.5)
  #pred <- factor(pred, levels = c(0,1))
  
  ####
  pred <- x[,'Y_hat']
  
  # get the confusion matrix
  CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
  Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  Perf
})

perf_ERG_train_tcga <- do.call('rbind', perf_ERG_train_tcga)
rownames(perf_ERG_train_tcga) <- names(labels_ERG_train_tcga)

# get the average
for (i in colnames(perf_ERG_train_tcga)){
  print(paste('average', i, mean(perf_ERG_train_tcga[, i])))
}

##################
# best threshold
thresholds_erg_train_tcga <- lapply(folds_ERG_train_tcga, function(x){
  # label
  label <- x[,'Y']
  # prob
  prob <- x[,'p_1']
  # coords
  coords <- coords(roc(label, prob, levels = c(0, 1), direction = "<" ), "local maximas")
  # best threshold
  #best_thr <- coords(roc(label, prob, levels = c(0, 1), direction = "<" ), "best")['threshold']$threshold
  #cbind(coords, best_thr)
  coords
})

thresholds_erg_train_tcga_df <- do.call(rbind, thresholds_erg_train_tcga)
thresholds_erg_train_tcga_df$fold <- gsub('\\..*', '', rownames(thresholds_erg_train_tcga_df))

# get the best threshold
thresholds_erg_train_tcga_df <- thresholds_erg_train_tcga_df %>%
  group_by(fold) %>%
  mutate(best_thr = case_when(sensitivity >= 0.75 & specificity >=0.50 ~ threshold)) %>%
  dplyr::filter(sensitivity >= 0.75) %>%
  dplyr::filter(specificity == max(specificity))


best_thr_train_tcga_df <- thresholds_erg_train_tcga_df[!duplicated(thresholds_erg_train_tcga_df$fold), c('fold', 'best_thr')] 
best_thr_train_tcga_df <- as.list(as.matrix(best_thr_train_tcga_df[,'best_thr']))
names(best_thr_train_tcga_df) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

#########################################################################################
## load the metrics of each fold: test tcga
temp_ERG_test_tcga = list.files(path = "./results/eval/EVAL_pca_ERG_512_TCGA_MBbig_B16CE_size512_mag10x_trTCGA_evTCGA_test/", pattern="*.csv", full.names = T)
temp_ERG_test_tcga = temp_ERG_test_tcga[-grep('summary.csv', temp_ERG_test_tcga)]

folds_ERG_test_tcga = lapply(temp_ERG_test_tcga, read.delim, sep = ',')
names(folds_ERG_test_tcga) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

# get the scores
scores_ERG_test_tcga <- lapply(folds_ERG_test_tcga, function(x){
  score <- x[,'p_1']
})

# get the labels
labels_ERG_test_tcga <- lapply(folds_ERG_test_tcga, function(x){
  label <- x[,'Y']
})

# join scores
scores_ERG_test_tcga <- join_scores(scores_ERG_test_tcga, chklen = F)

# join labels
labels_ERG_test_tcga <- join_labels(labels_ERG_test_tcga, chklen = F)

# combine together
data_ERG_test_tcga <- mmdata(scores_ERG_test_tcga, labels_ERG_test_tcga, modnames = names(folds_ERG_test_tcga), dsids = 1:10)

# plot the curves
ERG_curves_test_tcga <- evalmod(data_ERG_test_tcga)

ERG_test_tcga_plot <- autoplot(ERG_curves_test_tcga, 'roc', show_legend = T) + labs(title = "Predicting ERG fusion: performance in the testing data") 

##################################################################
# get the confusion matrix using thresholds from training
#########################################################

# get the scores
scores_ERG_test_tcga <- lapply(folds_ERG_test_tcga, function(x){
  score <- x[,'p_1']
  names(score) <- x[,'slide_id']
  score
})

# get the labels
labels_ERG_test_tcga <- lapply(folds_ERG_test_tcga, function(x){
  label <- x[,'Y']
  label <- factor(label, levels = c(0,1))
  names(label) <- x[,'slide_id']
  label
})

# creating a function to binarize predictions into 0 and 1 based on the best threshold
calc_pred <- function(score, thr) {
  pred <- as.numeric(score > thr)
  pred <- factor(pred, levels = c(0,1))
  names(pred) <- names(score)
  pred
}

pred_test_tcga <- as.data.frame(mapply(calc_pred, scores_ERG_test_tcga, best_thr_train_tcga_df))
pred_test_tcga <- as.list(pred_test_tcga)


# creating a function to calc CM 
calc_cm <- function(labels, predictions) {
  cm <- confusionMatrix(reference = labels, data = as.factor(predictions), positive = '1')
  Perf <- t(data.frame("performance" = c(cm$overall["Accuracy"], cm$byClass["Balanced Accuracy"], cm$byClass["Sensitivity"], cm$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  as.data.frame(Perf)
}

cm_test_tcga <- as.data.frame(mapply(calc_cm, labels_ERG_test_tcga, pred_test_tcga))

# MCC based on best threshold
mcc(actuals = labels_ERG_test_tcga$fold3, preds = as.factor(pred_test_tcga$fold3))

#############
# table of metrics by thresholds:

# get the training thresholds
roc_obj_train <- roc(labels_ERG_train_tcga$fold3, scores_ERG_train_tcga$fold3)
thresholds_train <- roc_obj_train$thresholds

# Initialize an empty data frame to store the results
result_df_tcga_test <- data.frame(
  Threshold = double(),
  Sensitivity = double(),
  Specificity = double(),
  MCC = double(),
  PPV = double(),
  NPV = double()
)

for (thr in thresholds_train) {
  # Binarize the predictions using the threshold
  pred_bin <- as.numeric(scores_ERG_test_tcga$fold3 > thr)
  
  # Compute the confusion matrix
  cm <- table(Truth = labels_ERG_test_tcga$fold3, Prediction = pred_bin)
  
  # Check the dimensions of cm and handle cases where one of the classes is missing
  if (all(dimnames(cm)$Truth == c("0", "1")) && all(dimnames(cm)$Prediction == c("0", "1"))) {
    tp <- cm[2,2]
    tn <- cm[1,1]
    fp <- cm[1,2]
    fn <- cm[2,1]
  } else {
    if (length(unique(pred_bin)) == 1) {
      if (unique(pred_bin)[1] == 0) {
        tp <- 0
        fp <- 0
        tn <- sum(pred_bin == 0)
        fn <- sum(as.numeric(as.character(labels_ERG_test_tcga$fold3))) - tp
      } else {
        tn <- 0
        fn <- 0
        tp <- sum(pred_bin == 1)
        fp <- length(pred_bin) - tp - tn - fn
      }
    }
  }
  
  # Compute the metrics
  sensitivity <- tp / (tp + fn)
  specificity <- tn / (tn + fp)
  ppv <- tp / (tp + fp)
  npv <- tn / (tn + fn)
  mcc_val <- (tp*tn - fp*fn) / sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn))
  
  # Store the results
  result_df_tcga_test <- rbind(result_df_tcga_test, data.frame(
    Threshold = thr,
    Sensitivity = sensitivity,
    Specificity = specificity,
    MCC = mcc_val,
    PPV = ppv,
    NPV = npv
  ))
}

# Display the result table
result_df_tcga_test

#write_csv(result_df_tcga_test, file = '/Users/mohamedomar/Library/CloudStorage/Box-Box/PCa_ERG_status/Mol_CancerResearch/supplementary_tables/Supplementary_Table1.csv', col_names=TRUE)
library(xlsx)
write.xlsx(result_df_tcga_test, 
           file =  '/Users/mohamedomar/Library/CloudStorage/Box-Box/PCa_ERG_status/Mol_CancerResearch/supplementary_tables/Supplementary_Table1.xlsx', 
           sheetName = 'thresholds_tcga_testing',
           row.names = F
)




#########################################################
# get the confusion matrix based on 0.5 as a threshold
#########################################################
perf_ERG_test_tcga <- lapply(folds_ERG_test_tcga, function(x){
  label <- x[,'Y']

  ####
  # change threshold
  #pred <- as.numeric(x$p_1 > 0.4)
  #pred <- factor(pred, levels = c(0,1))

  ####
  pred <- x[,'Y_hat']

  # get the confusion matrix
  CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
  Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  Perf
})
 
perf_ERG_test_tcga <- do.call('rbind', perf_ERG_test_tcga)
rownames(perf_ERG_test_tcga) <- names(labels_ERG_test_tcga)
 
# MCC based on 0.5 threshold
mcc(actuals = labels_ERG_test_tcga$fold3, preds = as.factor(folds_ERG_test_tcga$fold3$Y_hat))



##########
# plot the ROC curve for TCGA testing (fold3)
ROC_data_tcga_test_fold3 <- evalmod(scores = scores_ERG_test_tcga$fold3, labels = labels_ERG_test_tcga$fold3)

ROC_plot_tcga_test_fold3 <- autoplot(ROC_data_tcga_test_fold3, curvetype = c("ROC"), show_legend = F) + 
  labs(title = "Performance of the Final ERG Model in the TCGA Test Set") + 
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)) + 
  annotate("text", x = .65, y = .25, label = paste("AUC = 0.72"), size = 6, fontface = 2)

tiff('./figures/test_tcga_ROC.tiff', width = 3000, height = 3000, res = 400)
ROC_plot_tcga_test_fold3
dev.off()







#########################################################################################
## load the metrics of each fold: test natHist
temp_ERG_test_natHist = list.files(path = "./results/eval/EVAL_pca_ERG_512_TCGA_MBbig_B16CE_mag10x_s1_evnatHist2/", pattern="*.csv", full.names = T)
temp_ERG_test_natHist = temp_ERG_test_natHist[-grep('summary.csv', temp_ERG_test_natHist)]

folds_ERG_test_natHist = lapply(temp_ERG_test_natHist, read.delim, sep = ',')
names(folds_ERG_test_natHist) <- c('fold0', 'fold1', 'fold2', 'fold3', 'fold4', 'fold5', 'fold6', 'fold7', 'fold8', 'fold9')

# get the scores
scores_ERG_test_natHist <- lapply(folds_ERG_test_natHist, function(x){
  score <- x[,'p_1']
})

# get the labels
labels_ERG_test_natHist <- lapply(folds_ERG_test_natHist, function(x){
  label <- x[,'Y']
})

# join scores
scores_ERG_test_natHist <- join_scores(scores_ERG_test_natHist, chklen = F)

# join labels
labels_ERG_test_natHist <- join_labels(labels_ERG_test_natHist, chklen = F)

# combine together
data_ERG_test_natHist <- mmdata(scores_ERG_test_natHist, labels_ERG_test_natHist, modnames = names(folds_ERG_test_natHist), dsids = 1:10)

# plot the curves
ERG_curves_test_natHist <- evalmod(data_ERG_test_natHist)

ERG_test_natHist_plot <- autoplot(ERG_curves_test_natHist, 'roc', show_legend = T) + labs(title = "Predicting ERG fusion: performance in the testing data") 

###########################################################################
#@ get the confusion matrix using thresholds from training
##################################################################

# get the scores
scores_ERG_test_natHist <- lapply(folds_ERG_test_natHist, function(x){
  score <- x[,'p_1']
  names(score) <- x[,'slide_id']
  score
})

# get the labels
labels_ERG_test_natHist <- lapply(folds_ERG_test_natHist, function(x){
  label <- x[,'Y']
  label <- factor(label, levels = c(0,1))
  names(label) <- x[,'slide_id']
  label
})

#$$$$$$$$$$$$$$$$
# creating a function to binarize predictions into 0 and 1 based on the best threshold from the training data
#@@@@@@@@@@@@@@@@@@@@@
calc_pred <- function(score, thr) {
  pred <- as.numeric(score > thr)
  pred <- factor(pred, levels = c(0,1))
  names(pred) <- names(score)
  pred
}

pred_test_natHist <- as.data.frame(mapply(calc_pred, scores_ERG_test_natHist, best_thr_train_tcga_df))
pred_test_natHist <- as.list(pred_test_natHist)

#########
# creating a function to calc CM
calc_cm <- function(labels, predictions) {
  cm <- confusionMatrix(reference = labels, data = as.factor(predictions), positive = '1')
  Perf <- t(data.frame("performance" = c(cm$overall["Accuracy"], cm$byClass["Balanced Accuracy"], cm$byClass["Sensitivity"], cm$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  as.data.frame(Perf)
}

cm_test_natHist <- as.data.frame(mapply(calc_cm, labels_ERG_test_natHist, pred_test_natHist))

# creating a function to calc Mathiew's correlation coefficient
calc_mcc <- function(labels, predictions) {
  mcc <- mcc(actuals = labels, preds = as.factor(predictions))
  Perf <- t(data.frame("MCC" = mcc))
  colnames(Perf) <- c("MCC")
  as.data.frame(Perf)
}

mcc_test_natHist <- as.data.frame(mapply(calc_mcc, labels_ERG_test_natHist, pred_test_natHist))

mcc(actuals = labels_ERG_test_natHist$fold3, preds = as.factor(pred_test_natHist$fold3))

#############
# table of metrics by thresholds:

# get the training thresholds
roc_obj_train <- roc(labels_ERG_train_tcga$fold3, scores_ERG_train_tcga$fold3)
thresholds_train <- roc_obj_train$thresholds

# Initialize an empty data frame to store the results
result_df_natHist <- data.frame(
  Threshold = double(),
  Sensitivity = double(),
  Specificity = double(),
  MCC = double(),
  PPV = double(),
  NPV = double()
)

for (thr in thresholds_train) {
  # Binarize the predictions using the threshold
  pred_bin <- as.numeric(scores_ERG_test_natHist$fold3 > thr)
  
  # Compute the confusion matrix
  cm <- table(Truth = labels_ERG_test_natHist$fold3, Prediction = pred_bin)
  
  # Check the dimensions of cm and handle cases where one of the classes is missing
  if (all(dimnames(cm)$Truth == c("0", "1")) && all(dimnames(cm)$Prediction == c("0", "1"))) {
    tp <- cm[2,2]
    tn <- cm[1,1]
    fp <- cm[1,2]
    fn <- cm[2,1]
  } else {
    if (length(unique(pred_bin)) == 1) {
      if (unique(pred_bin)[1] == 0) {
        tp <- 0
        fp <- 0
        tn <- sum(pred_bin == 0)
        fn <- sum(as.numeric(as.character(labels_ERG_test_natHist$fold3))) - tp
      } else {
        tn <- 0
        fn <- 0
        tp <- sum(pred_bin == 1)
        fp <- length(pred_bin) - tp - tn - fn
      }
    }
  }
  
  # Compute the metrics
  sensitivity <- tp / (tp + fn)
  specificity <- tn / (tn + fp)
  ppv <- tp / (tp + fp)
  npv <- tn / (tn + fn)
  mcc_val <- (tp*tn - fp*fn) / sqrt((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn))
  
  # Store the results
  result_df_natHist <- rbind(result_df_natHist, data.frame(
    Threshold = thr,
    Sensitivity = sensitivity,
    Specificity = specificity,
    MCC = mcc_val,
    PPV = ppv,
    NPV = npv
  ))
}

# Display the result table
result_df_natHist



write.xlsx(result_df_natHist, 
           file =  '/Users/mohamedomar/Library/CloudStorage/Box-Box/PCa_ERG_status/Mol_CancerResearch/supplementary_tables/Supplementary_Table1.xlsx', 
           sheetName = 'thresholds_natHist',
           row.names = F, append = T
)
##################################################################
# get the confusion matrix based on 0.5 threshold
##################################################################
perf_ERG_test_natHist <- lapply(folds_ERG_test_natHist, function(x){
  label <- x[,'Y']

  ####
  # change threshold
  #pred <- as.numeric(x$p_1 > 0.2)
  #pred <- factor(pred, levels = c(0,1))

  ####
  pred <- x[,'Y_hat']

  # get the confusion matrix
  CM <- confusionMatrix(reference = as.factor(label), data = as.factor(pred), positive = '1')
  Perf <- t(data.frame("performance" = c(CM$overall["Accuracy"], CM$byClass["Balanced Accuracy"], CM$byClass["Sensitivity"], CM$byClass["Specificity"])))
  colnames(Perf) <- c("Accuracy", "Bal.Accuracy", "Sensitivity", "Specificity")
  Perf
})

perf_ERG_test_natHist <- do.call('rbind', perf_ERG_test_natHist)
rownames(perf_ERG_test_natHist) <- names(labels_ERG_test_natHist)

# get the average
for (i in colnames(perf_ERG_test_natHist)){
  print(paste('average', i, mean(perf_ERG_test_natHist[, i])))
}

# CM based on 0.5 threshold
confusionMatrix(reference = as.factor(folds_ERG_test_natHist$fold3$Y), data = as.factor(folds_ERG_test_natHist$fold3$Y_hat), positive = '1')

# MCC based on 0.5 threshold
mcc(actuals = labels_ERG_test_natHist$fold3, preds = as.factor(folds_ERG_test_natHist$fold3$Y_hat))









##########
# plot the ROC curve for TCGA testing (fold3)
ROC_data_natHist_test_fold3 <- evalmod(scores = scores_ERG_test_natHist$fold3, labels = labels_ERG_test_natHist$fold3)

ROC_plot_natHist_test_fold3 <- autoplot(ROC_data_natHist_test_fold3, curvetype = c("ROC"), show_legend = F) + 
  labs(title = "Performance of the Final ERG Model in the Natural History Cohort") + 
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)) + 
  annotate("text", x = .65, y = .25, label = paste("AUC = 0.73"), size = 6, fontface = 2)

tiff('./figures/test_natHist_ROC.tiff', width = 3000, height = 3000, res = 400)
ROC_plot_natHist_test_fold3
dev.off()



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







