-- Question 4: Using Hive calculate the per-user TF-IDF (just submit the top 10 terms for each of the top 10 users from Question 2)

add jar /home/rajesh.kumar.reddy.kummetha/hivemall-core-0.4.2-rc.2-with-dependencies.jar;
source /home/rajesh.kumar.reddy.kummetha/define-all.hive;

create temporary macro max2(x INT, y INT) if(x>y,x,y);

create temporary macro tfidf(tf FLOAT, df_t INT, n_docs INT) tf * (log(10, CAST(n_docs as FLOAT)/max2(1,df_t)) + 1.0);

create table topUsers as select owneruserid, sum(score) as OverallScore from data group by OwnerUserId order by OverallScore desc limit 10;

create table topUsers1 as select d.OwnerUserID,title from data d join topUsers t on  d.OwnerUserID = t.OwnerUserID;

create or replace view topUsersExplode as select ownerUserId, eachword from topUsers1 LATERAL VIEW explode(tokenize(Title, True)) t as eachword where not is_stopword(eachword);

create or replace view tf_temp as select ownerUserid, eachword, freq from (select ownerUserId, tf(eachword) as word2freq from topUsersExplode group by ownerUserId) t LATERAL VIEW explode(word2freq) t2 as eachword, freq;

create or replace view tf as select * from (select ownerUserId, eachword, freq, rank() over (partition by ownerUserId order by freq desc) as rank from tf_temp ) t where rank < 10;

select owneruserid,eachword,freq from tf;