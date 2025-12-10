install.packages("ggplot2")
install.packages("dplyr")
install.packages("tidyr")
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
                     dataset, '/metrics_at_threshold_0.6_', dataset, '.csv')
  
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


# Create faceted bar plot
ggplot(combined_df, aes(x = tool, y = auc, fill = tool)) +
  geom_bar(stat = "identity", alpha = 1) +
  facet_wrap(~ dataset, nrow = 1) +
  labs(title = "AUC Comparison Across Datasets and Tools",
       x = "Tool",
       y = "AUC") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        strip.text = element_text(size = 12, face = "bold"),
        panel.grid.major.y = element_line(color = "gray80"),
        panel.grid.minor = element_blank(),
        legend.position = "none") +
  ylim(0, 1) +
  #fill with more muted colors
  scale_fill_manual(values = c("SIFT4G" = "#c55959", "REVEL" = "royalblue", "PrimateAI" = "seagreen", "MetaRNN" = "mediumpurple", "AlphaMissense" = "#f6ae56"))


# Save the plot
ggsave('/home/mfischer10/vep_project/Benchmarking_VEPs/output/auc_comparison_faceted.png',
       plot = last_plot(), width = 12, height = 4, dpi = 300)

# Display the plot
print(last_plot())

# Print summary statistics
cat("\nSummary statistics:\n")
#which dataset had the highest auc?

summary_stats <- combined_df %>%
  group_by(dataset, tool) %>%
  summarise(mean_auc = mean(auc, na.rm = TRUE), .groups = 'drop')
print(summary_stats)

# Which dataset had the highest overall AUC?
cat("\nOverall AUC by dataset (averaged across all tools):\n")
dataset_auc <- combined_df %>%
  group_by(dataset) %>%
  summarise(overall_auc = mean(auc, na.rm = TRUE), .groups = 'drop') %>%
  arrange(desc(overall_auc))
print(dataset_auc)

cat("\nDataset with highest overall AUC:", dataset_auc$dataset[1], "with AUC =", round(dataset_auc$overall_auc[1], 4), "\n")

# Which tool had the highest overall AUC across all datasets?
cat("\nOverall AUC by tool (averaged across all datasets):\n")
tool_auc <- combined_df %>%
  group_by(tool) %>%
  summarise(overall_auc = mean(auc, na.rm = TRUE), .groups = 'drop') %>%
  arrange(desc(overall_auc))
print(tool_auc)

cat("\nTool with highest overall AUC:", as.character(tool_auc$tool[1]), "with AUC =", round(tool_auc$overall_auc[1], 4), "\n")

# Write summary to file
summary_file <- '/home/mfischer10/vep_project/Benchmarking_VEPs/output/auc_comparison_summary.txt'
sink(summary_file)

cat("AUC COMPARISON SUMMARY\n")
cat("======================\n\n")

cat("Summary Statistics by Dataset and Tool:\n")
cat("----------------------------------------\n")
print(summary_stats)

cat("\n\nOverall AUC by Dataset (averaged across all tools):\n")
cat("----------------------------------------------------\n")
print(dataset_auc)
cat("\nDataset with highest overall AUC:", dataset_auc$dataset[1], "with AUC =", round(dataset_auc$overall_auc[1], 4), "\n")

cat("\n\nOverall AUC by Tool (averaged across all datasets):\n")
cat("----------------------------------------------------\n")
print(tool_auc)
cat("\nTool with highest overall AUC:", as.character(tool_auc$tool[1]), "with AUC =", round(tool_auc$overall_auc[1], 4), "\n")

cat("\n\nGenerated on:", as.character(Sys.time()), "\n")

sink()

cat("\nSummary written to:", summary_file, "\n")
