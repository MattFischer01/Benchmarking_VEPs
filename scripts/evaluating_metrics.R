#I want to focus on certain columns at the moment, 1-9, 27-32, 60-62, 66-71, 78-83, 107-109, 114-115, 122-124
#Here i will focus on the rank score for each score, from 0 to 1. A rank score of 0.9 means the top 10% most damaging. I will evaluate metrics with thresholds from 0.4 to 0.9, anything above the threhold will be considered pathogenic and below will be considered benign. 

install.packages("dplyr")
install.packages("data.table")
if (!requireNamespace("pROC", quietly = TRUE)) install.packages("pROC")

library(dplyr)
library(data.table)
library(pROC)

#I will perform one dataset at a time 
dataset_name <- "varibench"  

#paths to the dbNSFP output, the input, and the output for this script 
scores_in <- file.path("/home/mfischer10/vep_project/testing_sets/dbnsfp_format/output",
                       paste0(dataset_name, "_selected_tool_scores.out"))
truth_in  <- file.path("/home/mfischer10/vep_project/testing_sets",
                       paste0(dataset_name, "_selected_tool_scores.csv"))
out_dir   <- paste0("/home/mfischer10/vep_project/Benchmarking_VEPs/output/", dataset_name)

#read files using dataset_name
dataset <- fread(scores_in, sep = '\t', header = TRUE, na.strings = ".") %>%
  select(1:9,27:32,60:62,66:71,78:83,107:109,114:115,122:124)

#find columns whose names end with "rankscore"
rank_cols <- grep("rankscore$", names(dataset), value = TRUE)

#replace "." with NA and convert to numeric for those columns
dataset <- dataset %>% mutate(across(all_of(rank_cols), as.numeric))

#Read in the datasets input
truth <- fread(truth_in, sep = ',', header = TRUE) %>% select(1,3,4,5 ,6)

colnames(dataset)
colnames(truth) <- c("truth", "hg19_chr", "hg19_pos(1-based)", "ref", "alt")

#truth$hg19_chr <- sub("^chr", "", as.character(truth$hg19_chr), ignore.case = TRUE)

dataset_truth <- dataset %>% inner_join(truth, by = c("hg19_chr", "hg19_pos(1-based)", "ref", "alt"))

#check the merge
head(dataset_truth)

#check merged size and truth contents
nrow(dataset_truth)
str(dataset_truth$truth)
table(dataset_truth$truth, useNA = "ifany")

###Threshold sweep for rankscore columns

#thresholds to test
thresholds <- seq(0.4, 0.9, by = 0.1)

#rankscore columns present in the merged data
rank_cols_in_merged <- intersect(rank_cols, names(dataset_truth))

safe_metrics <- function(y_true_raw, y_score, thr) {
  #converting dataset truth to scores 0 and 1: pathogenic (1) -> 1, benign (-1) -> 0
  y_true <- ifelse(as.numeric(y_true_raw) == 1, 1, 0)
  keep <- !is.na(y_score) & !is.na(y_true)
  n <- sum(keep)
  y_score <- as.numeric(y_score[keep])
  y_true <- y_true[keep]
  #predictions at threshold thr, if greater or equal to threshold, assign pathogenic, else, benign
  y_pred <- ifelse(y_score >= thr, 1, 0)
  #counting TP, TN, FP, FN
  TP <- sum(y_pred == 1 & y_true == 1)
  TN <- sum(y_pred == 0 & y_true == 0)
  FP <- sum(y_pred == 1 & y_true == 0)
  FN <- sum(y_pred == 0 & y_true == 1)
  #Evaluating metrics 
  accuracy <- (TP + TN) / (TP + TN + FP + FN) 
  sensitivity <- TP / (TP + FN) 
  specificity <- TN / (TN + FP) 
  precision <- TP / (TP + FP) 
  f1 <- (2 * precision * sensitivity) / (precision + sensitivity) 

  #calculate MCC
  TPn <- as.numeric(TP); TNn <- as.numeric(TN); FPn <- as.numeric(FP); FNn <- as.numeric(FN)
  mcc_denom <- sqrt((TPn + FPn) * (TPn + FNn) * (TNn + FPn) * (TNn + FNn))
  mcc <- (TPn * TNn - FPn * FNn) / mcc_denom

  #calculate AUC
  auc_val <- NA
  roc_obj <- roc(y_true, y_score, quiet = TRUE)
  auc_val <- as.numeric(auc(roc_obj))
  
  #Return metrics 
  c(n = n, accuracy = accuracy, sensitivity = sensitivity,
    specificity = specificity, precision = precision, f1 = f1,
    mcc = mcc, auc = auc_val)
}

#results
results <- lapply(rank_cols_in_merged, function(col) {
  scores <- dataset_truth[[col]]
  metrics_per_thr <- t(sapply(thresholds, function(thr) safe_metrics(dataset_truth$truth, scores, thr)))
  df <- as.data.frame(metrics_per_thr, stringsAsFactors = FALSE)
  df$threshold <- thresholds
  df$column <- col
  # ensure numeric
  numc <- c("n","accuracy","sensitivity","specificity","precision","f1","mcc","auc","threshold")
  df[numc] <- lapply(df[numc], as.numeric)
  # reorder
  df <- df[, c("column","threshold", numc)]
  df
})

#get all metrics 
metrics_df <- do.call(rbind, results)
#reorder columns
metrics_df <- metrics_df[, c("column","threshold","n","accuracy","sensitivity","specificity","precision","f1","mcc","auc")]

#save data 
fwrite(metrics_df, file = file.path(out_dir, paste0("rankscore_metrics_threshold_sweep_", dataset_name, ".csv")))


#what tool has the best auc?
metrics_thrs <- metrics_df %>% filter(threshold == 0.6) %>% arrange(desc(auc))

#write only the threshold-0.6 rows out
fwrite(metrics_thrs, file = file.path(out_dir, paste0("metrics_at_threshold_0.6_", dataset_name, ".csv")))


#create a concise file for auc only and write out 
auc_per_model <- metrics_df %>%
  group_by(column) %>%
  summarize(auc = max(auc, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(dataset = dataset_name)

fwrite(auc_per_model, file = file.path(out_dir, paste0("auc_per_model_", dataset_name, ".csv")))
