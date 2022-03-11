#!/bin/bash
#
# a script to generate the array of subject numbers to be allocated to sbatch processing task IDs

#project directory
project=/path/to/PROJECT

pref=`echo ${project} | cut -d/ -f3`

cd $project

#cleanup
rm tasklist.txt
rm tasks.txt

#generate list of subject folders
subslist=(./$pref*)

for SUB in "${subslist[@]}"; do

subID=${SUB:2:10}

echo $(( 10#${subID:3:3} )) >> tasklist.txt

done

awk -vORS=, '{ print $1 }' ../MBB/tasklist.txt | sed 's/,$/\n/' >> tasks.txt
