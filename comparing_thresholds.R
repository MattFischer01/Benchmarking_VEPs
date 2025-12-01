library(ggplot2)
library(dplyr)
library(tidyr)

# Define datasets and tools
datasets <- c('exovar', 'humvar', 'predictSNP', 'swissvar', 'varibench')
tools <- c('SIFT4G_converted_rankscore', 'REVEL_rankscore', 'PrimateAI_rankscore', 
           'MetaRNN_rankscore', 'AlphaMissense_rankscore')
tool_labels <- c('SIFT4G', 'REVEL', 'PrimateAI', 'MetaRNN', 'AlphaMissense')

# Read and combine data from all datasets
data_list <- list()
for (dataset in datasets) {
  filepath <- paste0('/home/mfischer10/vep_project/Benchmarking_VEPs/output/',
                     dataset, '/rankscore_metrics_threshold_sweep_', dataset, '.csv')
  
  if (file.exists(filepath)) {
    df <- read.csv(filepath, stringsAsFactors = FALSE)
    # Filter for the tools we want
    df_filtered <- df %>%
      filter(column %in% tools) %>%
      mutate(dataset = dataset,
             tool = factor(column, levels = tools, labels = tool_labels))
    data_list[[dataset]] <- df_filtered
  } else {
    warning(paste("File not found:", filepath))
  }
}

# Combine all data
combined_df <- bind_rows(data_list)

# Create faceted line plot with F1 score
ggplot(combined_df, aes(x = threshold, y = f1, color = tool, group = tool)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  facet_wrap(~ dataset, nrow = 1) +
  labs(title = "F1 Score vs Threshold Across Datasets and Tools",
       x = "Threshold",
       y = "F1 Score",
       color = "Tool") +
  theme_bw() +
  theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        strip.text = element_text(size = 14, face = "bold"),
        axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12),
        legend.position = "bottom",
        legend.title = element_text(size = 16, face = "bold"),
        legend.text = element_text(size = 14),
        panel.grid.minor = element_blank()) +
  scale_color_manual(values = c("SIFT4G" = "#c55959", 
                                 "REVEL" = "royalblue", 
                                 "PrimateAI" = "seagreen", 
                                 "MetaRNN" = "mediumpurple", 
                                 "AlphaMissense" = "#f6ae56")) +
  scale_x_continuous(breaks = seq(0.4, 0.9, by = 0.1)) +
  ylim(0, 1)

# Save the plot
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/threshold_sweep_f1_comparison.png',
       plot = last_plot(), width = 12, height = 5, dpi = 300)

# Display the plot
print(last_plot())

cat("\nPlot saved as 'threshold_sweep_f1_comparison.png'\n")

# Print summary statistics
cat("\nF1 Score summary by tool and threshold:\n")
f1_summary <- combined_df %>%
  group_by(tool, threshold) %>%
  summarise(
    mean_f1 = mean(f1, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(tool, threshold)
print(f1_summary)

# Find optimal threshold per tool (highest average F1 across datasets)
cat("\nOptimal threshold by tool (based on mean F1 across datasets):\n")
optimal_thresholds <- combined_df %>%
  group_by(tool, threshold) %>%
  summarise(mean_f1 = mean(f1, na.rm = TRUE), .groups = 'drop') %>%
  group_by(tool) %>%
  slice_max(mean_f1, n = 1) %>%
  arrange(desc(mean_f1))
print(optimal_thresholds)
