#import dplyr package to modify the columns
library(dplyr)

#read all 4 datasets filenames we downloaded from stackexchange
stack_exchange_files <- list.files(pattern = 'stack_.*csv')

#read the data present in those 4 datasets
stack_exchange_data <- lapply(stack_exchange_files,read.csv)

#remove commas(,) in body and title columns
stack_exchange_data <- lapply(stack_exchange_data,function (x) mutate(x,Body=gsub(","," ",Body),Title=gsub(","," ",Title)))

#remove html tags from body and title columns
stack_exchange_data <- lapply(stack_exchange_data,function (x) mutate(x,Body=gsub("<.*?>"," ",Body),Title=gsub("<.*?>"," ",Title)))

#remove \t \r \n from body and title columns
stack_exchange_data <- lapply(stack_exchange_data,function (x) mutate(x,Body=gsub("\\t*\\r*\\n*\\s+"," ",Body),Title=gsub("\\t*\\r*\\n*\\s+"," ",Title)))

#finally merge all 4 datasets and export to csv format
write.csv(bind_rows(stack_exchange_data),"stack_exchange_final.csv",na="",row.names=FALSE)