#I want to focus on certain columns at the moment, 1-9, 27-32, 60-62, 66-71, 78-83, 107-109, 114-115, 122-124
#Here i will focus on the rank score for each score, from 0 to 1. A rank score of 0.9 means the top 10% most damaging. I will consider anything 70% or greater as pathogenic (in which the truth is 1) and anything less than 70% as benign (in which the truth is -1). I will first determine how many missingness is there for each model between the variants. 

install.packages("dplyr")
install.packages("data.table")

library(dplyr)
library(data.table)

# name this dataset (change this to run the script for another dataset)
dataset_name <- "varibench"   # e.g. "dataset", "dataset2", "dataset3", ...

# convenience paths that use dataset_name
scores_in <- file.path("/home/mfischer10/vep_project/testing_sets/dbnsfp_format/output",
                       paste0(dataset_name, "_selected_tool_scores.out"))
truth_in  <- file.path("/home/mfischer10/vep_project/testing_sets",
                       paste0(dataset_name, "_selected_tool_scores.csv"))
out_dir   <- paste0("/home/mfischer10/vep_project/Benchmarking_VEPs/output/", dataset_name)

# read files using dataset_name
dataset <- fread(scores_in, sep = '\t', header = TRUE, na.strings = ".") %>%
  select(1:9,27:32,60:62,66:71,78:83,107:109,114:115,122:124)

# find columns whose names end with "rankscore"
rank_cols <- grep("rankscore$", names(dataset), value = TRUE)

# replace "." with NA and convert to numeric for those columns
dataset <- dataset %>% mutate(across(all_of(rank_cols), as.numeric))


# compute missing counts and percentages
missing_counts <- sapply(dataset[ , ..rank_cols, drop = FALSE], function(x) sum(is.na(x)))
missing_pct <- round(missing_counts / nrow(dataset) * 100, 2)

missing_summary <- data.frame(
  vep_model = names(missing_counts),
  missing = as.integer(missing_counts),
  total = nrow(dataset),
  pct_missing = as.numeric(missing_pct),
  row.names = NULL
)

# print sorted by most missing
missing_summary <- missing_summary[order(-missing_summary$missing), ]
print(missing_summary)

fwrite(missing_summary,
          file = file.path(out_dir, paste0("missingness_summary_", dataset_name, ".tsv")),
          row.names = FALSE, sep = "\t")

truth <- fread(truth_in, sep = ',', header = TRUE) %>% select(1,3,4,5 ,6)



colnames(dataset)
colnames(truth) <- c("truth", "hg19_chr", "hg19_pos(1-based)", "ref", "alt")

#truth$hg19_chr <- sub("^chr", "", as.character(truth$hg19_chr), ignore.case = TRUE)

dataset_truth <- dataset %>% inner_join(truth, by = c("hg19_chr", "hg19_pos(1-based)", "ref", "alt"))

# View the first few rows of the merged data frame
head(dataset_truth)

# check merged size and truth contents
nrow(dataset_truth)
str(dataset_truth$truth)
table(dataset_truth$truth, useNA = "ifany")

# how many non-missing scores per rank column
rank_cols_in_merged <- intersect(rank_cols, names(dataset_truth))
sapply(rank_cols_in_merged, function(col) sum(!is.na(dataset_truth[[col]])))


# -----------------------------
# Threshold sweep for rankscore columns
# -----------------------------
if (!requireNamespace("pROC", quietly = TRUE)) install.packages("pROC")
library(pROC)

# thresholds to test (customize as needed)
thresholds <- seq(0.4, 0.9, by = 0.1)

# rankscore columns present in the merged data
rank_cols_in_merged <- intersect(rank_cols, names(dataset_truth))

safe_metrics <- function(y_true_raw, y_score, thr) {
  # map truth: pathogenic (1) -> 1, benign (-1) -> 0
  y_true <- ifelse(as.numeric(y_true_raw) == 1, 1, 0)
  keep <- !is.na(y_score) & !is.na(y_true)
  n <- sum(keep)
  if (n == 0) return(rep(NA, 8))  # was rep(NA, 9)
  y_score <- as.numeric(y_score[keep])
  y_true <- y_true[keep]
  # predictions at threshold thr
  y_pred <- ifelse(y_score >= thr, 1, 0)
  TP <- sum(y_pred == 1 & y_true == 1)
  TN <- sum(y_pred == 0 & y_true == 0)
  FP <- sum(y_pred == 1 & y_true == 0)
  FN <- sum(y_pred == 0 & y_true == 1)
  accuracy <- if ((TP+TN+FP+FN) > 0) (TP + TN) / (TP + TN + FP + FN) else NA
  sensitivity <- if ((TP + FN) > 0) TP / (TP + FN) else NA
  specificity <- if ((TN + FP) > 0) TN / (TN + FP) else NA
  precision <- if ((TP + FP) > 0) TP / (TP + FP) else NA
  f1 <- if (!is.na(precision) & !is.na(sensitivity) & (precision + sensitivity) > 0) 2 * precision * sensitivity / (precision + sensitivity) else NA
  # safer MCC: coerce to numeric (double) to avoid integer overflow and guard NA
  TPn <- as.numeric(TP); TNn <- as.numeric(TN); FPn <- as.numeric(FP); FNn <- as.numeric(FN)
  mcc_denom <- tryCatch(sqrt((TPn + FPn) * (TPn + FNn) * (TNn + FPn) * (TNn + FNn)), error = function(e) NA_real_)
  mcc <- if (!is.na(mcc_denom) && mcc_denom > 0) (TPn * TNn - FPn * FNn) / mcc_denom else NA_real_
  # AUC computed on full scores (independent of thr) if both classes present
  auc_val <- NA
  if (length(unique(y_true)) > 1) {
    roc_obj <- tryCatch(roc(y_true, y_score, quiet = TRUE), error = function(e) NULL)
    if (!is.null(roc_obj)) auc_val <- as.numeric(auc(roc_obj))
  }
  c(n = n, accuracy = accuracy, sensitivity = sensitivity,
    specificity = specificity, precision = precision, f1 = f1,
    mcc = mcc, auc = auc_val)
}

# build results: one row per (column, threshold)
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

metrics_df <- do.call(rbind, results)
# reorder columns nicely
metrics_df <- metrics_df[, c("column","threshold","n","accuracy","sensitivity","specificity","precision","f1","mcc","auc")]

# Save full sweep (include dataset_name)
out_csv <- file.path(out_dir, paste0("rankscore_metrics_threshold_sweep_", dataset_name, ".csv"))
write.csv(metrics_df, out_csv, row.names = FALSE)
message("Threshold sweep saved to: ", out_csv)

# Optionally: pick best threshold per column by maximizing MCC (or other metric)
best_by_mcc <- metrics_df %>%
  group_by(column) %>%
  slice_max(order_by = mcc, n = 1, with_ties = FALSE) %>%
  arrange(desc(mcc))

best_out <- file.path(out_dir, paste0("best_thresholds_by_mcc_", dataset_name, ".csv"))
write.csv(as.data.frame(best_by_mcc), best_out, row.names = FALSE)
message("Best thresholds (by MCC) saved to: ", best_out)


metrics_thrs <- metrics_df %>% filter(dplyr::near(threshold, 0.6)) %>%
  arrange(desc(auc))

# write only the threshold-0.6 rows out
best_out <- file.path(out_dir, paste0("metrics_at_threshold_0.6_", dataset_name, ".csv"))
write.csv(as.data.frame(metrics_thrs), best_out, row.names = FALSE)
message("Metrics at threshold 0.6 saved to: ", best_out)


# ---- Prepare per-dataset/per-model AUCs and plot results ----
# After you run the threshold sweep for each dataset you can produce one AUC per model
# (AUC is independent of threshold so we take the max non-NA AUC from the sweep).
# Set dataset_name for this run, then save per-dataset AUCs. Repeat for your 5 datasets
# and rbind the results into `all_metrics` (shown below).

library(ggplot2)

# name this dataset (change for each dataset run)
dataset_name <- "dataset"

# metrics_df is produced by the sweep above; reduce to one AUC per model
auc_per_model <- metrics_df %>%
  group_by(column) %>%
  summarize(auc = if (all(is.na(auc))) NA_real_ else max(auc, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(dataset = dataset_name)

# save this dataset's AUCs (optional)
write.csv(auc_per_model,
          file = file.path("/home/mfischer10/vep_project/Benchmarking_VEPs/output/",
                           paste0(dataset_name, "/auc_per_model_", dataset_name, ".csv")),
          row.names = FALSE)

# ---- After you have run this for all 5 datasets ----
# Read them and combine; or if you created them in-memory, just rbind them.
# Example reading saved CSVs:
dataset_files <- Sys.glob("/home/mfischer10/vep_project/Benchmarking_VEPs/output/*/auc_per_model_*.csv")

all_metrics <- do.call(rbind, lapply(dataset_files, fread))  # requires data.table::fread
# ensure columns names consistent
all_metrics <- as.data.frame(all_metrics)
colnames(all_metrics) <- c("column", "auc", "dataset")

# ---- Plot: grouped bars (dataset on x, one bar per model inside each dataset) ----
# If you have many models, consider faceting or using a color palette that supports many colors.
p <- ggplot(all_metrics, aes(x = dataset, y = auc, fill = column)) +
  geom_col(position = position_dodge2(width = 0.9, preserve = "single"), width = 0.8) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  labs(x = "Dataset", y = "AUC", fill = "VEP model",
       title = "AUC by VEP model across datasets") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1),
        legend.position = "right")

# Save and show
ggsave("/home/mfischer10/vep_project/Benchmarking_VEPs/output/auc_by_model_by_dataset_barplot.png",
       p, width = 12, height = 6, dpi = 300)
print(p)

# ---- Alternative: faceted small-multiples (one panel per model) ----
# Useful if many models and legend gets crowded. Each panel shows AUC per dataset.
p2 <- ggplot(all_metrics, aes(x = dataset, y = auc)) +
  geom_col(fill = "steelblue", width = 0.7) +
  facet_wrap(~ column, scales = "free_x", ncol = 4) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "Dataset", y = "AUC", title = "AUC per model (one panel per VEP)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("/home/mfischer10/vep_project/Benchmarking_VEPs/output/auc_by_model_facets.png",
       p2, width = 14, height = 10, dpi = 300)
print(p2)


