
rm(list = ls())

library(ggplot2)
library(jsonlite)
library(stringr)
library(tibble)
library(dplyr)
library(ggpubr)
library(survminer)
library(survival)
library(tidyverse)

source("code/plot_func_ERG_natHist.R")

# gen_count_df_pten <- function(status, bm_name){
gen_count_df_ERG_natHist <- function(json_file_paths_filt,status,bm_name){
  
  json_file_paths <- json_file_paths_filt
  print(length(json_file_paths))
  
  
  json_dat_list <- list()
  
  # for (j in 1:10){
  for (j in 1:length(json_file_paths)){
    # j <- 1
    path <- json_file_paths[[j]]
    json_raw <- read_json(path)
    json_dat_list[[j]] <- list()
    json_dat_list[[j]]$json <- json_raw
    json_dat_list[[j]]$nuc <- json_raw$nuc
    
    nuc_list <- list()
    
    for (i in 1:length(json_dat_list[[j]]$nuc)){
      index_inst = json_dat_list[[j]]$nuc[[i]]
      index_val = index_inst$type
      nuc_list[[i]] <- index_val
      json_dat_list[[j]]$nuc_list <- nuc_list
      json_dat_list[[j]]$nuc_vec <- unlist(nuc_list)
      names(json_dat_list)[j] <- path
    }
    
  }
  
  #names(json_dat_list) <- gsub('.+natHist-', 'natHist-', names(json_dat_list) )
  names(json_dat_list) <- gsub('.+_pca', 'pca', names(json_dat_list) )
  names(json_dat_list) <- gsub('_x.+', '', names(json_dat_list) )
  #names(json_dat_list) <- str_split(names(json_dat_list), "-", n=3, simplify = TRUE)
  print(names(json_dat_list))
  
  
  count_list <- list()
  for (i in 1:length(json_dat_list)){
    count_list[[i]] <- json_dat_list[[i]]$nuc_vec
  }
  
  length(count_list) == length(json_dat_list)
  names(count_list) <- names(json_dat_list)
  #print(names(count_list))
  
  
  #count_vec <- unlist(count_list, use.names=F)
  count_vec <- setNames(unlist(count_list, use.names=F),rep(names(count_list), lengths(count_list)))
  print(names(count_vec))
  
  nuc_df <- data.frame(count_vec)
  
  nuc_df$patient <- names(count_vec)
  
  pred_ERG <- ifelse(status == T, "ERG_positive", "ERG_negative")
  nuc_df <- nuc_df %>% 
    dplyr::mutate(pred_ERG = factor(pred_ERG, levels = c("ERG_negative", "ERG_positive"), labels = c("ERG_negative", "ERG_positive")),bm_name = bm_name)
  
  
  return(nuc_df)
}

# get the paths for the natHist ERG fusion
fusion_paths_natHist <- filter_paths_natHist(status = T, bm_name = 'ERG')
wt_paths_natHist <- filter_paths_natHist(status = F, bm_name = 'ERG')

#########################################################
# Make a dataframe with nuclear types for each slide/patient: fusion
fusion_df_natHist <- gen_count_df_ERG_natHist(json_file_paths_filt = fusion_paths_natHist, status = T, bm_name = 'ERG')
length(unique(fusion_df_natHist$patient))


# change the nuclei names
table(fusion_df_natHist$count_vec)
# remove 0
fusion_df_natHist <- fusion_df_natHist[!(fusion_df_natHist$count_vec == '0'), ]
fusion_df_natHist$count_vec <- as.factor(fusion_df_natHist$count_vec)
levels(fusion_df_natHist$count_vec) <- c("neoplastic", "immune", "stroma", "necrotic", "benign_epithelial")

# make in a wider format
fusion_df_natHist_summarized <- fusion_df_natHist %>% 
  group_by(patient) %>%
  count(count_vec) %>%
  pivot_wider(names_from="count_vec", values_from="n", 
              values_fn=sum) %>%
  replace(is.na(.), 0) %>%
  mutate(sum_all = rowSums(across(where(is.numeric)))) %>%
  mutate_if(is.numeric, funs(ratio = 100 * ./sum_all)) %>%
  mutate('stroma_neoplastic_ratio' = stroma/neoplastic)

fusion_df_natHist_summarized$pred <- 'ERG positive'  

######################################################
# Make a dataframe with nuclear types for each slide/patient: fusion
wt_df_natHist <- gen_count_df_ERG_natHist(json_file_paths_filt = wt_paths_natHist, status = F, bm_name = 'ERG')
length(unique(wt_df_natHist$patient))

# change the nuclei names
table(wt_df_natHist$count_vec)
# remove 0
wt_df_natHist <- wt_df_natHist[!(wt_df_natHist$count_vec == '0'), ]
wt_df_natHist$count_vec <- as.factor(wt_df_natHist$count_vec)
levels(wt_df_natHist$count_vec) <- c("neoplastic", "immune", "stroma", "necrotic", "benign_epithelial")

# make in a wider format
wt_df_natHist_summarized <- wt_df_natHist %>% 
  group_by(patient) %>%
  count(count_vec) %>%
  pivot_wider(names_from="count_vec", values_from="n", 
              values_fn=sum) %>%
  replace(is.na(.), 0) %>%
  mutate(sum_all = rowSums(across(where(is.numeric)))) %>%
  mutate_if(is.numeric, funs(ratio = 100 * ./sum_all)) %>%
  mutate('stroma_neoplastic_ratio' = stroma/neoplastic)

wt_df_natHist_summarized$pred <- 'ERG negative'  

######################################
# combine together
natHist_nuclei <- rbind(wt_df_natHist_summarized, fusion_df_natHist_summarized)

length(natHist_nuclei$patient)

#####################################################
#####################################################
# load the natHist clinical data
natHist_clinical_1 <- read_csv('natHist_IHCdata2.csv')
natHist_clinical_2 <- read_csv('NatHistPheno.csv')

# merge
natHist_clinical <- merge(natHist_clinical_1, natHist_clinical_2, by.x = 'slide_id', by.y = 'slide_id')

###
# join the nuclei data with clinical data
natHist_clinical_nuclei <- merge(natHist_clinical, natHist_nuclei, by.x = 'slide_id', by.y = 'patient')

length(unique(natHist_clinical_nuclei$patient_id))
# natHist.V1.A9O5: repeated for some reason
natHist_clinical_nuclei <- natHist_clinical_nuclei[!duplicated(natHist_clinical_nuclei$patient_id), ]


natHist_clinical_nuclei[, 'ERG_status'] <- natHist_clinical_nuclei$ERG.IHC.x
table(natHist_clinical_nuclei$ERG_status)
table(natHist_clinical_nuclei$pred)

##############################################################################
## survival
#colnames(natHist_clinical_nuclei) <- gsub('_', ' ', colnames(natHist_clinical_nuclei))

CoxData_natHist <- natHist_clinical_nuclei[, c("os", "os_time", "met", "met_time","pathgs", "pstage", "preop_psa", "age", 'adt', 'rt', 'rp_type', 'bmi',
                                         "neoplastic_ratio", "immune_ratio", "stroma_ratio", "necrotic_ratio", "benign_epithelial_ratio", "stroma_neoplastic_ratio", 
                                         'ERG_status', 'pred')]

nuc_ratios <- c("neoplastic_ratio", "immune_ratio", "stroma_ratio", "necrotic_ratio", "benign_epithelial_ratio", "stroma_neoplastic_ratio")

CutPoint_os <- surv_cutpoint(data = CoxData_natHist, time = "os_time", event = "os", variables = nuc_ratios)
CutPoint_os

CutPoint_met <- surv_cutpoint(data = CoxData_natHist, time = "met_time", event = "met", variables = nuc_ratios)
CutPoint_met

SurvData_natHist_os <- surv_categorize(CutPoint_os)
SurvData_natHist_met <- surv_categorize(CutPoint_met)


# re-add the other info
SurvData_natHist_os$ERG_status <- as.factor(CoxData_natHist$ERG_status)
SurvData_natHist_met$ERG_status <- as.factor(CoxData_natHist$ERG_status)

SurvData_natHist_os$gleason_score <- as.factor(CoxData_natHist$pathgs)
SurvData_natHist_met$gleason_score <- as.factor(CoxData_natHist$pathgs)

SurvData_natHist_os$pstage <- as.factor(CoxData_natHist$pstage)
SurvData_natHist_met$pstage <- as.factor(CoxData_natHist$pstage)

SurvData_natHist_os$preop_psa <- CoxData_natHist$preop_psa
SurvData_natHist_met$preop_psa <- CoxData_natHist$preop_psa

SurvData_natHist_os$age <- as.numeric(CoxData_natHist$age)
SurvData_natHist_met$age <- as.numeric(CoxData_natHist$age)

SurvData_natHist_os$adt <- as.factor(CoxData_natHist$adt)
SurvData_natHist_met$adt <- as.factor(CoxData_natHist$adt)

SurvData_natHist_os$rt <- as.factor(CoxData_natHist$rt)
SurvData_natHist_met$rt <- as.factor(CoxData_natHist$rt)

SurvData_natHist_os$rp_type <- as.factor(CoxData_natHist$rp_type)
SurvData_natHist_met$rp_type <- as.factor(CoxData_natHist$rp_type)

SurvData_natHist_os$bmi <- as.numeric(CoxData_natHist$bmi)
SurvData_natHist_met$bmi <- as.numeric(CoxData_natHist$bmi)

#################
# fit surv curves by each of the nuclei ratios
nuc_ratios_list <- as.list(unlist(nuc_ratios))
names(nuc_ratios_list) <- nuc_ratios

###########
## functions for plotting km curves

# os 
surv_func_natHist_os <- function(x){
  f <- as.formula(paste("Surv(os_time, os) ~", x))
  return(surv_fit(f, data = SurvData_natHist_os))
}

# met
surv_func_natHist_met <- function(x){
  f <- as.formula(paste("Surv(met_time, met) ~", x))
  return(surv_fit(f, data = SurvData_natHist_met))
}



################
# fit curves without erg status
fit_list_nuclei_natHist_os <- lapply(nuc_ratios_list, surv_func_natHist_os)
fit_list_nuclei_natHist_met <- lapply(nuc_ratios_list, surv_func_natHist_met)

################
# calculate the pvalue: without erg status
Pval_list_nuclei_natHist_os <- surv_pvalue(fit_list_nuclei_natHist_os)
Pval_df_nuclei_natHist_os <- do.call(rbind.data.frame, Pval_list_nuclei_natHist_os)

Pval_list_nuclei_natHist_met <- surv_pvalue(fit_list_nuclei_natHist_met)
Pval_df_nuclei_natHist_met <- do.call(rbind.data.frame, Pval_list_nuclei_natHist_met)

#####################################################################################
#####################################################################################
## indv figures

# nat Hist

# OS

tiff(filename = './figures/survival/natHist/os/natHist_nuclei_os_neoplastic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_os$neoplastic_ratio, 
           data = SurvData_natHist_os, 
           legend.title = '', 
           legend.labs = c('high neoplastic content', 'low neoplastic content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/os/natHist_nuclei_os_immune.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_os$immune_ratio, 
           data = SurvData_natHist_os, 
           legend.title = '', 
           legend.labs = c('high immune content', 'low immune content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/os/natHist_nuclei_os_stroma.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_os$stroma_ratio, 
           data = SurvData_natHist_os, 
           legend.title = '', 
           legend.labs = c('high stromal content', 'low stromal content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/os/natHist_nuclei_os_necrotic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_os$necrotic_ratio, 
           data = SurvData_natHist_os, 
           legend.title = '', 
           legend.labs = c('high necrotic content', 'low necrotic content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/os/natHist_nuclei_os_benignEpith.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_os$benign_epithelial_ratio, 
           data = SurvData_natHist_os, 
           legend.title = '', 
           legend.labs = c('high benign epithelial content', 'low benign epithelial content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 1))
dev.off()

tiff(filename = './figures/survival/natHist/os/natHist_nuclei_os_stroma_neoplastic_ratio.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_os$stroma_neoplastic_ratio, 
           data = SurvData_natHist_os, 
           legend.title = '', 
           legend.labs = c('high stroma to neoplastic ratio', 'low stroma to neoplastic ratio'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 1))
dev.off()

#################
# met

tiff(filename = './figures/survival/natHist/met/natHist_nuclei_met_neoplastic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_met$neoplastic_ratio, 
           data = SurvData_natHist_met, 
           legend.title = '', 
           legend.labs = c('high neoplastic content', 'low neoplastic content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/met/natHist_nuclei_met_immune.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_met$immune_ratio, 
           data = SurvData_natHist_met, 
           legend.title = '', 
           legend.labs = c('high immune content', 'low immune content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/met/natHist_nuclei_met_stroma.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_met$stroma_ratio, 
           data = SurvData_natHist_met, 
           legend.title = '', 
           legend.labs = c('high stromal content', 'low stromal content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/met/natHist_nuclei_met_necrotic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_met$necrotic_ratio, 
           data = SurvData_natHist_met, 
           legend.title = '', 
           legend.labs = c('high necrotic content', 'low necrotic content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/natHist/met/natHist_nuclei_met_benignEpith.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_met$benign_epithelial_ratio, 
           data = SurvData_natHist_met, 
           legend.title = '', 
           legend.labs = c('high benign epithelial content', 'low benign epithelial content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 1))
dev.off()

tiff(filename = './figures/survival/natHist/met/natHist_nuclei_met_stroma_neoplastic_ratio.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_natHist_met$stroma_neoplastic_ratio, 
           data = SurvData_natHist_met, 
           legend.title = '', 
           legend.labs = c('high stroma to neoplastic ratio', 'low stroma to neoplastic ratio'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 1))
dev.off()


###########################################################################################
###########################################################################################
## fit coxph model:

SurvData_natHist_os$neoplastic_ratio <- factor(SurvData_natHist_os$neoplastic_ratio, levels = c('low', 'high'))
SurvData_natHist_os$immune_ratio <- factor(SurvData_natHist_os$immune_ratio, levels = c('low', 'high'))
SurvData_natHist_os$stroma_ratio <- factor(SurvData_natHist_os$stroma_ratio, levels = c('low', 'high'))
SurvData_natHist_os$necrotic_ratio <- factor(SurvData_natHist_os$necrotic_ratio, levels = c('low', 'high'))
SurvData_natHist_os$benign_epithelial_ratio <- factor(SurvData_natHist_os$benign_epithelial_ratio, levels = c('low', 'high'))
SurvData_natHist_os$stroma_neoplastic_ratio <- factor(SurvData_natHist_os$stroma_neoplastic_ratio, levels = c('low', 'high'))


SurvData_natHist_met$neoplastic_ratio <- factor(SurvData_natHist_met$neoplastic_ratio, levels = c('low', 'high'))
SurvData_natHist_met$immune_ratio <- factor(SurvData_natHist_met$immune_ratio, levels = c('low', 'high'))
SurvData_natHist_met$stroma_ratio <- factor(SurvData_natHist_met$stroma_ratio, levels = c('low', 'high'))
SurvData_natHist_met$necrotic_ratio <- factor(SurvData_natHist_met$necrotic_ratio, levels = c('low', 'high'))
SurvData_natHist_met$benign_epithelial_ratio <- factor(SurvData_natHist_met$benign_epithelial_ratio, levels = c('low', 'high'))
SurvData_natHist_met$stroma_neoplastic_ratio <- factor(SurvData_natHist_met$stroma_neoplastic_ratio, levels = c('low', 'high'))


# binarize gleason scores
SurvData_natHist_os$gleason_score_binary <- SurvData_natHist_os$gleason_score
table(SurvData_natHist_os$gleason_score_binary)
levels(SurvData_natHist_os$gleason_score_binary) <- c('<8', '>=8', '>=8')

SurvData_natHist_met$gleason_score_binary <- SurvData_natHist_met$gleason_score
table(SurvData_natHist_met$gleason_score_binary)
levels(SurvData_natHist_met$gleason_score_binary) <- c('<8', '>=8', '>=8')

# fix t stage
SurvData_natHist_os$pstage_new <- SurvData_natHist_os$pstage
table(SurvData_natHist_os$pstage_new)
levels(SurvData_natHist_os$pstage_new) <- c('T2', 'T2', 'T2', 'T2', 'T3a', 'T3b')

SurvData_natHist_met$pstage_new <- SurvData_natHist_met$pstage
table(SurvData_natHist_met$pstage_new)
levels(SurvData_natHist_met$pstage_new) <- c('T2', 'T2', 'T2', 'T2', 'T3a', 'T3b')

#######################################
## Fit the COXPH models
#######################################

## neoplastic
Fit_sig_natHist_os_coxph_neoplastic <- coxph(Surv(os_time, os) ~ neoplastic_ratio + gleason_score_binary + pstage_new + adt + preop_psa + age, 
                                           data = SurvData_natHist_os)

tiff(filename = './figures/survival/natHist/os/natHist_neoplastic_ratio_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_os_coxph_neoplastic)
dev.off()

# met
Fit_sig_natHist_met_coxph_neoplastic <- coxph(Surv(met_time, met) ~ neoplastic_ratio + gleason_score_binary + pstage_new + adt + preop_psa + age, 
                                             data = SurvData_natHist_met)
tiff(filename = './figures/survival/natHist/met/natHist_neoplastic_ratio_cox_met.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_met_coxph_neoplastic)
dev.off()

#############
# stroma_ratio
Fit_sig_natHist_os_coxph_stroma <- coxph(Surv(os_time, os) ~ stroma_ratio + gleason_score_binary + pstage_new + adt + preop_psa + age, 
                                       data = SurvData_natHist_os)
tiff(filename = './figures/survival/natHist/os/natHist_stroma_ratio_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_os_coxph_stroma)
dev.off()

Fit_sig_natHist_met_coxph_stroma <- coxph(Surv(met_time, met) ~ stroma_ratio + gleason_score_binary + pstage_new + adt + preop_psa + age, 
                                         data = SurvData_natHist_met)
tiff(filename = './figures/survival/natHist/met/natHist_stroma_ratio_cox_met.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_met_coxph_stroma)
dev.off()

##############
# immune_ratio
Fit_sig_natHist_os_coxph_immune <- coxph(Surv(os_time, os) ~ immune_ratio + gleason_score_binary + pstage_new + adt + preop_psa + age, 
                                       data = SurvData_natHist_os)
tiff(filename = './figures/survival/natHist/os/natHist_immune_ratio_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_os_coxph_immune)
dev.off()

Fit_sig_natHist_met_coxph_immune <- coxph(Surv(met_time, met) ~ immune_ratio + gleason_score_binary + pstage_new + adt + preop_psa + age, 
                                         data = SurvData_natHist_met)
tiff(filename = './figures/survival/natHist/met/natHist_immune_ratio_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_met_coxph_immune)
dev.off()

###############
# necrotic_ratio
Fit_sig_natHist_os_coxph_necrotic <- coxph(Surv(os_time, os) ~ necrotic_ratio+gleason_score_binary+ pstage_new + adt + preop_psa + age, 
                                         data = SurvData_natHist_os)
tiff(filename = './figures/survival/natHist/os/natHist_necrotic_ratio_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_os_coxph_necrotic)
dev.off()

Fit_sig_natHist_met_coxph_necrotic <- coxph(Surv(met_time, met) ~ necrotic_ratio+gleason_score_binary+ pstage_new + adt + preop_psa + age, 
                                           data = SurvData_natHist_met)
tiff(filename = './figures/survival/natHist/os/natHist_necrotic_ratio_cox_met.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_met_coxph_necrotic)
dev.off()

##################
# benign epithelial
Fit_sig_natHist_os_coxph_benign_epithelial <- coxph(Surv(os_time, os) ~ benign_epithelial_ratio+gleason_score_binary+ pstage_new + adt + preop_psa + age, 
                                                  data = SurvData_natHist_os)
tiff(filename = './figures/survival/natHist/os/natHist_benign_epithelial_ratio_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_os_coxph_benign_epithelial)
dev.off()

Fit_sig_natHist_met_coxph_benign_epithelial <- coxph(Surv(met_time, met) ~ benign_epithelial_ratio+gleason_score_binary+ pstage_new + adt + preop_psa + age, 
                                                    data = SurvData_natHist_met)
tiff(filename = './figures/survival/natHist/met/natHist_benign_epithelial_ratio_cox_met.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_met_coxph_benign_epithelial)
dev.off()

#######################
# stroma to neoplastic ratio
Fit_sig_natHist_os_coxph_stroma_neoplastic <- coxph(Surv(os_time, os) ~ stroma_neoplastic_ratio+gleason_score_binary+ pstage_new + adt + preop_psa + age, 
                                                  data = SurvData_natHist_os)
tiff(filename = './figures/survival/natHist/os/natHist_stroma_neoplastic_ratio_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_os_coxph_stroma_neoplastic)
dev.off()

Fit_sig_natHist_met_coxph_stroma_neoplastic <- coxph(Surv(met_time, met) ~ stroma_neoplastic_ratio+gleason_score_binary+ pstage_new + adt + preop_psa + age, 
                                                    data = SurvData_natHist_met)
tiff(filename = './figures/survival/natHist/met/natHist_stroma_neoplastic_ratio_cox_met.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_met_coxph_stroma_neoplastic)
dev.off()

###################################
# with all cell ratios and gleason
Fit_sig_natHist_os_coxph_all <- coxph(Surv(os_time, os) ~ + neoplastic_ratio+benign_epithelial_ratio+stroma_ratio+immune_ratio+necrotic_ratio+stroma_neoplastic_ratio+gleason_score_binary+ pstage_new+ adt + preop_psa + age, 
                                    data = SurvData_natHist_os)
tiff(filename = './figures/survival/natHist/os/natHist_all_cox_os.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_os_coxph_all)
dev.off()

Fit_sig_natHist_met_coxph_all <- coxph(Surv(met_time, met) ~ + neoplastic_ratio+benign_epithelial_ratio+stroma_ratio+immune_ratio+necrotic_ratio+stroma_neoplastic_ratio+gleason_score_binary+ pstage_new+ adt + preop_psa + age, 
                                      data = SurvData_natHist_met)
tiff(filename = './figures/survival/natHist/met/natHist_all_cox_met.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_natHist_met_coxph_all)
dev.off()
