# Benchmarking_VEPs
This project is to benchmark various varient effect predictor tools using dbNSFP database.

To use dbNSFP, you must first register under your academic institutional email to receive an access code at https://www.dbnsfp.org/home, which will then allow you to download the database via wget. Downloading the database will also provide a Readme file (I have provided a copy: search_dbNSFP52a.readme.pdf), which discusses all possible input file formats allowed and showcases different usages and command line tags. To be able to run dbNSFP, you need to have Java installed on your machine. There are 647 columns containing a plethora of information, for clear output, it is important to pick which data you want to analyze using the -w tag.

Datasets can be downloaded from https://structure.bmc.lu.se/VariBench/data/variationtype/substitutions/test/GrimmDatasets.php using wget. 

The scripts below were used for running dbNSFP, parsing input and output, and creating figures for the report.

1. testing_dbNSFP.sh:
This script was used to first test dbNSFP functionality, with the output logs shown in the folder test_output as an example.

2. formatting_input.sh:
This script was used to first format the input necessary to run dbNSFP.

3. running_dbNSFP.sh:
The code necessary to run dbNSFP search function with all 5 datasets. I have also provided the log files from running dbNSFP for each dataset to show what the outputs should look like if you were to run the database with the code I provided, these can be found under /output/dataset/

4. evaluating_metrics.R: 
After running dbNSFP, this code was used to pull the respective scores from SIFT4G, PrimateAI, AlphaMissense, REVEL, and MetaRNN, and evaluate the performance of the tools against the datasets' "truth". The code is used to compute the accuracy, precision, recall, specificity, F1-scores, and area under the receiver operating characteristic curves (AUC). 
- The summary outputs from this script can be found under /output/dataset/

5. comparing_tools_AUC.R, comparing_timetorun.R, comparing_thresholds.R:
These scripts were used to create figures based on the metrics created in evaluating_metrics.R. 
- comparing_thresholds.R compares the accuracy, precision, recall, specificity, and F1-scores of each tool per dataset across thresholds from 0.4 to 0.9. Variants above the threshold are considered to be pathogenic, variants below are considered to be benign/neutral. This corresponds to figure 1.
- comparing_tools_AUC.R compares the tools AUCs between the 5 different datasets. This corresponds to figure 2. 
- comparing_timetorun.R compares the runtime, maximum resident set size, and the number of variants that were not evaluated by dbNSFP from the datasets using the search_dbNSFP5a function with all 5 datasets. This corresponds to figure 3. 

- The figures from these scripts can be found under /figures/
