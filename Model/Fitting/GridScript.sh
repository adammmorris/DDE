#!/usr/local/bin/bash

/gpfs/main/sys/shared/psfu/local/projects/matlab/R2013b/bin/matlab -nodisplay -nosplash -nodesktop -r "addpath '/home/amm4/git/DDE/Model/Fitting'; Fit_null('/home/amm4/git/DDE/Model/Fitting/v6/NGLagents/SimData.mat','/home/amm4/git/DDE/Model/Fitting/board_daw_fit.mat','/home/amm4/git/DDE/Model/Fitting/v6/NGLagents/SubjFits_null',25,0,$SGE_TASK_ID);exit;"
