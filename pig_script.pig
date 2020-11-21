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