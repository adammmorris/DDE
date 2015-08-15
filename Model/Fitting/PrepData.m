[Opt1,Opt2] = convertOptNumToOptions(OptNum);

% Convert S2 to 2:4 instead of 1:5
S2(S2==1 | S2==3) = 2;
S2(S2==2 | S2==4) = 3;
S2(S2==5) = 4;

% Convert Action2 to 1:2 instead of 1:6
Action2 = mod(Action2,2);
Action2(Action2==0) = 2;