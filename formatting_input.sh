#The code below is to format the testing sets for the correct input into dbNSFP.
#dbNSFP allows many different formats:
##"chr pos"
##"chr pos ref alt"
##"chr pos ref alt refAA altAA"
##Ensembl:ENST00000252835:M1K
##UNIPROT:Q9NVI1:S512A
##HGVSc:ENST00000335137:c.43G>C 
##HGVSp:ENSP00000334393:p.E15X 
##HGVSp:Q8NH21:p.Gln17* 
##HGVSp:A0A2U3U0J3_HUMAN:p.Met1?
##rsid
##MT-ND1 
##Ensembl:ENSG00000198763 
##Ensembl:ENST00000361624 
##Ensembl:ENSP00000354876 
##Uniprot:NU5M_HUMAN 
##Uniprot:P00846 
##Entrez:4541 

#The format for my test datasets will be:
##"chr pos ref alt"

#For this input format, I will need to extract fields 3,4,5,6 from my csv files, separated by commas, my input will be tab deliminated.
mkdir ~/vep_project/testing_sets/dbnsfp_format


#File 1:
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6}' ~/vep_project/testing_sets/exovar_filtered_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/exovar_filtered_tool_scores.tsv

#File 1:
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6}' ~/vep_project/testing_sets/exovar_filtered_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/exovar_filtered_tool_scores.tsv

#File 1:
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6}' ~/vep_project/testing_sets/exovar_filtered_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/exovar_filtered_tool_scores.tsv

#File 1:
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6}' ~/vep_project/testing_sets/exovar_filtered_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/exovar_filtered_tool_scores.tsv

#File 1:
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6}' ~/vep_project/testing_sets/exovar_filtered_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/exovar_filtered_tool_scores.tsv


#When running the dbNSFP code, I will only need the first 150 columns, which will contain all the predictions available from this tool.