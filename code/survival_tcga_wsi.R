
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

#####################################################
# Load the hovernet output data
tcga_nuclei_wsi <- read_csv('./hovernet_wsi/output/tcga/tcga_cellularComposition_wsi.csv')
tcga_nuclei_wsi$patient_id <- gsub("-", ".", substr(tcga_nuclei_wsi$patient_id, 1, 12))

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
tcga_clinical_nuclei <- merge(tcga_clinical, tcga_nuclei_wsi, by.x = 'patient_id')

length(unique(tcga_clinical_nuclei$patient_id))

# remove duplicates
tcga_clinical_nuclei <- tcga_clinical_nuclei[!duplicated(tcga_clinical_nuclei$patient_id), ]

# clean the label column
tcga_clinical_nuclei[, 'ERG_status'] <- tcga_clinical_nuclei$ERGstatus
table(tcga_clinical_nuclei$ERG_status)

# fix the benign epithelial column name
names(tcga_clinical_nuclei)[names(tcga_clinical_nuclei) == "benign epithelial"] <- "benign_epithelial"

###################################
# calculate the ratio of each cell type in each patient
###################################

# Columns that correspond to cell types
cell_type_columns <- c("stromal", "neoplastic", "inflammatory", "benign_epithelial", "necrotic", "no label")

# Calculate the sum for all cell types for each patient
tcga_clinical_nuclei$sum_all <- rowSums(tcga_clinical_nuclei[, cell_type_columns])

# Calculate the ratio for each cell type
tcga_clinical_nuclei_ratio <- tcga_clinical_nuclei %>%
  mutate_at(vars(cell_type_columns), ~ . / sum_all * 100)

# calculate 'stroma_neoplastic_ratio'
tcga_clinical_nuclei_ratio$stroma_neoplastic_ratio <- tcga_clinical_nuclei_ratio$stromal / tcga_clinical_nuclei_ratio$neoplastic

##############################################################################
## survival
#colnames(tcga_clinical_nuclei) <- gsub('_', ' ', colnames(tcga_clinical_nuclei))

CoxData_tcga <- tcga_clinical_nuclei_ratio[, c("OS", "OS_Time", "PFI", "PFI_Time", "gleason_score",
                                               cell_type_columns, 
                                               "stroma_neoplastic_ratio", 
                                               'ERG_status')
                                           ]

# Modify the column names for the ratio columns
for (col in cell_type_columns) {
  names(CoxData_tcga)[names(CoxData_tcga) == col] <- paste0(col, "_ratio")
}


# If you want the ratios as percentages, multiply by 100 as shown above. Otherwise, remove the "* 100".

nuc_ratios <- c("neoplastic_ratio", "inflammatory_ratio", "stromal_ratio", "necrotic_ratio", "benign_epithelial_ratio", "stroma_neoplastic_ratio")

CutPoint_os <- surv_cutpoint(data = CoxData_tcga, time = "OS_Time", event = "OS", variables = nuc_ratios)
CutPoint_os

CutPoint_pfs <- surv_cutpoint(data = CoxData_tcga, time = "PFI_Time", event = "PFI", variables = nuc_ratios)
CutPoint_pfs

SurvData_tcga_os <- surv_categorize(CutPoint_os)
SurvData_tcga_pfs <- surv_categorize(CutPoint_pfs)


# re-add the other info
SurvData_tcga_os$ERG_status <- as.factor(CoxData_tcga$ERG_status)
SurvData_tcga_pfs$ERG_status <- as.factor(CoxData_tcga$ERG_status)

SurvData_tcga_os$gleason_score <- as.factor(CoxData_tcga$gleason_score)
SurvData_tcga_pfs$gleason_score <- as.factor(CoxData_tcga$gleason_score)

#################
# fit surv curves by each of the nuclei ratios
nuc_ratios_list <- as.list(unlist(nuc_ratios))
names(nuc_ratios_list) <- nuc_ratios

###########
## functions for plotting km curves

# os without erg status
surv_func_tcga_os <- function(x){
  f <- as.formula(paste("Surv(OS_Time, OS) ~", x))
  return(surv_fit(f, data = SurvData_tcga_os))
}
# os with erg status
surv_func_tcga_os_ergStatus <- function(x){
  f <- as.formula(paste("Surv(OS_Time, OS) ~", x, '+', 'ERG_status'))
  return(surv_fit(f, data = SurvData_tcga_os))
}
# pfs without erg status
surv_func_tcga_pfs <- function(x){
  f <- as.formula(paste("Surv(PFI_Time, PFI) ~", x))
  return(surv_fit(f, data = SurvData_tcga_pfs))
}

# pfs with erg status
surv_func_tcga_pfs_ergStatus <- function(x){
  f <- as.formula(paste("Surv(PFI_Time, PFI) ~", x, '+', 'ERG_status'))
  return(surv_fit(f, data = SurvData_tcga_pfs))
}

################
# fit curves without erg status
fit_list_nuclei_tcga_os <- lapply(nuc_ratios_list, surv_func_tcga_os)
fit_list_nuclei_tcga_pfs <- lapply(nuc_ratios_list, surv_func_tcga_pfs)

# fit curves with erg status
fit_list_nuclei_tcga_os_ergStatus <- lapply(nuc_ratios_list, surv_func_tcga_os_ergStatus)
fit_list_nuclei_tcga_pfs_ergStatus <- lapply(nuc_ratios_list, surv_func_tcga_pfs_ergStatus)

################
# calculate the pvalue: without erg status
Pval_list_nuclei_tcga_os <- surv_pvalue(fit_list_nuclei_tcga_os)
Pval_df_nuclei_tcga_os <- do.call(rbind.data.frame, Pval_list_nuclei_tcga_os)

Pval_list_nuclei_tcga_pfs <- surv_pvalue(fit_list_nuclei_tcga_pfs)
Pval_df_nuclei_tcga_pfs <- do.call(rbind.data.frame, Pval_list_nuclei_tcga_pfs)

# calculate the pvalue: with erg status
Pval_list_nuclei_tcga_os_ergStatus <- surv_pvalue(fit_list_nuclei_tcga_os_ergStatus)
Pval_df_nuclei_tcga_os_ergStatus <- do.call(rbind.data.frame, Pval_list_nuclei_tcga_os_ergStatus)

Pval_list_nuclei_tcga_pfs_ergStatus <- surv_pvalue(fit_list_nuclei_tcga_pfs_ergStatus)
Pval_df_nuclei_tcga_pfs_ergStatus <- do.call(rbind.data.frame, Pval_list_nuclei_tcga_pfs_ergStatus)

####################################
## Plot survival curves

# # without erg status
# plot_list_nuclei_tcga_os <- ggsurvplot_list(fit_list_nuclei_tcga_os, 
#                                             data = SurvData_tcga_os, 
#                                             legend.title = names(fit_list_nuclei_tcga_os), 
#                                             pval = TRUE)
# 
# plot_list_nuclei_tcga_pfs <- ggsurvplot_list(fit_list_nuclei_tcga_pfs, 
#                                              data = SurvData_tcga_pfs, 
#                                              legend.title = names(fit_list_nuclei_tcga_pfs), 
#                                              pval = TRUE)
# 
# 
# Splot_tcga_os <- arrange_ggsurvplots(plot_list_nuclei_tcga_os, title = "Overall Survival plots using the nuclei ratios", ncol = 2, nrow = 3)
# Splot_tcga_pfs <- arrange_ggsurvplots(plot_list_nuclei_tcga_pfs, title = "Progression Free Survival plots using the nuclei ratios", ncol = 2, nrow = 3)
# 
# ggsave("./figures/tcga_nuclei_os.pdf", Splot_tcga_os, width = 40, height = 40, units = "cm")
# ggsave("./figures/tcga_nuclei_pfs.pdf", Splot_tcga_pfs, width = 40, height = 40, units = "cm")
# 
# 
# ############
# # with erg status
# plot_list_nuclei_tcga_os_ergStatus <- ggsurvplot_list(fit_list_nuclei_tcga_os_ergStatus, 
#                                             data = SurvData_tcga_os, 
#                                             legend.title = names(fit_list_nuclei_tcga_os_ergStatus), 
#                                             pval = TRUE, 
#                                             #facet.by = 'ERG_status'
#                                             )
# 
# Labs_list <- list(neoplastic_ratio = c('ERG- high neoplastic content', 'ERG+ high neoplastic content', 'ERG- low neoplastic content', 'ERG+ low neoplastic content'), 
#                   immune_ratio = c('ERG- high immune content', 'ERG+ high immune content', 'ERG- low immune content', 'ERG+ low immune content'), 
#                   stromal_ratio= c('ERG- high stromal content', 'ERG+ high stromal content', 'ERG- low stromal content', 'ERG+ low stromal content'),
#                   necrotic_ratio = c('ERG- high necrotic content', 'ERG+ high necrotic content', 'ERG- low necrotic content', 'ERG+ low necrotic content'),
#                   benign_epithial_ratio = c('ERG- high benign epith content', 'ERG+ high benign epith content', 'ERG- low benign epith content', 'ERG+ low benign epith content'), 
#                   stromal_neoplastic_ratio = c('ERG- high stromal/neoplastic ratio', 'ERG+ high stromal/neoplastic ratio', 'ERG- low stromal/neoplastic ratio', 'ERG+ low stromal/neoplastic ratio')
#                 )
# 
# 
# plot_list_nuclei_tcga_pfs_ergStatus <- ggsurvplot_list(fit_list_nuclei_tcga_pfs_ergStatus, 
#                                              data = SurvData_tcga_pfs, 
#                                              legend.title = '', 
#                                              legend.labs = Labs_list,
#                                              pval = TRUE, 
#                                              pval.size =	10,
#                                              ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(14, "plain", "black")),
#                                              #facet.by = 'ERG_status'
#                                              ) 
# 
# Splot_tcga_os_ergStatus <- arrange_ggsurvplots(plot_list_nuclei_tcga_os_ergStatus, #title = "Overall Survival plots using the nuclei ratios", 
#                                                ncol = 2, nrow = 3)
# 
# Splot_tcga_pfs_ergStatus <- arrange_ggsurvplots(plot_list_nuclei_tcga_pfs_ergStatus, #title = "Progression Free Survival plots using the nuclei ratios", 
#                                                 ncol = 2, nrow = 3)
# 
# ggsave("./figures/tcga_nuclei_os_byERGstatus.pdf", Splot_tcga_os_ergStatus, width = 40, height = 40, units = "cm")
# ggsave("./figures/tcga_nuclei_pfs_byERGstatus.pdf", Splot_tcga_pfs_ergStatus, width = 60, height = 65, units = "cm")

#####################################################################################
#####################################################################################
## indv figures

# TCGA

## without erg status

# OS

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_neoplastic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_os$neoplastic_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           legend.labs = c('high neoplastic content', 'low neoplastic content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_immune.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_os$inflammatory_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           legend.labs = c('high immune content', 'low immune content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_stroma.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_os$stromal_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           legend.labs = c('high stromal content', 'low stromal content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_necrotic.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_os$necrotic_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           legend.labs = c('high necrotic content', 'low necrotic content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_benignEpith.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_os$benign_epithelial_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           legend.labs = c('high benign epithelial content', 'low benign epithelial content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 1))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_stroma_neoplastic_ratio.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_os$stroma_neoplastic_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           legend.labs = c('high stroma to neoplastic ratio', 'low stroma to neoplastic ratio'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 1))
dev.off()


#################
# PFS

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_neoplastic.tiff', width = 2500, height = 2500, res = 400)
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

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_immune.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$inflammatory_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           legend.labs = c('high immune content', 'low immune content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_stroma.tiff', width = 2500, height = 2500, res = 400)
ggsurvplot(fit_list_nuclei_tcga_pfs$stromal_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           legend.labs = c('high stromal content', 'low stromal content'),
           pval = TRUE, 
           pval.size =	10,
           ggtheme = theme_survminer(base_size = 12, font.main = c(16, 'bold', 'black'), font.legend = c(16, "plain", "black")),
           #facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_necrotic.tiff', width = 2500, height = 2500, res = 400)
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

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_benignEpith.tiff', width = 2500, height = 2500, res = 400)
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

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_stroma_neoplastic_ratio.tiff', width = 2500, height = 2500, res = 400)
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


####################################################################
####################################################################
# with erg status
tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_byERGstatus_neoplastic.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_os_ergStatus$neoplastic_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           #legend.labs = c('ERG- high neoplastic content', 'ERG+ high neoplastic content', 'ERG- low neoplastic content', 'ERG+ low neoplastic content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = "ERG_status",
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_byERGstatus_immune.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_os_ergStatus$inflammatory_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           #legend.labs = c('ERG- high immune content', 'ERG+ high immune content', 'ERG- low immune content', 'ERG+ low immune content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_byERGstatus_stroma.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_os_ergStatus$stromal_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           #legend.labs = c('ERG- high stromal content', 'ERG+ high stromal content', 'ERG- low stromal content', 'ERG+ low stromal content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_byERGstatus_necrotic.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_os_ergStatus$necrotic_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           #legend.labs = c('ERG- high necrotic content', 'ERG+ high necrotic content', 'ERG- low necrotic content', 'ERG+ low necrotic content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_byERGstatus_benignEpith.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_os_ergStatus$benign_epithelial_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           #legend.labs = c('ERG- high benign epithelial content', 'ERG+ high benign epithelial content', 'ERG- low benign epithelial content', 'ERG+ low benign epithelial content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/os/tcga_nuclei_os_byERGstatus_stroma_neoplastic_ratio.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_os_ergStatus$stroma_neoplastic_ratio, 
           data = SurvData_tcga_os, 
           legend.title = '', 
           #legend.labs = c('ERG- high stroma to neoplastic ratio', 'ERG+ high stroma to neoplastic ratio', 'ERG- low stroma to neoplastic ratio', 'ERG+ low stroma to neoplastic ratio'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

##################################
# pfs
tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_byERGstatus_neoplastic.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_pfs_ergStatus$neoplastic_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           #legend.labs = c('ERG- high neoplastic content', 'ERG+ high neoplastic content', 'ERG- low neoplastic content', 'ERG+ low neoplastic content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_byERGstatus_immune.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_pfs_ergStatus$inflammatory_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           #legend.labs = c('ERG- high immune content', 'ERG+ high immune content', 'ERG- low immune content', 'ERG+ low immune content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_byERGstatus_stroma.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_pfs_ergStatus$stromal_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           #legend.labs = c('ERG- high stromal content', 'ERG+ high stromal content', 'ERG- low stromal content', 'ERG+ low stromal content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_byERGstatus_necrotic.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_pfs_ergStatus$necrotic_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           #legend.labs = c('ERG- high necrotic content', 'ERG+ high necrotic content', 'ERG- low necrotic content', 'ERG+ low necrotic content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_byERGstatus_benignEpith.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_pfs_ergStatus$benign_epithelial_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           #legend.labs = c('ERG- high benign epithelial content', 'ERG+ high benign epithelial content', 'ERG- low benign epithelial content', 'ERG+ low benign epithelial content'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

tiff(filename = './figures/survival_wsi/pfs/tcga_nuclei_pfs_byERGstatus_stroma_neoplastic_ratio.tiff', width = 2500, height = 2500, res = 300)
ggsurvplot(fit_list_nuclei_tcga_pfs_ergStatus$stroma_neoplastic_ratio, 
           data = SurvData_tcga_pfs, 
           legend.title = '', 
           #legend.labs = c('ERG- high stroma to neoplastic ratio', 'ERG+ high stroma to neoplastic ratio', 'ERG- low stroma to neoplastic ratio', 'ERG+ low stroma to neoplastic ratio'),
           pval = TRUE, 
           pval.size =	8,
           ggtheme = theme_survminer(base_size = 12, font.main = c(12, 'bold', 'black'), font.legend = c(14, "plain", "black")),
           facet.by = 'ERG_status'
) + guides(colour = guide_legend(ncol = 2))
dev.off()

###########################################################################################
###########################################################################################
## fit coxph model:

SurvData_tcga_pfs$neoplastic_ratio <- factor(SurvData_tcga_pfs$neoplastic_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$inflammatory_ratio <- factor(SurvData_tcga_pfs$inflammatory_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$stromal_ratio <- factor(SurvData_tcga_pfs$stromal_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$necrotic_ratio <- factor(SurvData_tcga_pfs$necrotic_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$benign_epithelial_ratio <- factor(SurvData_tcga_pfs$benign_epithelial_ratio, levels = c('low', 'high'))
SurvData_tcga_pfs$stroma_neoplastic_ratio <- factor(SurvData_tcga_pfs$stroma_neoplastic_ratio, levels = c('low', 'high'))

#levels(SurvData_tcga_pfs$gleason_score) <- c('<8', '<8', '>=8', '>=8', '>=8')

####################
## coxph funcs

# without ERG status
# surv_func_tcga_pfs_coxph <- function(x){
#   f <- as.formula(paste("Surv(PFI_Time, PFI) ~", x))
#   return(coxph(f, data = SurvData_tcga_pfs))
# }
# 
# # with gleason
# surv_func_tcga_pfs_coxph_withGleason <- function(x){
#   f <- as.formula(paste("Surv(PFI_Time, PFI) ~", x, '+', 'gleason_score'))
#   return(coxph(f, data = SurvData_tcga_pfs))
# }


#################
## fit curves

# # without erg status
# fit_list_tcga_pfs_coxph <- lapply(nuc_ratios_list, surv_func_tcga_pfs_coxph)
# names(fit_list_tcga_pfs_coxph) <- nuc_ratios_list
# 
# 
# # with erg status
# fit_list_tcga_pfs_coxph_withGleason <- lapply(nuc_ratios_list, surv_func_tcga_pfs_coxph_withGleason)
# names(fit_list_tcga_pfs_coxph_withGleason) <- nuc_ratios_list
# 
# #######################
# ## get the HR by nuclear type
# 
# 
# # without erg status
# summary_list_tcga_pfs_coxph <- lapply(fit_list_tcga_pfs_coxph, summary)
# 
# # get the HR
# HR_list_tcga_pfs_coxph <- lapply(summary_list_tcga_pfs_coxph, function(x){
#   HR <- x$conf.int[, 'exp(coef)']
#   Pvalue_Likelihood_ratio_test <- x$logtest['pvalue']
#   Pvalue_logrank_test <- x$sctest['pvalue']
#   Pvalue_wald_test <- x$waldtest['pvalue']
#   data.frame(HR = HR, Pvalue_Likelihood_ratio_test = Pvalue_Likelihood_ratio_test, 
#              Pvalue_logrank_test = Pvalue_logrank_test, Pvalue_wald_test = Pvalue_wald_test)
# })
# 
# 
# HR_df_tcga_pfs_coxph <- as.data.frame(do.call(rbind, HR_list_tcga_pfs_coxph))
# HR_df_tcga_pfs_coxph$variable <- rownames(HR_df_tcga_pfs_coxph)
# HR_df_tcga_pfs_coxph <- HR_df_tcga_pfs_coxph[order(HR_df_tcga_pfs_coxph$HR, decreasing = T), ]
# 
# # save the results
# write.csv(HR_df_tcga_pfs_coxph, 'objs/HR_df_tcga_pfs_coxph.csv')
# 
# ###################
# # with erg status
# summary_list_tcga_pfs_coxph_withGleason <- lapply(fit_list_tcga_pfs_coxph_withGleason, summary)
# 
# # get the HR
# HR_list_tcga_pfs_coxph_withGleason <- lapply(summary_list_tcga_pfs_coxph_withGleason, function(x){
#   HR <- x$conf.int[, 'exp(coef)']
#   Pvalue_Likelihood_ratio_test <- x$logtest['pvalue']
#   Pvalue_logrank_test <- x$sctest['pvalue']
#   Pvalue_wald_test <- x$waldtest['pvalue']
#   data.frame(HR = HR, Pvalue_Likelihood_ratio_test = Pvalue_Likelihood_ratio_test, 
#              Pvalue_logrank_test = Pvalue_logrank_test, Pvalue_wald_test = Pvalue_wald_test)
# })
# 
# 
# HR_df_tcga_pfs_coxph_withGleason <- as.data.frame(do.call(rbind, HR_list_tcga_pfs_coxph_withGleason))
# HR_df_tcga_pfs_coxph_withGleason$variable <- rownames(HR_df_tcga_pfs_coxph_withGleason)
# HR_df_tcga_pfs_coxph_withGleason <- HR_df_tcga_pfs_coxph_withGleason[order(HR_df_tcga_pfs_coxph_withGleason$HR, decreasing = T), ]
# 
# # save the results
# write.csv(HR_df_tcga_pfs_coxph_ergStatus, 'objs/HR_df_tcga_pfs_coxph_ergStatus.csv')

################################
## COXPH

SurvData_tcga_pfs$gleason_score_binary <- SurvData_tcga_pfs$gleason_score
table(SurvData_tcga_pfs$gleason_score_binary)
levels(SurvData_tcga_pfs$gleason_score_binary) <- c('<8', '<8', '8', '>8', '>8')

# neoplastic
Fit_sig_tcga_pfs_coxph_neoplastic <- coxph(Surv(PFI_Time, PFI) ~ neoplastic_ratio+gleason_score, 
                                           data = SurvData_tcga_pfs)

tiff(filename = './figures/survival_wsi/pfs/neoplastic_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_neoplastic)
dev.off()

######################
# stroma_ratio
Fit_sig_tcga_pfs_coxph_stroma <- coxph(Surv(PFI_Time, PFI) ~ stromal_ratio+gleason_score, 
                                       data = SurvData_tcga_pfs)

tiff(filename = './figures/survival_wsi/pfs/stromal_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_stroma)
dev.off()

######################
# immune_ratio
Fit_sig_tcga_pfs_coxph_immune <- coxph(Surv(PFI_Time, PFI) ~ inflammatory_ratio+gleason_score, 
                                       data = SurvData_tcga_pfs)

tiff(filename = './figures/survival_wsi/pfs/immune_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_immune)
dev.off()

######################
# necrotic_ratio
Fit_sig_tcga_pfs_coxph_necrotic <- coxph(Surv(PFI_Time, PFI) ~ necrotic_ratio+gleason_score, 
                                         data = SurvData_tcga_pfs)

tiff(filename = './figures/survival_wsi/pfs/necrotic_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_necrotic)
dev.off()

######################
# benign epithelial
Fit_sig_tcga_pfs_coxph_benign_epithelial <- coxph(Surv(PFI_Time, PFI) ~ benign_epithelial_ratio+gleason_score, 
                                                  data = SurvData_tcga_pfs)

tiff(filename = './figures/survival_wsi/pfs/benign_epithelial_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_benign_epithelial)
dev.off()


######################
# stroma to neoplastic ratio
Fit_sig_tcga_pfs_coxph_stroma_neoplastic <- coxph(Surv(PFI_Time, PFI) ~ stroma_neoplastic_ratio+gleason_score, 
                                                  data = SurvData_tcga_pfs)

tiff(filename = './figures/survival_wsi/pfs/stroma_neoplastic_ratio_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_stroma_neoplastic)
dev.off()


###################################
# with all cell ratios and gleason
Fit_sig_tcga_pfs_coxph_all <- coxph(Surv(PFI_Time, PFI) ~ + ERG_status + neoplastic_ratio+benign_epithelial_ratio+stromal_ratio+inflammatory_ratio+necrotic_ratio+stroma_neoplastic_ratio+gleason_score, 
                                    data = SurvData_tcga_pfs)

tiff(filename = './figures/survival_wsi/pfs/all_cox.tiff', width = 2500, height = 2500, res = 300)
ggforest(Fit_sig_tcga_pfs_coxph_all)
dev.off()


