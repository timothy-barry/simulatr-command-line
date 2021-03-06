#!/bin/bash
# NAME
#   run_simulation
# SYNOPSIS
#   run_simulation -f simulatr_obj_fp.rds -r result_directory -b n_replicates
# DESCRIPTION
#   This bash script runs a simulation using the simulatr package.
# Arguments
#   Specify arguments using the -f, -r, and -B (or -b) flags; the -r and -B
#   arguments are optional, while the -f argument is required.
#   -f: file path to simulatr_specifier object.
#   -r: directory in which to store the results
#   -B: replace "B" in the simulatr_specifier object with this value; generally,
#    "B" corresponds to the number of simulation replicates for each parameter
#     setting. Setting B to a small number allows the user to test out the
#     simulation study on a small number of replicates.

# Set code directory of nextflow and bin scripts.
code_dir=$(dirname $0)

printf "\n***********************************\n"
echo Running simulation in background...
printf "***********************************\n\n"
printf "Check simulatr.log to monitor progress. Stop execution via \"kill \$(cat .nextflow.pid)\".\n"
# echo Executable located at $code_dir/run_simulation.sh

# Get command line args.
while getopts ":f:r:B:b:" flag; do
  case $flag in
    f) sim_obj_fp="$OPTARG";;
    B) B="$OPTARG";;
    b) B="$OPTARG";;
    r) result_fp="$OPTARG";;
    \?) exit "Invalid option -$OPTARG; available arguments are -f, -B, and -r.";;
  esac
done

# Print the arguments for user.
printf "\nSupplied arguments:\n"
echo "-f (path to simulatr_specifier object): "$sim_obj_fp
echo "-B (number of simulation replicates): "$B
echo "-r (result file): "$result_fp
printf "\n"

# Check if -f has been supplied; if not, exit.
if [ -z "$sim_obj_fp" ]
then
  echo "ERROR: You must supply an argument to -f."
  exit 1
fi


# If result_fp is missing, set to directory of simulatr_specifier object.
if [ -z "$result_fp" ]
then
  base_result_name="result.rds"
  result_dir=$(dirname "${sim_obj_fp}")
else
  base_result_name=$(basename "${result_fp}")
  result_dir=$(dirname "${result_fp}")
fi

# If B is missing, set to 0.
if [ -z "$B" ]
then
  B="0"
fi

# Remove trace if it exists
rm -f $PWD/"trace.txt"

# Obtain the metaparam_file and save to .metaparams.txt.
metaparam_file=$PWD/".metaparams.txt"
Rscript $code_dir"/bin/get_meta_params.R" $sim_obj_fp $metaparam_file $B

# run nextflow script
nextflow $code_dir/"simulatr.nf" --sim_obj_fp $sim_obj_fp --metaparam_file $metaparam_file --B $B --result_dir $result_dir --base_result_name $base_result_name -bg > $PWD/simulatr.log -ansi-log false -with-trace
