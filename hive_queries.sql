
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