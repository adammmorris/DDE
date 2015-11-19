This page contains the experiments, data, analysis script, and generative model used in Cushman & Morris (2015). Habitual control of goal selection in humans. PNAS.

Under the header "Experiments", there are four SWFs; these are the four experiments reported in the paper.
Under the header "Data & Analysis", there are four CSV files containing the critical trial data in the four experiments. The "Analysis.R" script does the analysis.
Under the header "Generative Model", there are three MATLAB scripts and a MAT data file. "generativeModel.m" contains the model outlined in the Supplementary Information. "buildEnvironment.m" builds the environment (a version of Experiment 1B) that the simulated agents experience. "environment_1B.mat" is an example of such an environment, but you could run buildEnvironment.m again and get a different environment. "getOtherAvailableAction.m" is a function that both of the other scripts call.

Please send questions or comments to cushman@fas.harvard.edu or adammorris@g.harvard.edu.