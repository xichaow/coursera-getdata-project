

# Create a directory in which to store the downloaded and processed data
data.dir = path.expand("~/data/school/2015/courera-getdata-project/data")
dir.create(data.dir, recursive=T)
setwd(data.dir)

# Download and extract the raw data
url = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
zipfile = paste(data.dir, "UCI-HAR-Dataset.zip", sep="/")
download.file(url, zipfile, method="curl")
unzip(zipfile)

# The data files are now in:
# ./UCI HAR Dataset
# ./UCI HAR Dataset/activity_labels.txt
# ./UCI HAR Dataset/features.txt
# ./UCI HAR Dataset/features_info.txt
# ./UCI HAR Dataset/README.txt
# ./UCI HAR Dataset/test
# ./UCI HAR Dataset/test/Inertial Signals
# ./UCI HAR Dataset/test/Inertial Signals/body_acc_x_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/body_acc_y_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/body_acc_z_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/body_gyro_x_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/body_gyro_y_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/body_gyro_z_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/total_acc_x_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/total_acc_y_test.txt
# ./UCI HAR Dataset/test/Inertial Signals/total_acc_z_test.txt
# ./UCI HAR Dataset/test/subject_test.txt
# ./UCI HAR Dataset/test/X_test.txt
# ./UCI HAR Dataset/test/y_test.txt
# ./UCI HAR Dataset/train
# ./UCI HAR Dataset/train/Inertial Signals
# ./UCI HAR Dataset/train/Inertial Signals/body_acc_x_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/body_acc_y_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/body_acc_z_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/body_gyro_x_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/body_gyro_y_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/body_gyro_z_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/total_acc_x_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/total_acc_y_train.txt
# ./UCI HAR Dataset/train/Inertial Signals/total_acc_z_train.txt
# ./UCI HAR Dataset/train/subject_train.txt
# ./UCI HAR Dataset/train/X_train.txt
# ./UCI HAR Dataset/train/y_train.txt

# Description of the dataset
# http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

# Sizes of test and train sets: 10299 observations, matches the description on the web page
# $ wc -l UCI\ HAR\ Dataset/train/*.txt
# 7352 UCI HAR Dataset/train/X_train.txt
# 7352 UCI HAR Dataset/train/subject_train.txt
# 7352 UCI HAR Dataset/train/y_train.txt
# 22056 total
# $ wc -l UCI\ HAR\ Dataset/test/*.txt
# 2947 UCI HAR Dataset/test/X_test.txt
# 2947 UCI HAR Dataset/test/subject_test.txt
# 2947 UCI HAR Dataset/test/y_test.txt
# 8841 total

# install.packages("dplyr")
library(dplyr)

# 1. Merge the training and the test sets to create one data set

# An Exploration of how to read and combine test data

# read test data
xtest = read.table("./UCI HAR Dataset/test/X_test.txt")
head(xtest)
summary(xtest)
str(xtest)
ytest = read.table("./UCI HAR Dataset/test/y_test.txt")
head(ytest)
str(ytest)
subjecttest = read.table("./UCI HAR Dataset/test/subject_test.txt")
head(subjecttest)
str(subjecttest)
table(subjecttest)

# check that the same number of observations exist.
nrow(xtest) == nrow(ytest)
nrow(xtest) == nrow(subjecttest)

# create a test data set
testset = xtest

# merge the subject column into the test data set
testset = mutate(testset, subject = as.integer(subjecttest$V1))
summary(testset)
str(testset$subject)
head(testset)

# merge the activity label column into the test data set
test.activityf = factor(ytest$V1, levels=activity.labels$V1, labels=activity.labels$V2)
# sanity check
table(test.activityf)
table(ytest$V1)
testset = mutate(testset, activity = test.activityf)
summary(testset)

# read and combine training data

# Read in observed variables, activity, and subject for each observation
# Return a data frame with the combined data
read.dataset <- function(xfilename, yfilename, subjectfilename) {
  df = read.table(xfilename) # observed variables per observation
  y.df = read.table(yfilename) # activity label per observation
  subject.df = read.table(subjectfilename) # subject per observation

  # add the subject column to the data set
  df = mutate(df, subject = subject.df$V1)
  
  # add the activity column to the data set
  df = mutate(df, activity = y.df$V1)
}

trainset = read.dataset("./UCI HAR Dataset/train/X_train.txt", 
                        "./UCI HAR Dataset/train/y_train.txt",
                        "./UCI HAR Dataset/train/subject_train.txt")
str(trainset)
summary(trainset)
table(trainset$subject)

testset = read.dataset("./UCI HAR Dataset/test/X_test.txt", 
                        "./UCI HAR Dataset/test/y_test.txt",
                        "./UCI HAR Dataset/test/subject_test.txt")
str(testset)
summary(testset)
table(testset$subject)

# merge the train and test sets into a single data set

data = rbind(testset, trainset)
summary(data)

# 2. Extracts only the measurements on the mean and standard deviation for each measurement. 

# The file `features_info.txt` explains that for each measurement the mean and standard deviation
# was calculated (along with other statistics) and labeled with mean(), std(), or meanFreq().

# Read the feature labels
feature.labels = read.table("./UCI HAR Dataset/features.txt")
feature.labels = mutate(feature.labels, varname=paste0("V", V1))
feature.labels

# Select only feature labels that contain mean or std (case insensitive) AND are not angle measurements
filtered.feature.labels = filter(feature.labels, grepl('(mean|std)', V2, ignore.case=T) & !grepl('^angle\\(', V2))
filtered.feature.labels
vars = c(filtered.feature.labels$varname, c("subject", "activity"))
vars
data2 = select(data, one_of(vars))
names(data2)
summary(data2)

# 3. Use descriptive activity names to name the activities in the data set

# Read the activity labels
activity.labels = read.table("./UCI HAR Dataset/activity_labels.txt")
activity.labels

# transform the activity column into a factor
activityf = factor(data2$activity, levels=activity.labels$V1, labels=activity.labels$V2)
str(activityf)
summary(activityf)
# add the activity column to the data set
data3 = mutate(data2, activity = activityf)
summary(data3)

# 4. Appropriately label the data set with descriptive variable names.

# Replace the default variable names for the observed variables, e.g. "V1" and "V2", with the
# descriptive names from features.txt, e.g. "tBodyAcc-mean()-X" and "tBodyAcc-mean()-Y".
library(data.table)
oldnames = filtered.feature.labels$varname
oldnames
newnames = as.character(filtered.feature.labels$V2)
newnames
setnames(data3, old=oldnames, new=newnames)
names(data3)

# Save the time window observations table to a file.
write.table(data3, file="HAR-timewindow.txt", row.name=FALSE)
df = read.table("HAR-timewindow.txt", header=TRUE)
dim(df)
head(df)
names(df)

# 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

library(reshape2)
# group by subject and activity
data.melt = melt(data3, id=c("subject", "activity"), measure.vars=newnames)
head(data.melt)
# take mean of each variable within each group
mean.data = dcast(data.melt, subject + activity ~ variable, mean)

# transform the variable names to reflect that they are now the mean of measurements for
# each subject and activity
oldnames = names(mean.data)[3:length(names(mean.data))]
oldnames
newnames = as.character(sapply(oldnames, function(n) paste0("subject-activity-mean-", n)))
newnames
setnames(mean.data, old=oldnames, new=newnames)
# look at the first 3 subjects
head(mean.data, n=18)

# Write the mean across time windows of each variable within each subject-activity group to a file.
write.table(mean.data, file="HAR-subject-activity-mean.txt", row.name=FALSE)
# Example of how to read the table
df = read.table("HAR-subject-activity-mean.txt", header=TRUE)
dim(df)
head(df)
names(df)

for(name in names(mean.data)) { print(name) }
