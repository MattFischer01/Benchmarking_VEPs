#!/bin/bash

#This script is to test the dbNSFP database search command. 

#testing
cd /home/mfischer10/vep_project/mydbNSFP/dbNSFP5.2a

/usr/bin/time -v java -cp . search_dbNSFP52a \
  -i ~/vep_project/mydbNSFP/dbNSFP5.2a/tryhg19.in \
  -o ~/vep_project/mydbNSFP/dbNSFP5.2a/tryhg19.out \
  -v hg19 -w 1-7,12-18,37-155,533-543 > ~/vep_project/mydbNSFP/dbNSFP5.2a/tryhg19.log 2> ~/vep_project/mydbNSFP/dbNSFP5.2a/tryhg19.time.log &
