#!/bin/bash

#This script is to run all 5 datasets using dbNSFP database search command. 

#Running this script: nohup /home/mfischer10/vep_project/Benchmarking_VEPs/running_dbNSFP.sh &

#Need to be in the correct path to run the program 
#cd /home/mfischer10/vep_project/mydbNSFP/dbNSFP5.2a

#exovar
/usr/bin/time -v java -cp . search_dbNSFP52a \
  -i /home/mfischer10/vep_project/testing_sets/dbnsfp_format/exovar_filtered_tool_scores.tsv \
  -o /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/exovar_filtered_tool_scores.out \
  -v hg19 \
  -w 1-9,12-18,37-155,533-543 > /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/exovar_filtered_tool_scores.log 2> /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/exovar_filtered_tool_scores.time.log &


#HumVar
/usr/bin/time -v java -cp . search_dbNSFP52a \
  -i /home/mfischer10/vep_project/testing_sets/dbnsfp_format/humvar_filtered_tool_scores.tsv \
  -o /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/humvar_filtered_tool_scores.out \
  -v hg19 \
  -w 1-9,12-18,37-155,533-543 > /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/humvar_filtered_tool_scores.log 2> /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/humvar_filtered_tool_scores.time.log &


#predictSNP
/usr/bin/time -v java -cp . search_dbNSFP52a \
  -i /home/mfischer10/vep_project/testing_sets/dbnsfp_format/predictSNP_selected_tool_scores_V2.tsv \
  -o /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/predictSNP_selected_tool_scores.out \
  -v hg19 \
  -w 1-9,12-18,37-155,533-543 > /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/predictSNP_selected_tool_scores.log 2> /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/predictSNP_selected_tool_scores.time.log &


#Swissvar
/usr/bin/time -v java -cp . search_dbNSFP52a \
  -i /home/mfischer10/vep_project/testing_sets/dbnsfp_format/swissvar_selected_tool_scores_V2.tsv \
  -o /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/swissvar_selected_tool_scores.out \
  -v hg19 \
  -w 1-9,12-18,37-155,533-543 > /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/swissvar_selected_tool_scores.log 2> /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/swissvar_selected_tool_scores.time.log &


#Varibench 
/usr/bin/time -v java -cp . search_dbNSFP52a \
  -i /home/mfischer10/vep_project/testing_sets/dbnsfp_format/varibench_selected_tool_scores.tsv \
  -o /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/varibench_selected_tool_scores.out \
  -v hg19 \
  -w 1-9,12-18,37-155,533-543 > /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/varibench_selected_tool_scores.log 2> /home/mfischer10/vep_project/testing_sets/dbnsfp_format/output/varibench_selected_tool_scores.time.log &