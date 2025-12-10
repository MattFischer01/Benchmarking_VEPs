# Benchmarking_VEPs
This project is to benchmark various varient effect predictor tools using dbNSFP database.

The scripts below were used for running dbNSFP, parsing input and output, and creating figures for the report.

1. testing_dbNSFP.sh:
This script was used to first test dbNSFP functionality, with the output logs shown in the folder test_output as an example.

2. formatting_input.sh:
This script was used to first format the input necessary to run dbNSFP.

3. running_dbNSFP.sh:
The code necessary to run dbNSFP search function with all 5 datasets.

4. evaluating_metrics.R: 
After running dbNSFP, this code was used to pull the respective scores from SIFT4G, PrimateAI, AlphaMissense, REVEL, and MetaRNN, and evaluate the performance of the tools against the datasets' "truth". The code is used to compute the accuracy, precision, recall, specificity, F1-scores, and area under the receiver operating characteristic curves (AUC). 
- The summary outputs from this script can be found under /output/dataset/

5. comparing_tools_AUC.R, comparing_timetorun.R, comparing_thresholds.R:
These scripts were used to create figures based on the metrics created in evaluating_metrics.R. 
- comparing_thresholds.R compares the accuracy, precision, recall, specificity, and F1-scores of each tool per dataset across thresholds from 0.4 to 0.9. Variants above the threshold are considered to be pathogenic, variants below are considered to be benign/neutral. This corresponds to figure 1.
- comparing_tools_AUC.R compares the tools AUCs between the 5 different datasets. This corresponds to figure 2. 
- comparing_timetorun.R compares the runtime, maximum resident set size, and the number of variants that were not evaluated by dbNSFP from the datasets using the search_dbNSFP5a function with all 5 datasets. This corresponds to figure 3. 

- The figures from these scripts can be found under /figures/
