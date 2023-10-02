
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

source("code/plot_func_ERG_TCGA.R")

# gen_count_df_pten <- function(status, bm_name){
gen_count_df_ERG_TCGA <- function(json_file_paths_filt,status,bm_name){

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
  
  names(json_dat_list) <- gsub('.+TCGA-', 'TCGA-', names(json_dat_list) )
  names(json_dat_list) <- gsub('-01Z.+', '', names(json_dat_list) )
  names(json_dat_list) <- gsub('-', '.', names(json_dat_list) )
  #names(json_dat_list) <- str_split(names(json_dat_list), "-", n=3, simplify = TRUE)
  #print(names(json_dat_list))

  
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

# get the paths for the TCGA ERG fusion
fusion_paths_tcga <- filter_paths_TCGA(status = T, bm_name = 'ERG')
wt_paths_tcga <- filter_paths_TCGA(status = F, bm_name = 'ERG')

#########################################################
# Make a dataframe with nuclear types for each slide/patient: fusion
fusion_df_tcga <- gen_count_df_ERG_TCGA(json_file_paths_filt = fusion_paths_tcga, status = T, bm_name = 'ERG')
length(unique(fusion_df_tcga$patient))

# change the nuclei names
table(fusion_df_tcga$count_vec)
# remove 0
fusion_df_tcga <- fusion_df_tcga[!(fusion_df_tcga$count_vec == '0'), ]
fusion_df_tcga$count_vec <- as.factor(fusion_df_tcga$count_vec)
levels(fusion_df_tcga$count_vec) <- c("neoplastic", "immune", "stroma", "necrotic", "benign_epithelial")

# make in a wider format
fusion_df_tcga_summarized <- fusion_df_tcga %>% 
  group_by(patient) %>%
  count(count_vec) %>%
  pivot_wider(names_from="count_vec", values_from="n", 
              values_fn=sum) %>%
  replace(is.na(.), 0) %>%
  mutate(sum_all = rowSums(across(where(is.numeric)))) %>%
  mutate_if(is.numeric, funs(ratio = 100 * ./sum_all)) %>%
  mutate('stroma_neoplastic_ratio' = stroma/neoplastic)

fusion_df_tcga_summarized$pred <- 'ERG positive'  

######################################################
# Make a dataframe with nuclear types for each slide/patient: fusion
wt_df_tcga <- gen_count_df_ERG_TCGA(json_file_paths_filt = wt_paths_tcga, status = F, bm_name = 'ERG')
length(unique(wt_df_tcga$patient))

# change the nuclei names
table(wt_df_tcga$count_vec)
# remove 0
wt_df_tcga <- wt_df_tcga[!(wt_df_tcga$count_vec == '0'), ]
wt_df_tcga$count_vec <- as.factor(wt_df_tcga$count_vec)
levels(wt_df_tcga$count_vec) <- c("neoplastic", "immune", "stroma", "necrotic", "benign_epithelial")

# make in a wider format
wt_df_tcga_summarized <- wt_df_tcga %>% 
  group_by(patient) %>%
  count(count_vec) %>%
  pivot_wider(names_from="count_vec", values_from="n", 
              values_fn=sum) %>%
  replace(is.na(.), 0) %>%
  mutate(sum_all = rowSums(across(where(is.numeric)))) %>%
  mutate_if(is.numeric, funs(ratio = 100 * ./sum_all)) %>%
  mutate('stroma_neoplastic_ratio' = stroma/neoplastic)

wt_df_tcga_summarized$pred <- 'ERG negative'  

######################################
# combine together
tcga_nuclei <- rbind(wt_df_tcga_summarized, fusion_df_tcga_summarized)

length(tcga_nuclei$patient)

#####################################################
#####################################################
# load the tcga clinical data
tcga_clinical1 <- read_csv('tcga_meta_data_all.csv')
tcga_clinical2 <- read_csv('tcga_clinical_data.csv')

# remove normal samples
table(tcga_clinical1$sample_type)
tcga_clinical1 <- tcga_clinical1[tcga_clinical1$sample_type == 'primary',]

# remove samples without erg status
tcga_clinical1 <- tcga_clinical1[!is.na(tcga_clinical1$ERGstatus),]

# merge together
tcga_clinical <- merge(tcga_clinical1, tcga_clinical2, by.x = 'patient_id', by.y = 'id')

###
# join the nuclei data with clinical data
tcga_clinical_nuclei <- merge(tcga_clinical, tcga_nuclei, by.x = 'patient_id', by.y = 'patient')

length(unique(tcga_clinical_nuclei$patient_id))
# TCGA.V1.A9O5: repeated for some reason
tcga_clinical_nuclei <- tcga_clinical_nuclei[!duplicated(tcga_clinical_nuclei$patient_id), ]


tcga_clinical_nuclei[, 'ERG_status'] <- tcga_clinical_nuclei$ERGstatus
table(tcga_clinical_nuclei$ERG_status)
table(tcga_clinical_nuclei$pred)

##############################################################################
## survival
#colnames(tcga_clinical_nuclei) <- gsub('_', ' ', colnames(tcga_clinical_nuclei))

CoxData_tcga <- tcga_clinical_nuclei[, c("PFI", "PFI_Time", "gleason_score",
                                           "neoplastic_ratio", "immune_ratio", "stroma_ratio", "necrotic_ratio", "benign_epithelial_ratio", "stroma_neoplastic_ratio", 
                                         'ERG_status', 'pred', 'psa_value', 'pathologic_t', 'pathologic_n', 'pathologic_m')]

nuc_ratios <- c("neoplastic_ratio", "immune_ratio", "stroma_ratio", "necrotic_ratio", "benign_epithelial_ratio", "stroma_neoplastic_ratio")

CutPoint_pfs <- surv_cutpoint(data = CoxData_tcga, time = "PFI_Time", event = "PFI", variables = nuc_ratios)
CutPoint_pfs

SurvData_tcga_pfs <- surv_categorize(CutPoint_pfs)


# re-add the other info
SurvData_tcga_pfs$ERG_status <- as.factor(CoxData_tcga$ERG_status)

SurvData_tcga_pfs$gleason_score <- as.factor(CoxData_tcga$gleason_score)

SurvData_tcga_pfs$psa_value <- CoxData_tcga$psa_value

SurvData_tcga_pfs$pathologic_t <- as.factor(CoxData_tcga$pathologic_t)

SurvData_tcga_pfs$pathologic_n <- as.factor(CoxData_tcga$pathologic_n)


#################
# fit surv curves by each of the nuclei ratios
nuc_ratios_list <- as.list(unlist(nuc_ratios))
names(nuc_ratios_list) <- nuc_ratios
  
###########
## functions for plotting km curves

# pfs without erg status
surv_func_tcga_pfs <- function(x){
  f <- as.formula(paste("Surv(PFI_Time, PFI) ~", x))
  return(surv_fit(f, data = SurvData_tcga_pfs))
}


################
# fit curves 
fit_list_nuclei_tcga_pfs <- lapply(nuc_ratios_list, surv_func_tcga_pfs)

#############
# calculate the pvalue
Pval_list_nuclei_tcga_pfs <- surv_pvalue(fit_list_nuclei_tcga_pfs)
Pval_df_nuclei_tcga_pfs <- do.call(rbind.data.frame, Pval_list_nuclei_tcga_pfs)

#################
# PFS

tiff(filename = './figures/survival/tcga/pfs/tcga_nuclei_pfs_neoplastic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$neoplastic_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           legend.labs = c('high neoplastic content', 'low neoplastic content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/tcga/pfs/tcga_nuclei_pfs_immune.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$immune_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           legend.labs = c('high immune content', 'low immune content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/tcga/pfs/tcga_nuclei_pfs_stroma.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$stroma_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           legend.labs = c('high stromal content', 'low stromal content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/tcga/pfs/tcga_nuclei_pfs_necrotic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$necrotic_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           legend.labs = c('high necrotic content', 'low necrotic content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival/tcga/pfs/tcga_nuclei_pfs_benignEpith.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$benign_epithelial_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           legend.labs = c('high benign epithelial content', 'low benign epithelial content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 1))
dev.off()

tiff(filename = './figures/survival/tcga/pfs/tcga_nuclei_pfs_stroma_neoplastic_ratio.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$stroma_neoplastic_ratio, 
           data = SurvData_tcga_pfs, 
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
## COXPH
SurvData_tcga_pfs$neoplastic_ratio <- factor(SurvData_tcga_pfs$neoplastic_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$immune_ratio <- factor(SurvData_tcga_pfs$immune_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$stroma_ratio <- factor(SurvData_tcga_pfs$stroma_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$necrotic_ratio <- factor(SurvData_tcga_pfs$necrotic_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$benign_epithelial_ratio <- factor(SurvData_tcga_pfs$benign_epithelial_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$stroma_neoplastic_ratio <- factor(SurvData_tcga_pfs$stroma_neoplastic_ratio, levels = c('low', 'high'))


SurvData_tcga_pfs$gleason_score_binary <- SurvData_tcga_pfs$gleason_score
table(SurvData_tcga_pfs$gleason_score_binary)
levels(SurvData_tcga_pfs$gleason_score_binary) <- c('<8', '<8', '>=8', '>=8', '>=8')

# neoplastic
Fit_sig_tcga_pfs_coxph_neoplastic <- coxph(Surv(PFI_Time, PFI) ~ neoplastic_ratio + gleason_score_binary + pathologic_t + pathologic_n, 
                                data = SurvData_tcga_pfs)

tiff(filename = './figures/survival/tcga/pfs/tcga_neoplastic_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_neoplastic)
dev.off()

#############
# stroma_ratio
Fit_sig_tcga_pfs_coxph_stroma <- coxph(Surv(PFI_Time, PFI) ~ stroma_ratio+gleason_score_binary + pathologic_t + pathologic_n, 
                                           data = SurvData_tcga_pfs)

tiff(filename = './figures/survival/tcga/pfs/tcga_stroma_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_stroma)
dev.off()

##############
# immune_ratio
Fit_sig_tcga_pfs_coxph_immune <- coxph(Surv(PFI_Time, PFI) ~ immune_ratio+gleason_score_binary+ pathologic_t + pathologic_n, 
                                       data = SurvData_tcga_pfs)

tiff(filename = './figures/survival/tcga/pfs/tcga_immune_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_immune)
dev.off()

###############
# necrotic_ratio
Fit_sig_tcga_pfs_coxph_necrotic <- coxph(Surv(PFI_Time, PFI) ~ necrotic_ratio+gleason_score_binary+ pathologic_t + pathologic_n, 
                                       data = SurvData_tcga_pfs)

tiff(filename = './figures/survival/tcga/pfs/tcga_necrotic_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_necrotic)
dev.off()


##################
# benign epithelial
Fit_sig_tcga_pfs_coxph_benign_epithelial <- coxph(Surv(PFI_Time, PFI) ~ benign_epithelial_ratio+gleason_score_binary+ pathologic_t + pathologic_n, 
                                         data = SurvData_tcga_pfs)

tiff(filename = './figures/survival/tcga/pfs/tcga_benign_epithelial_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_benign_epithelial)
dev.off()

#######################
# stroma to neoplastic ratio
Fit_sig_tcga_pfs_coxph_stroma_neoplastic <- coxph(Surv(PFI_Time, PFI) ~ stroma_neoplastic_ratio+gleason_score_binary+ pathologic_t + pathologic_n, 
                                                  data = SurvData_tcga_pfs)

tiff(filename = './figures/survival/tcga/pfs/tcga_stroma_neoplastic_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_stroma_neoplastic)
dev.off()


