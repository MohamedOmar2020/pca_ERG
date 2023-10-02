filter_paths_TCGA <- function(status, bm_name){
  # status = F
  # bm_name= "pten"
  
  
  # bm_json_path <- sprintf("/Users/mohamedomar/Documents/Research/Projects/pca_outcome/hovernet/output/%s/pos/pannuke/json", bm_name)
  # wt_json_path <- sprintf("/Users/mohamedomar/Documents/Research/Projects/pca_outcome/hovernet/output/%s/neg/pannuke/json", bm_name)
  # 
  bm_json_path <- sprintf("hovernet_topPatches/output/%s/TCGA/fusion/json", bm_name)
  wt_json_path <- sprintf("hovernet_topPatches/output/%s/TCGA/wt/json", bm_name)
  
  
  print(sprintf("Reading from paths %s and %s", bm_json_path, wt_json_path))
  # biomarker = T
  # status = T
  json_path <- ifelse(status == T, bm_json_path, wt_json_path)
  
  json_file_paths_all  <- list.files(json_path, pattern = ".json")
  
  # length(json_file_paths_all)
  # json_file_paths <- sample(x = unlist(json_file_paths_all),size = 500, replace = FALSE)
  # print(length(json_file_paths))
  
  
  json_dat_list <- list()
  
  # for (j in 1:10){
  for (j in 1:length(json_file_paths_all)){
    
    path <- json_file_paths_all[[j]]
    json_raw <- read_json(paste0(json_path,"/",path))
    json_dat_list[[j]] <- list()
    json_dat_list[[j]]$json <- json_raw
    json_dat_list[[j]]$nuc <- json_raw$nuc
    json_dat_list[[j]]$path <- path
    json_dat_list[[j]]$full_path <- paste0(json_path,"/",path)
    
  }
  
  a <- unlist(lapply(json_dat_list, function(x) length(x$nuc)))
  without_data = which(a==0)
  paths_without_data <- unlist(lapply(json_dat_list[without_data], function(x) x$path))
  
  json_file_paths_filt <- json_file_paths_all[!(json_file_paths_all %in% paths_without_data)]
  
  final_paths <- paste0(json_path,"/", json_file_paths_filt)
  length(unique(json_file_paths_filt))
  length(unique(json_file_paths_all))
  print(sprintf('there were %s files with no nuc data',length(unique(paths_without_data))))
  print(sprintf('there were %s files with  nuc data',length(unique(final_paths))))
  # b <- json_dat_list[[13]]
  
  return(final_paths)
}


# gen_count_df_pten <- function(status, bm_name){
gen_count_df_ERG_TCGA <- function(json_file_paths_filt,status,bm_name){
  
  # status = F  
  # bm_name= "pten"
  # 
  
  # bm_json_path <- sprintf("/Users/mohamedomar/Documents/Research/Projects/pca_outcome/hovernet/output/%s/pos/pannuke/json", bm_name)
  # wt_json_path <- sprintf("/Users/mohamedomar/Documents/Research/Projects/pca_outcome/hovernet/output/%s/neg/pannuke/json", bm_name)
  # 
  # bm_json_path <- sprintf("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/hovernet/output/%s/pos/pannuke/json", bm_name)
  # wt_json_path <- sprintf("/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/hovernet/output/%s/neg/pannuke/json", bm_name)
  # 
  # 
  # print(sprintf("Reading from paths %s and %s", bm_json_path, wt_json_path))
  # # biomarker = T
  # # status = T
  # json_path <- ifelse(status == T, bm_json_path, wt_json_path)
  # 
  # json_file_paths_all  <- list.files(json_path, pattern = ".json")
  
  # length(json_file_paths_all)
  
  # json_file_paths_filt <- neg_paths
  json_file_paths <- sample(x = unlist(json_file_paths_filt),size = 100, replace = FALSE)
  print(length(json_file_paths))
  
  
  json_dat_list <- list()
  
  # for (j in 1:10){
  for (j in 1:length(json_file_paths)){
    # j <- 1
    path <- json_file_paths[[j]]
    # json_raw <- read_json(paste0(json_path,"/",path))
    json_raw <- read_json(path)
    json_dat_list[[j]] <- list()
    json_dat_list[[j]]$json <- json_raw
    json_dat_list[[j]]$nuc <- json_raw$nuc
    # json_dat_list[[j]]$path <- path
    # json_dat_list[[j]]$full_path <- paste0(json_path,"/",path)
    
    
    # a <- unlist(lapply(json_dat_list, function(x) length(x$nuc)))
    # without_data = which(a==0)
    # paths_without_data <- unlist(lapply(json_dat_list[without_data], function(x) x$path))
    # 
    # json_file_paths_filt <- json_file_paths_all[!(json_file_paths_all %in% paths_without_data)]
    # length(unique(json_file_paths_filt))
    # length(unique(json_file_paths_all))
    # print(sprintf('there were %s files with no nuc data',length(unique(paths_without_data))))
    # # b <- json_dat_list[[13]]
    # 
    # 
    # json_file_paths <- sample(x = unlist(json_file_paths_filt),size = 500, replace = FALSE)
    # 
    # json_dat_list <- list()
    # # for (j in 1:10){
    # for (j in 1:length(json_file_paths_all)){
    #   
    #   path <- json_file_paths_all[[j]]
    #   json_raw <- read_json(paste0(json_path,"/",path))
    #   json_dat_list[[j]] <- list()
    #   json_dat_list[[j]]$json <- json_raw
    #   json_dat_list[[j]]$nuc <- json_raw$nuc
    #   json_dat_list[[j]]$path <- path
    #   json_dat_list[[j]]$full_path <- paste0(json_path,"/",path)
    #   
    # }
    # 
    # 
    # 
    # 
    #json_dat_list <- Filter(function(x) !is.na(x), json_dat_list)
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
  
  
  # print(length(json_dat_list ))
  
  
  count_list <- list()
  for (i in 1:length(json_dat_list)){
    count_list[[i]] <- json_dat_list[[i]]$nuc_vec
  }
  
  length(count_list) == length(json_dat_list)
  
  count_vec <- unlist(count_list)
  nuc_df <- data.frame(count_vec)
  
  
  flag <- ifelse(status == T, "ERG-fusion positive", "ERG-fusion negative")
  nuc_df <- nuc_df %>% 
    dplyr::mutate(flag = factor(flag, levels = c("ERG-fusion negative", "ERG-fusion positive"), labels = c("ERG-fusion negative", "ERG-fusion positive")),bm_name = bm_name)
  
  
  return(nuc_df)
}

gen_plot_df_ERG_TCGA <- function(bm_name){
  
  fusion_paths <- filter_paths_TCGA(status = T, bm_name = bm_name)
  wt_paths <- filter_paths_TCGA(status = F, bm_name = bm_name)
  
  # print(neg_paths)
  
  wt_df <- gen_count_df_ERG_TCGA(json_file_paths_filt = wt_paths, status = F,bm_name = bm_name)
  bm_df <- gen_count_df_ERG_TCGA(json_file_paths_filt = fusion_paths, status = T,bm_name = bm_name)
  
  # wt_df <- gen_count_df_pten(status = F, bm_name = bm_name)
  # bm_df <- gen_count_df_pten(status = T,bm_name = bm_name)
  
  full_df <- rbind(wt_df, bm_df)
  full_df <- full_df[!(full_df$count_vec == '0'), ]
  return(full_df)
}



gen_plot_ERG_TCGA <- function(df){
  
  # Prepare plot
  color_table <- tibble(
    count_vec = c("1","2","3","4","5"),
    Color = c("red","green","blue","yellow","#9b870c")
  )
  
  full_df <- df
  bm_name = unique(full_df$bm_name)
  
  full_agg_df <- full_df %>% count(count_vec, flag)
  full_agg_df$count_vec <- factor(full_agg_df$count_vec, levels = color_table$count_vec)
  
  p <- ggplot(full_agg_df, aes(x = count_vec, y = n, alpha = flag, fill = count_vec)) +
    geom_bar(stat = "identity",position = "dodge") + 
    scale_alpha_manual(values = c(0.4,1), guide_legend(title = sprintf("%s Status", bm_name))) + 
    scale_fill_manual("Cell Types",values = color_table$Color,labels = c("Neoplastic","Inflammatory","Connective Tissue","Necrotic","Non-neoplastic epithelial"))  +
    #ggtitle(sprintf("Cell Types, %s Fusion",bm_name)) + 
    scale_x_discrete(labels = str_wrap(c("Neoplastic","Inflammatory","Connective Tissue","Necrotic","Non-neoplastic epithelial"),width = 10)) + 
    ggplot2::theme_bw() +
    theme(axis.text.x = element_text(angle = -25, hjust = 0, vjust = 1)) + 
    # theme(legend.position = "none") +
    xlab("Cell Type") + ylab( "Count")
  
  
  return(p)
}
