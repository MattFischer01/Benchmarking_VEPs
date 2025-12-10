#This code is to report time to run datasets, the max RSS for each dataset run, and the number of snps that were not located in dbNSFP

library(ggplot2)
library(dplyr)

#datasets
datasets <- c('humvar_filtered', 'predictSNP_selected', 'swissvar_selected', 'varibench_selected', 'exovar_filtered')

#the number of missing variants per dataset 
missing_var <- c(
  humvar = 451,
  predictSNP = 141,
  swissvar = 386,
  varibench = 59,
  exovar = 66
)

#read time log files and extract elapsed time and memory
time_data <- data.frame(
  dataset = character(),
  elapsed_seconds = numeric(),
  elapsed_minutes = numeric(),
  max_rss_kb = numeric(),
  max_rss_gb = numeric(),
  missing_snps = numeric(),
  stringsAsFactors = FALSE
)

for (dataset in datasets) {
  filepath <- paste0('/home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/',
                     dataset, '_tool_scores.time.log')
  
  lines <- readLines(filepath)
  
  #find elaspsed time 
  elapsed_line <- grep("Elapsed \\(wall clock\\) time", lines, value = TRUE)
  #find maximum resident set size
  rss_line <- grep("Maximum resident set size \\(kbytes\\)", lines, value = TRUE)
  
  #extract time string
  time_string <- sub(".*time \\(h:mm:ss or m:ss\\): ([0-9:]+\\.[0-9]+).*", "\\1", elapsed_line)
  
  # Convert to seconds
  time_parts <- strsplit(time_string, ":")[[1]]
  if (length(time_parts) == 2) {
    #format: mm:ss.ss
    elapsed_seconds <- as.numeric(time_parts[1]) * 60 + as.numeric(time_parts[2])
  } else if (length(time_parts) == 3) {
    #format: h:mm:ss.ss
    elapsed_seconds <- as.numeric(time_parts[1]) * 3600 + 
                      as.numeric(time_parts[2]) * 60 + 
                      as.numeric(time_parts[3])
  }

  max_rss_kb <- as.numeric(sub(".*: ([0-9]+).*", "\\1", rss_line))

  time_data <- rbind(time_data, data.frame(
    dataset = dataset,
    elapsed_seconds = elapsed_seconds,
    elapsed_minutes = elapsed_seconds / 60,
    max_rss_kb = max_rss_kb,
    max_rss_gb = max_rss_kb / (1024 * 1024),
    missing_snps = NA_real_
  ))
}

time_data$dataset = c("humvar", "predictSNP", "swissvar", "varibench", "exovar")
datasets <- c('humvar', 'predictSNP', 'swissvar', 'varibench', 'exovar')
time_data$dataset <- factor(time_data$dataset, levels = datasets)

manual_df <- data.frame(dataset = factor(names(missing_var), levels = datasets),
                        missing_snps = as.numeric(missing_var))
time_data <- time_data %>% select(-missing_snps) %>% left_join(manual_df, by = "dataset")

#Plot runtime 
p_time <- ggplot(time_data, aes(x = dataset, y = elapsed_minutes, fill = dataset)) +
  geom_bar(stat = "identity", alpha = 1) +
  labs(title = "dbNSFP Runtime Comparison Across Datasets",
    x = "Dataset",
    y = "Elapsed Time (minutes)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
     plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
     axis.title = element_text(size = 14, face = "bold"),
     axis.text = element_text(size = 14),
     legend.position = "none") +
  scale_fill_manual(values = c("humvar" = "#c55959", "predictSNP" = "royalblue", "swissvar" = "seagreen", "varibench" = "mediumpurple", "exovar" = "#f6ae56"))

#Plot max resident set size 
p_rss <- ggplot(time_data, aes(x = dataset, y = max_rss_gb, fill = dataset)) +
  geom_bar(stat = "identity", alpha = 1) +
  labs(title = "dbNSFP Max Resident Set Size Across Datasets",
    x = "Dataset",
    y = "Max RSS (GB)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
     plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
     axis.title = element_text(size = 14, face = "bold"),
     axis.text = element_text(size = 14),
     legend.position = "none") +
  scale_fill_manual(values = c("humvar" = "#c55959", "predictSNP" = "royalblue", "swissvar" = "seagreen", "varibench" = "mediumpurple", "exovar" = "#f6ae56"))

#plot missing varriants 
missing_available <- "missing_snps" %in% names(time_data) && any(!is.na(time_data$missing_snps))
if (missing_available) {
  p_missing <- ggplot(time_data, aes(x = dataset, y = missing_snps, fill = dataset)) +
    geom_bar(stat = "identity", alpha = 1) +
    labs(title = "Variants Not Found in dbNSFP",
         x = "Dataset",
         y = "Count of Missing SNPs") +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
          axis.title = element_text(size = 14, face = "bold"),
          axis.text = element_text(size = 14),
          legend.position = "none") +
    scale_fill_manual(values = c("humvar" = "#c55959", "predictSNP" = "royalblue", "swissvar" = "seagreen", "varibench" = "mediumpurple", "exovar" = "#f6ae56"))
}

#save plots 
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/dbnsfp_runtime_comparison.png',
    plot = p_time, width = 8, height = 6, dpi = 300)
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/dbnsfp_maxrss_comparison.png',
    plot = p_rss, width = 8, height = 6, dpi = 300)
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/dbnsfp_missing_snps.png',
    plot = p_missing, width = 8, height = 6, dpi = 300)


#summaries
cat("\nTotal runtime across all datasets:", round(sum(time_data$elapsed_minutes), 2), "minutes\n")
cat("Average runtime per dataset:", round(mean(time_data$elapsed_minutes), 2), "minutes\n")
cat("\nDataset with longest runtime:", as.character(time_data$dataset[which.max(time_data$elapsed_minutes)]), 
    "with", round(max(time_data$elapsed_minutes), 2), "minutes\n")
cat("\nDataset with highest max RSS:", as.character(time_data$dataset[which.max(time_data$max_rss_gb)]),
  "with", round(max(time_data$max_rss_gb, na.rm = TRUE), 2), "GB\n")
cat("\nDataset with most missing SNPs:", as.character(time_data$dataset[which.max(time_data$missing_snps)]),
  "with", format(max(time_data$missing_snps, na.rm = TRUE), big.mark = ","), "missing SNPs\n")