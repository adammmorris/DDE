load('simdata.mat');
getLikelihood_scanner_2b([.2 .2 .95 1 1 1 .33 .33 1], 'scanner_2b.mat', realA1(:,1), realS2(:,1), realA2(:,1), realRe(:,1))
Fit_scanner_2b('C:\Personal\Psychology\Projects\DDE\git\Model\fMRI\Fitting_2b\simdata.mat','C:\Personal\Psychology\Projects\DDE\git\Model\fMRI\Fitting_2b\scanner_2b.mat','C:\Personal\Psychology\Projects\DDE\git\Model\fMRI\Fitting_2b', 10, 1, 1);