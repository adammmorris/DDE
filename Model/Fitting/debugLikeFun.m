%% Prep data
[Opt1,Opt2] = convertOptNumToOptions(OptNum);

% Convert S2 to 2:4 instead of 1:5
S2_fit = S2;
S2_fit(S2_fit==1 | S2_fit==3) = 2;
S2_fit(S2_fit==2 | S2_fit==4) = 3;
S2_fit(S2_fit==5) = 4;

% Convert Action2 to 1:2 instead of 1:6
Action2_fit = mod(Action2,2);
Action2_fit(Action2_fit==0) = 2;

index = 1:250;
boardpath = 'C:\Personal\Psychology\Projects\DDE\git\Model\Fitting\board_daw_fit.mat';

getLikelihood_daw([.5 .5 1 .5 .5],boardpath,Opt1(index),Opt2(index),Action(index),S2_fit(index),Action2_fit(index),Re(index),round1(index))