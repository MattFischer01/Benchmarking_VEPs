library(ggplot2)
library(dplyr)

# Define datasets in the desired order
datasets <- c('humvar_filtered', 'predictSNP_selected', 'swissvar_selected', 'varibench_selected', 'exovar_filtered')

# Optional: provide missing SNP counts (not found in db) either via CSV or manual vector.
# 1) CSV option: set `missing_file` to a CSV with columns: dataset, missing_snps
# 2) Manual option: fill the named vector below; leave NA for unknown.
missing_file <- ""  # e.g., "/home/mfischer10/vep_project/Benchmarking_VEPs/output/missing_snps.csv"
manual_missing <- c(
  humvar = 451,
  predictSNP = 141,
  swissvar = 386,
  varibench = 59,
  exovar = 66
)

# Read time log files and extract elapsed time and memory
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
  
  if (file.exists(filepath)) {
    # Read the file
    lines <- readLines(filepath)
    
    # Find the line with elapsed time
    elapsed_line <- grep("Elapsed \\(wall clock\\) time", lines, value = TRUE)
    # Find the line with max resident set size
    rss_line <- grep("Maximum resident set size \\(kbytes\\)", lines, value = TRUE)
    
    if (length(elapsed_line) > 0) {
      # Extract time string (e.g., "25:59.95" or "1:25:59.95")
      time_string <- sub(".*time \\(h:mm:ss or m:ss\\): ([0-9:]+\\.[0-9]+).*", "\\1", elapsed_line)
      
      # Convert to seconds
      time_parts <- strsplit(time_string, ":")[[1]]
      if (length(time_parts) == 2) {
        # Format: mm:ss.ss
        elapsed_seconds <- as.numeric(time_parts[1]) * 60 + as.numeric(time_parts[2])
      } else if (length(time_parts) == 3) {
        # Format: h:mm:ss.ss
        elapsed_seconds <- as.numeric(time_parts[1]) * 3600 + 
                          as.numeric(time_parts[2]) * 60 + 
                          as.numeric(time_parts[3])
      }
      
      max_rss_kb <- NA_real_
      if (length(rss_line) > 0) {
        max_rss_kb <- as.numeric(sub(".*: ([0-9]+).*", "\\1", rss_line))
      }

      time_data <- rbind(time_data, data.frame(
        dataset = dataset,
        elapsed_seconds = elapsed_seconds,
        elapsed_minutes = elapsed_seconds / 60,
        max_rss_kb = max_rss_kb,
        max_rss_gb = max_rss_kb / (1024 * 1024),
        missing_snps = NA_real_
      ))
    }
  } else {
    warning(paste("File not found:", filepath))
  }
}

time_data$dataset = c("humvar", "predictSNP", "swissvar", "varibench", "exovar")
datasets <- c('humvar', 'predictSNP', 'swissvar', 'varibench', 'exovar')
# Set factor levels to maintain order
time_data$dataset <- factor(time_data$dataset, levels = datasets)

# Attach missing SNP counts (CSV overrides manual vector)
if (nzchar(missing_file) && file.exists(missing_file)) {
  missing_df <- read.csv(missing_file, stringsAsFactors = FALSE)
  if (!all(c("dataset", "missing_snps") %in% names(missing_df))) {
    stop("missing_snps CSV must have columns: dataset, missing_snps")
  }
  missing_df$dataset <- factor(missing_df$dataset, levels = datasets)
  time_data <- time_data %>% select(-missing_snps) %>% left_join(missing_df, by = "dataset")
} else {
  # use manual vector where provided
  manual_df <- data.frame(dataset = factor(names(manual_missing), levels = datasets),
                          missing_snps = as.numeric(manual_missing))
  time_data <- time_data %>% select(-missing_snps) %>% left_join(manual_df, by = "dataset")
}

# Runtime plot
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

# Max resident set size plot (GB)
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

# Missing SNPs plot (if available)
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

# Save the plot
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/dbnsfp_runtime_comparison.png',
    plot = p_time, width = 8, height = 6, dpi = 300)
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/dbnsfp_maxrss_comparison.png',
    plot = p_rss, width = 8, height = 6, dpi = 300)
if (missing_available) {
  ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/dbnsfp_missing_snps.png',
    plot = p_missing, width = 8, height = 6, dpi = 300)
}

# Display the plot
print(p_time)
print(p_rss)
if (missing_available) print(p_missing)

# Print summary
cat("\ndbNSFP Runtime Summary:\n")
cat("=======================\n\n")
print(time_data)

cat("\nTotal runtime across all datasets:", round(sum(time_data$elapsed_minutes), 2), "minutes\n")
cat("Average runtime per dataset:", round(mean(time_data$elapsed_minutes), 2), "minutes\n")
cat("\nDataset with longest runtime:", as.character(time_data$dataset[which.max(time_data$elapsed_minutes)]), 
    "with", round(max(time_data$elapsed_minutes), 2), "minutes\n")
cat("\nDataset with highest max RSS:", as.character(time_data$dataset[which.max(time_data$max_rss_gb)]),
  "with", round(max(time_data$max_rss_gb, na.rm = TRUE), 2), "GB\n")
if (missing_available) {
  cat("\nDataset with most missing SNPs:", as.character(time_data$dataset[which.max(time_data$missing_snps)]),
    "with", format(max(time_data$missing_snps, na.rm = TRUE), big.mark = ","), "missing SNPs\n")
}