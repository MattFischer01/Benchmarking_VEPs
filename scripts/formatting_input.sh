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
##"chr pos ref alt refaa altaa"

#For this input format, I will need to extract fields 3,4,5,6 from my csv files, separated by commas, my input will be tab deliminated.
mkdir ~/vep_project/testing_sets/dbnsfp_format

#This files are formatted in hg19 formatting


#File 1: ExoVar, Deleterious Variants: 5156, Neutral Variants: 3694
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6, $13, $14}' ~/vep_project/testing_sets/exovar_filtered_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/exovar_filtered_tool_scores.tsv


#File 2: HumVar, Deleterious Variants: 21090, Neutral Variants: 19299
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6, $13, $14}' ~/vep_project/testing_sets/humvar_filtered_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/humvar_filtered_tool_scores.tsv


#File 3: predictSNPSelected, Deleterious Variants: 10000, Neutral Variants: 6098, total: 16098. This file has 34 alternate coding regions (chrHG299_PATCH or chrHSCHR6_MHC_COX) that I will removem leaving 16066 snps.
awk 'BEGIN {FS=","} {
    if ($3 !~ /^chrH/)
        print $0
}' ~/vep_project/testing_sets/predictSNP_selected_tool_scores.csv > ~/vep_project/testing_sets/predictSNP_selected_tool_scores_V2.csv


awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6, $13, $14}' ~/vep_project/testing_sets/predictSNP_selected_tool_scores_V2.csv > ~/vep_project/testing_sets/dbnsfp_format/predictSNP_selected_tool_scores.tsv

#further formatting: removing chr from column 1 and changing MT to M
sed -E 's/^chr([0-9]+)\t/\1\t/; s/^chrMT\t/M\t/; s/^chrX\t/X\t/; s/^chrY\t/Y\t/' ~/vep_project/testing_sets/dbnsfp_format/predictSNP_selected_tool_scores.tsv > ~/vep_project/testing_sets/dbnsfp_format/predictSNP_selected_tool_scores_V2.tsv


#File 4: SwissVarSelected, Deleterious Variants: 4526, Neutral Variants: 8203, total 12,729. This file has 369 alternate coding regions (chrHG299_PATCH or chrHSCHR6_MHC_COX) that I will remove, leaving 12360 snps.
awk 'BEGIN {FS=","} {
    if ($3 !~ /^chrH/)
        print $0
}' ~/vep_project/testing_sets/swissvar_selected_tool_scores.csv > ~/vep_project/testing_sets/swissvar_selected_tool_scores_V2.csv

awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6, $13, $14}' ~/vep_project/testing_sets/swissvar_selected_tool_scores_V2.csv > ~/vep_project/testing_sets/dbnsfp_format/swissvar_selected_tool_scores.tsv

#further formatting: removing chr from column 1 and changing MT to M
sed -E 's/^chr([0-9]+)\t/\1\t/; s/^chrMT\t/M\t/; s/^chrX\t/X\t/; s/^chrY\t/Y\t/' ~/vep_project/testing_sets/dbnsfp_format/swissvar_selected_tool_scores.tsv > ~/vep_project/testing_sets/dbnsfp_format/swissvar_selected_tool_scores_V2.tsv


#File 5: VariBenchSelected, Deleterious Variants: 4309, Neutral Variants: 5957
awk -F',' 'NR > 1 {OFS="\t"; print $3, $4, $5, $6, $13, $14}' ~/vep_project/testing_sets/varibench_selected_tool_scores.csv > ~/vep_project/testing_sets/dbnsfp_format/varibench_selected_tool_scores.tsv

