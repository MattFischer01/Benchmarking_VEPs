library(ggplot2)
library(dplyr)

# Define datasets in the desired order
datasets <- c('humvar_filtered', 'predictSNP_selected', 'swissvar_selected', 'varibench_selected', 'exovar_filtered')

# Read time log files and extract elapsed time
time_data <- data.frame(
  dataset = character(),
  elapsed_seconds = numeric(),
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
      
      time_data <- rbind(time_data, data.frame(
        dataset = dataset,
        elapsed_seconds = elapsed_seconds,
        elapsed_minutes = elapsed_seconds / 60
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

# Create bar plot
ggplot(time_data, aes(x = dataset, y = elapsed_minutes, fill = dataset)) +
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

# Save the plot
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/dbnsfp_runtime_comparison.png',
       plot = last_plot(), width = 8, height = 6, dpi = 300)

# Display the plot
print(p)

# Print summary
cat("\ndbNSFP Runtime Summary:\n")
cat("=======================\n\n")
print(time_data)

cat("\nTotal runtime across all datasets:", round(sum(time_data$elapsed_minutes), 2), "minutes\n")
cat("Average runtime per dataset:", round(mean(time_data$elapsed_minutes), 2), "minutes\n")
cat("\nDataset with longest runtime:", as.character(time_data$dataset[which.max(time_data$elapsed_minutes)]), 
    "with", round(max(time_data$elapsed_minutes), 2), "minutes\n")