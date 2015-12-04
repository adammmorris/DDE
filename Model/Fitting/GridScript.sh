#!/usr/local/bin/bash

/gpfs/main/sys/shared/psfu/local/projects/matlab/R2013b/bin/matlab -nodisplay -nosplash -nodesktop -r "addpath '/home/amm4/git/DDE/Model/Fitting'; Fit_null('/home/amm4/git/DDE/Game/Data/dawstage2/v2/data_fitting.mat','/home/amm4/git/DDE/Model/Fitting/board_daw_fit.mat','/home/amm4/git/DDE/Model/Fitting/wouter2',25,75,$SGE_TASK_ID);exit;"
