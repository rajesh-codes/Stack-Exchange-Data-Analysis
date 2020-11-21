# Stack Exchange Data Analysis
##### by Rajesh Kumar Reddy Kummetha, DCU Student Number: 20211568
In this project we are going perform some computing tasks on the data extracted from **Stack Exchange** website which is a questions & answers platform of any kind. In this project `PuTTY` software is used as an `SSH` client of Google Cloud Platform's virtual machine instance.
#### The tasks we are going to perform are:
1. Get data from Stack Exchange
2. Load them with PIG
3. Query them with Hive
4. Calculate TF-IDF with Hive

#### 1. Get data from Stack Exchange
We have to extract the data based on the view count of the posts. And also we can only download up to `50000` records at a time. So, we have to run the query several times to get required `200000` records. We can extract the data from the website [http://data.stackexchange.com/stackoverflow/query/new](http://data.stackexchange.com/stackoverflow/query/new) using below quries.

The query for first set of `50000` records goes like:
```sql
select * from posts where viewcount >= 111930
```
Similarly queries for 2nd, 3rd and 4th set of data will be the following respectively.

```sql
select * from posts where viewcount < 111930 and viewcount >= 65887
select * from posts where viewcount < 65887 and viewcount >= 47039
select * from posts where viewcount < 47039 and viewcount >= 36590
```
The same queries are mentioned in the `data_fetch.sql` file in the project. 
##### Cleaning the data using `R` language:
As the raw data is not ready for analysis, we have to remove `comma(,)`, `\n`, `\r`, `\t` from body, title, tags columns as they make the data messy and complex to perform analysis. After cleaning the data all 4 datasets are merged. The `R` script to perform cleaning & merging is:
````R
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
````
The final exported file consisting total stack exchange data is uploaded to Google Cloud Platform for analysis. The `stack_exchange_final.csv` file is copied to `HDFS` using the below command.
````
hdfs dfs -put /input/stack_exchange_final.csv /home/rajesh.kumar.reddy.kummetha/stack_exchange_final.csv
````
#### 2. Load them with PIG
Now, as the file is ready, we can load the data to PIG using the below script. We used default `piggybank.jar` which contains `CSVExcelStorage()` function to load the `csv` file into PIG.
````pig
register '/usr/lib/pig/piggybank.jar';
define CSVExcelStorage org.apache.pig.piggybank.storage.CSVExcelStorage();

-- Read full data set from hdfs
raw_data = load '/input/stack_exchange_final.csv' using CSVExcelStorage(',', 'YES_MULTILINE','NOCHANGE','SKIP_INPUT_HEADER') AS (Id:int, PostTypeId:int,  AcceptedAnswerId:int, ParentId:int, CreationDate:chararray, DeletionDate:chararray, Score:int, ViewCount:int, Body:chararray, OwnerUserId:int, OwnerDisplayName:chararray, LastEditorUserId:int, LastEditorDisplayName:chararray, LastEditDate:chararray, LastActivityDate:chararray, Title:chararray, Tags:chararray, AnswerCount:int, CommentCount:int, FavoriteCount:int, ClosedDate:chararray, CommunityOwnedDate:chararray, ContentLicense:chararray);

-- avoid unnecessary columns and also remove commas(,) from body, title and tags columns
required_data = foreach raw_data generate  Id as Id, Score as Score, REPLACE(Body,',*','') as Body, OwnerUserId as OwnerUserId, REPLACE(Title,',*','') as Title, REPLACE(Tags,',*','') as Tags;

-- Remove the columns containing null as we may get null owneruserid if we execute in hive.
cleaned_data = filter required_data by (OwnerUserId is not null) and (Score is not null);

-- store cleaned_data to HDFS
store cleaned_data into '/output/cleaned_data' using CSVExcelStorage(',');
````
After the execution of this script, the data is stored into HDFS. This script is included in the `pig_script.pig` file in the project. The above script is executed using the below command.
````
pig -x mapreduce pig_script.pig
````

#### 3. Query them with Hive
We have to enter into the hive query execution environment in order to execute any query using the below command.
````
sudo hive
````
After that the data which is present in the HDFS is loaded into the hive table `data` and found answers for several questions using below queries.
````sql
-- create new table
create table data (Id int, Score int, Body String, OwnerUserId Int, Title String, Tags String) row format delimited FIELDS TERMINATED BY ',';

-- load the data into data table from hdfs which was written by pig
load data inpath '/output/cleaned_data/' into table data;

-- Question 1: The top 10 posts by score
select id, title, score from data order by score desc limit 10;

-- Question 2: The top 10 users by post score
select owneruserid, sum(score) as OverallScore from data group by OwnerUserId order by OverallScore desc limit 10;

-- Question 3: The number of distinct users, who used the word "hadoop" in one of their posts
select count (distinct owneruserid) from data where (lower(body) like '%hadoop%' or lower(title) like '%hadoop%' or lower(tags) like '%hadoop%');
````
The queries performed are included in the `hive_queries.sql` file in the project.
#### 4 Calculate TF-IDF with Hive
TF-IDF (term frequency–inverse document frequency) is a numerical statistic that is intended to reflect how important a word is to a document in a collection (source: [Wikipedia tf-idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)). We used `hivemall` in order to compute TF-IDF per-user. The documentation for `hivemall` can be found at [TF-IDF Term Weighting Hivemall User Manual](https://hivemall.incubator.apache.org/userguide/ft_engineering/tfidf.html) and [TFIDF Calculation](https://github.com/myui/hivemall/wiki/TFIDF-calculation). The information how to include `hivemall` in hive can be found at [Hivemall Installation](https://github.com/myui/hivemall/wiki/Installation). Below `hivemall` queries are executed to perform TF-IDF.

````
-- Question 4: Using Hive calculate the per-user TF-IDF (just submit the top 10 terms for each of the top 10 users from Question 2)

add jar /home/rajesh.kumar.reddy.kummetha/hivemall-core-0.4.2-rc.2-with-dependencies.jar;
source /home/rajesh.kumar.reddy.kummetha/define-all.hive;

create temporary macro max2(x INT, y INT) if(x>y,x,y);

create temporary macro tfidf(tf FLOAT, df_t INT, n_docs INT) tf * (log(10, CAST(n_docs as FLOAT)/max2(1,df_t)) + 1.0);

create table topUsers as select ownerUserId, Title,score from data order by Score desc limit 10;

create or replace view topUsersExplode as select ownerUserId, eachword from topUsers LATERAL VIEW explode(tokenize(Title, True)) t as eachword where not is_stopword(eachword);

create or replace view tf_temp as select ownerUserid, eachword, freq from (select ownerUserId, tf(eachword) as word2freq from topUsersExplode group by ownerUserId) t LATERAL VIEW explode(word2freq) t2 as eachword, freq;

create or replace view tf as select * from (select ownerUserId, eachword, freq, rank() over (partition by ownerUserId order by freq desc) as rank from tf_temp ) t where rank < 10;

select * from tf;
````
The above queries are included in the `tfidf.sql` file in the project.
#

> All screenshots of above all code executions are included in the `screenshots` folder in the project.