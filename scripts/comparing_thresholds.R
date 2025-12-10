library(ggplot2)
library(dplyr)
library(tidyr)
library(rlang)

# Define datasets and tools
datasets <- c('exovar', 'humvar', 'predictSNP', 'swissvar', 'varibench')
tools <- c('SIFT4G_converted_rankscore', 'REVEL_rankscore', 'PrimateAI_rankscore',
           'MetaRNN_rankscore', 'AlphaMissense_rankscore')
tool_labels <- c('SIFT4G', 'REVEL', 'PrimateAI', 'MetaRNN', 'AlphaMissense')
palette_tools <- c("SIFT4G" = "#c55959",
                   "REVEL" = "royalblue",
                   "PrimateAI" = "seagreen",
                   "MetaRNN" = "mediumpurple",
                   "AlphaMissense" = "#f6ae56")

metrics <- c("f1", "accuracy", "sensitivity", "precision", "specificity")
metric_titles <- c(f1 = "F1 Score",
                   accuracy = "Accuracy",
                   sensitivity = "Sensitivity",
                   precision = "Precision",
                   specificity = "Specificity")

# Read and combine data from all datasets
data_list <- list()
for (dataset in datasets) {
  filepath <- paste0('/home/mfischer10/vep_project/Benchmarking_VEPs/output/',
                     dataset, '/rankscore_metrics_threshold_sweep_', dataset, '.csv')

  if (file.exists(filepath)) {
    df <- read.csv(filepath, stringsAsFactors = FALSE)
    df_filtered <- df %>%
      filter(column %in% tools) %>%
      mutate(dataset = dataset,
             tool = factor(column, levels = tools, labels = tool_labels))
    data_list[[dataset]] <- df_filtered
  } else {
    warning(paste("File not found:", filepath))
  }
}

combined_df <- bind_rows(data_list)

# Helper to plot and save each metric
make_metric_plot <- function(metric) {
  metric_label <- metric_titles[[metric]]
  p <- ggplot(combined_df,
              aes(x = threshold, y = .data[[metric]], color = tool, group = tool)) +
    geom_line(size = 1.2) +
    geom_point(size = 2) +
    facet_wrap(~ dataset, nrow = 1) +
    labs(title = paste0(metric_label, " vs Threshold Across Datasets and Tools"),
         x = "Threshold",
         y = metric_label,
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
    scale_color_manual(values = palette_tools) +
    scale_x_continuous(breaks = seq(0.4, 0.9, by = 0.1)) +
    ylim(0, 1)

  out_file <- paste0('/home/mfischer10/vep_project/Benchmarking_VEPs/output/threshold_sweep_',
                     metric, '_comparison.png')
  ggsave(out_file, plot = p, width = 12, height = 5, dpi = 300)
  cat("\nPlot saved as '", out_file, "'\n", sep = "")
  print(p)
}

# Generate plots for all metrics
invisible(lapply(metrics, make_metric_plot))

# F1-specific summaries (kept from previous version)
cat("\nF1 Score summary by tool and threshold:\n")
f1_summary <- combined_df %>%
  group_by(tool, threshold) %>%
  summarise(mean_f1 = mean(f1, na.rm = TRUE), .groups = 'drop') %>%
  arrange(tool, threshold)
print(f1_summary)

cat("\nOptimal threshold by tool (based on mean F1 across datasets):\n")
optimal_thresholds <- combined_df %>%
  group_by(tool, threshold) %>%
  summarise(mean_f1 = mean(f1, na.rm = TRUE), .groups = 'drop') %>%
  group_by(tool) %>%
  slice_max(mean_f1, n = 1) %>%
  arrange(desc(mean_f1))
print(optimal_thresholds)
