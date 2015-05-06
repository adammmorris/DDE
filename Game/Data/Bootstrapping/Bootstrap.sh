#!/usr/local/bin/bash
#$ -cwd
#PBS -e /dev/null
#PBS -o /dev/null

/home/amm4/R/R-devel/bin/Rscript ExecuteBootstrap.R "/home/amm4/git/DDE/Game/Data/Round 8/Take2/.RData" "model_comb" "/home/amm4/git/DDE/Game/Data/Round 8/Take2/Bootstrapping/model_comb" $SGE_TASK_ID
