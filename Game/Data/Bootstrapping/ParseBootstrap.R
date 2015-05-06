### ParseBootstrap.R

## Inputs: input_folder, numFiles
# input_folder should have numFiles CSV files, each w/ a single number

## Output: p value

# SET THESE
input_folder = "/home/amm4/git/DDE/Game/Data/Round 8/Take2/Bootstrapping/model_comb";
numFiles = 250;

results <- vector(mode='integer',length=numFiles);

for (i in 1:numFiles) {
	filename <- paste(input_folder,"/",i,".csv",sep="");
	if (file.exists(filename)) {
		results[i] <- read.csv(filename,head=FALSE);
	} else {
		results[i] <- NaN;
	}
}

print(mean(as.numeric(results),na.rm=TRUE))
