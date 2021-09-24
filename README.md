# slim-mongodump-s3

Debian slim + mongodump + AWS CLI docker image for Kubernetes; rigged up to backup mongodb, a single database, or a single collection to an s3 bucket

[![docker pulls](https://img.shields.io/docker/pulls/recipedude/slim-mongodump-s3.svg?style=plastic)](https://cloud.docker.com/u/recipedude/repository/docker/recipedude/slim-mongodump-s3)

This docker image contains:

- Debian slim Slim
- [MongoDB Community Edition](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)

## Environment variables

### MongoDB and mongodump options

- ```MONGO_URI``` - specifies the resolvable [URI connection string](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--uri) of the MongoDB deployment
- ```MONGODUMP_DB``` - specifies a [database to backup](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--db). If you do not specify a database, [mongodump](https://docs.mongodb.com/database-tools/mongodump/#std-program-mongodump) copies all databases in this instance into the dump files.
- ```MONGODUMP_COLLECTION``` - Specifies a [collection to backup](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--collection). If you do not specify a collection, this option copies all collections in the specified database or instance to the dump files.
- ```MONGO_READPREFERENCE``` - specifies the [read preference](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--readPreference) for [mongodump](https://docs.mongodb.com/database-tools/mongodump/#std-program-mongodump). 
- ```MONGODUMP_GZIP``` - compresses the output [--gzip](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--gzip)
- ```MONGODUMP_OPLOG``` - creates a file named [oplog.bson](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--oplog) as part of the [mongodump](https://docs.mongodb.com/database-tools/mongodump/#std-program-mongodump) output. If `MONGODUMP_DB` is provided this option is ignored.
- ```MONGODUMP_OPTIONS``` - added to the [mongodump](https://docs.mongodb.com/database-tools/mongodump/#std-program-mongodump) command line allowing you to pass in arbitrary arguments according to your use-case
- ```MONGODUMP_ARCHIVE``` - output to an [archive file](https://docs.mongodb.com/database-tools/mongodump/#output-to-an-archive-file) see: [Archiving and compression in MongoDB tools](https://www.mongodb.com/blog/post/archiving-and-compression-in-mongodb-tools)
- ```MONGODUMP_ARCHIVE_FILENAME``` - overrides the filename of the archive
- ```MONGODUMP_LABEL``` - string that is 'injected' into the archive filename - `2021-09-10_16-54-59_UTC-[LABEL]-[DB]-[COLLECTION]-ingredient_docs.archive`
- ```MONGODUMP_EXCLUDES``` - collection to exclude from the dump, multiple values are comma-separated [excludeCollection](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--excludeCollection)
- ```MONGODUMP_EXCLUDE_PREFIXES``` - string collection prefix to exclude, multiple values are comma-separated [excludeCollectionsWithPrefix](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--excludeCollectionsWithPrefix)
- ```MONGODUMP_NUM_PARALLEL``` - number of parallel connections [numParallelCollections](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--numParallelCollections)
- ```MONGODUMP_QUERY``` -  JSON as a query that optionally limits the documents included in the output of mongodump. You must also specify the --collection option. See [query](https://docs.mongodb.com/database-tools/mongodump/#std-option-mongodump.--query) for more detail.

### AWS Credentials and S3 options

Pass in the following environment variables for AWS CLI credientals.

- ```AWS_ACCESS_KEY_ID``` – Specifies an AWS access key associated with an IAM user or role.
- ```AWS_SECRET_ACCESS_KEY``` – Specifies the secret key associated with the access key. This is essentially the "password" for the access key.
- ```AWS_DEFAULT_REGION``` – Specifies the [AWS Region](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration-region) to send the request to.
- ```AWS_PROFILE```  - specifies a pre-configured AWS profile - see AWS CLI docs
- ```AWS_S3_BUCKET``` - Specifies the AWS S3 bucket
- ```AWS_S3_PATH``` - Optional path within the S3 bucket - must include `/` absolute path

For more options you can configure with environment variables refer to: [AWS Environment Variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)

### Debugging

- ```DEBUG``` - enable run.sh debugging - if this variable contains any value error handling and shell exiting will be disabled - 
              this can be useful when running via a Kubernetes job, the job errors with return code 1 and k8s has 
              deleted the pod which results in the inability to view the logs of the failed job. Enabling DEBUG prevents 
              the job from erroring when the `mongodump` or `aws s3 cp` fails but tends to preserv


## Examples

**Backup the all databases to S3 using AWS access keys**

```
docker run --name mongodump-s3 \
  -e "MONGO_URI=mongodb://user:pass@host:port"
  -e "AWS_ACCESS_KEY_ID=your_aws_access_key"
  -e "AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key"
  -e "AWS_DEFAULT_REGION=us-east-1"
  -e "AWS_S3_BUCKET=your_aws_bucket"
  recipedude/slim-mongodump-s3:latest 
```

**Backup all databases to S3 using AWS profile**

Options include:
- gzip compress the backup
- use a secondary replicaset node rather than the primary node
- use a preconfigured AWS profile for the passing of AWS credentials 
- point in time backup using --oplog

```
docker run --name mongodump-s3 --rm \
  -e "AWS_PROFILE=self" \
  -e "AWS_S3_BUCKET=rl.mongodb" \
  -e "MONGO_READPREFERENCE=secondary" \
  -e "MONGO_URI=mongodb://host1:27017,host2:27017,host3:27017" \
  -e "MONGODUMP_GZIP=true" \
  -e "MONGODUMP_OPLOG=true" \
  --mount type=bind,source=/Users/username/.aws,target=/root/.aws \
  recipedude/slim-mongodump-s3:latest 
```

Output will look as thus:

```
Running mongodump
Backup name: 2021-09-10_16-38-36_UTC.tar
Fri Sep 10 16:38:36 UTC 2021
2021-09-10T16:38:37.039+0000	writing admin.system.version to dump/admin/system.version.bson.gz
2021-09-10T16:38:37.043+0000	done dumping admin.system.version (1 document)
2021-09-10T16:38:37.046+0000	writing recipes.recipe_docs to dump/recipes/recipe_docs.bson.gz
2021-09-10T16:38:37.069+0000	writing recipes.ingredient_docs to dump/recipes/ingredient_docs.bson.gz
2021-09-10T16:38:37.069+0000	writing recipes.search_word_docs to dump/recipes/search_word_docs.bson.gz
2021-09-10T16:38:37.071+0000	writing recipes.recipe_stat_docs to dump/recipes/recipe_stat_docs.bson.gz
2021-09-10T16:38:38.000+0000	done dumping recipes.search_word_docs (36309 documents)
2021-09-10T16:38:39.902+0000	done dumping recipes.recipe_stat_docs (53206 documents)
2021-09-10T16:38:39.972+0000	[........................]      recipes.recipe_docs  1489/55955   (2.7%)
2021-09-10T16:38:39.972+0000	[#####...................]  recipes.ingredient_docs    896/3786  (23.7%)
2021-09-10T16:38:39.972+0000
2021-09-10T16:38:42.972+0000	[#.......................]      recipes.recipe_docs  4509/55955   (8.1%)
2021-09-10T16:38:42.972+0000	[##################......]  recipes.ingredient_docs   2985/3786  (78.8%)
2021-09-10T16:38:42.972+0000
2021-09-10T16:38:45.144+0000	[########################]  recipes.ingredient_docs  3786/3786  (100.0%)
2021-09-10T16:38:45.144+0000	done dumping recipes.ingredient_docs (3786 documents)
2021-09-10T16:38:45.972+0000	[###.....................]  recipes.recipe_docs  7199/55955  (12.9%)
2021-09-10T16:38:48.973+0000	[####....................]  recipes.recipe_docs  10339/55955  (18.5%)
2021-09-10T16:38:51.972+0000	[#####...................]  recipes.recipe_docs  13437/55955  (24.0%)
2021-09-10T16:38:54.972+0000	[######..................]  recipes.recipe_docs  16238/55955  (29.0%)
2021-09-10T16:38:57.973+0000	[########................]  recipes.recipe_docs  19234/55955  (34.4%)
2021-09-10T16:39:00.972+0000	[#########...............]  recipes.recipe_docs  22638/55955  (40.5%)
2021-09-10T16:39:03.972+0000	[##########..............]  recipes.recipe_docs  25480/55955  (45.5%)
2021-09-10T16:39:06.972+0000	[############............]  recipes.recipe_docs  28339/55955  (50.6%)
2021-09-10T16:39:09.950+0000	[#############...........]  recipes.recipe_docs  31556/55955  (56.4%)
2021-09-10T16:39:12.950+0000	[##############..........]  recipes.recipe_docs  34627/55955  (61.9%)
2021-09-10T16:39:15.950+0000	[################........]  recipes.recipe_docs  38003/55955  (67.9%)
2021-09-10T16:39:18.950+0000	[#################.......]  recipes.recipe_docs  41007/55955  (73.3%)
2021-09-10T16:39:21.950+0000	[##################......]  recipes.recipe_docs  44280/55955  (79.1%)
2021-09-10T16:39:24.950+0000	[####################....]  recipes.recipe_docs  47319/55955  (84.6%)
2021-09-10T16:39:27.950+0000	[#####################...]  recipes.recipe_docs  50490/55955  (90.2%)
2021-09-10T16:39:30.950+0000	[######################..]  recipes.recipe_docs  52910/55955  (94.6%)
2021-09-10T16:39:33.451+0000	[########################]  recipes.recipe_docs  55955/55955  (100.0%)
2021-09-10T16:39:33.451+0000	done dumping recipes.recipe_docs (55955 documents)
2021-09-10T16:39:33.453+0000	writing captured oplog to
2021-09-10T16:39:33.455+0000		dumped 22 oplog entries
Fri Sep 10 16:39:33 UTC 2021
tar -cvzf "2021-09-10_16-38-36_UTC.tar" dump
dump/
dump/recipes/
dump/recipes/ingredient_docs.metadata.json.gz
dump/recipes/ingredient_docs.bson.gz
dump/recipes/recipe_stat_docs.metadata.json.gz
dump/recipes/recipe_docs.bson.gz
dump/recipes/search_word_docs.bson.gz
dump/recipes/recipe_docs.metadata.json.gz
dump/recipes/search_word_docs.metadata.json.gz
dump/recipes/recipe_stat_docs.bson.gz
dump/admin/
dump/admin/system.version.metadata.json.gz
dump/admin/system.version.bson.gz
dump/oplog.bson
Fri Sep 10 16:39:43 UTC 2021
S3 object: s3://rl.mongodb/2021-09-10_16-38-36_UTC.tar
Running: aws s3 cp "2021-09-10_16-38-36_UTC.tar" "s3://rl.mongodb/2021-09-10_16-38-36_UTC.tar"
upload: ./2021-09-10_16-38-36_UTC.tar to s3://rl.mongodb/2021-09-10_16-38-36_UTC.tar
finished
Fri Sep 10 16:39:53 UTC 2021
```

**Archive all databases to S3 using AWS profile**

Options include:
- gzip compress the backup
- use a secondary replicaset node rather than the primary node
- use a preconfigured AWS profile for the passing of AWS credentials 
- point in time backup using --oplog
- archive backup (backs up collection in parallel to archive format)

```
docker run --name mongodump-s3 --rm \
  -e "AWS_PROFILE=self" \
  -e "AWS_S3_BUCKET=rl.mongodb" \
  -e "MONGO_READPREFERENCE=secondary" \
  -e "MONGO_URI=mongodb://host1:27017,host2:27017,host3:27017" \
  -e "MONGODUMP_GZIP=true" \
  -e "MONGODUMP_OPLOG=true" \
  -e "MONGODUMP_ARCHIVE=true"
  --mount type=bind,source=/Users/username/.aws,target=/root/.aws \
  recipedude/slim-mongodump-s3:latest 
```

Output will look as thus:

```
Running mongodump
Backup name: 2021-09-10_16-45-39_UTC.archive
Fri Sep 10 16:45:39 UTC 2021
2021-09-10T16:45:39.828+0000	writing admin.system.version to archive '2021-09-10_16-45-39_UTC.archive'
2021-09-10T16:45:39.833+0000	done dumping admin.system.version (1 document)
2021-09-10T16:45:39.837+0000	writing recipes.recipe_docs to archive '2021-09-10_16-45-39_UTC.archive'
2021-09-10T16:45:39.851+0000	writing recipes.ingredient_docs to archive '2021-09-10_16-45-39_UTC.archive'
2021-09-10T16:45:39.851+0000	writing recipes.search_word_docs to archive '2021-09-10_16-45-39_UTC.archive'
2021-09-10T16:45:39.851+0000	writing recipes.recipe_stat_docs to archive '2021-09-10_16-45-39_UTC.archive'
2021-09-10T16:45:40.831+0000	done dumping recipes.search_word_docs (36309 documents)
2021-09-10T16:45:42.785+0000	[........................]       recipes.recipe_docs   1852/55955   (3.3%)
2021-09-10T16:45:42.786+0000	[########................]   recipes.ingredient_docs    1361/3786  (35.9%)
2021-09-10T16:45:42.786+0000	[################........]  recipes.recipe_stat_docs  35879/53206  (67.4%)
2021-09-10T16:45:42.786+0000
2021-09-10T16:45:44.392+0000	[########################]  recipes.recipe_stat_docs  53206/53206  (100.0%)
2021-09-10T16:45:45.786+0000	[#.......................]      recipes.recipe_docs  3600/55955   (6.4%)
2021-09-10T16:45:45.786+0000	[##################......]  recipes.ingredient_docs   2985/3786  (78.8%)
2021-09-10T16:45:45.786+0000
2021-09-10T16:45:47.240+0000	done dumping recipes.recipe_stat_docs (53206 documents)
2021-09-10T16:45:47.933+0000	[########################]  recipes.ingredient_docs  3786/3786  (100.0%)
2021-09-10T16:45:48.785+0000	[##......................]  recipes.recipe_docs  6195/55955  (11.1%)
2021-09-10T16:45:49.317+0000	done dumping recipes.ingredient_docs (3786 documents)
2021-09-10T16:45:51.786+0000	[###.....................]  recipes.recipe_docs  8869/55955  (15.9%)
2021-09-10T16:45:54.785+0000	[####....................]  recipes.recipe_docs  11651/55955  (20.8%)
2021-09-10T16:45:57.786+0000	[######..................]  recipes.recipe_docs  15217/55955  (27.2%)
2021-09-10T16:46:00.786+0000	[########................]  recipes.recipe_docs  18896/55955  (33.8%)
2021-09-10T16:46:03.785+0000	[#########...............]  recipes.recipe_docs  21745/55955  (38.9%)
2021-09-10T16:46:06.786+0000	[##########..............]  recipes.recipe_docs  25385/55955  (45.4%)
2021-09-10T16:46:09.763+0000	[############............]  recipes.recipe_docs  28135/55955  (50.3%)
2021-09-10T16:46:12.763+0000	[#############...........]  recipes.recipe_docs  30963/55955  (55.3%)
2021-09-10T16:46:15.763+0000	[##############..........]  recipes.recipe_docs  34530/55955  (61.7%)
2021-09-10T16:46:18.763+0000	[################........]  recipes.recipe_docs  37369/55955  (66.8%)
2021-09-10T16:46:21.763+0000	[#################.......]  recipes.recipe_docs  40917/55955  (73.1%)
2021-09-10T16:46:24.763+0000	[##################......]  recipes.recipe_docs  43723/55955  (78.1%)
2021-09-10T16:46:27.763+0000	[####################....]  recipes.recipe_docs  47223/55955  (84.4%)
2021-09-10T16:46:30.764+0000	[#####################...]  recipes.recipe_docs  49676/55955  (88.8%)
2021-09-10T16:46:33.764+0000	[######################..]  recipes.recipe_docs  52434/55955  (93.7%)
2021-09-10T16:46:36.763+0000	[#######################.]  recipes.recipe_docs  55068/55955  (98.4%)
2021-09-10T16:46:36.885+0000	[########################]  recipes.recipe_docs  55955/55955  (100.0%)
2021-09-10T16:46:37.179+0000	done dumping recipes.recipe_docs (55955 documents)
2021-09-10T16:46:37.182+0000	writing captured oplog to
2021-09-10T16:46:37.191+0000		dumped 58 oplog entries
Fri Sep 10 16:46:37 UTC 2021
Fri Sep 10 16:46:37 UTC 2021
S3 object: s3://rl.mongodb/2021-09-10_16-45-39_UTC.archive
Running: aws s3 cp "2021-09-10_16-45-39_UTC.archive" "s3://rl.mongodb/2021-09-10_16-45-39_UTC.archive"
upload: ./2021-09-10_16-45-39_UTC.archive to s3://rl.mongodb/2021-09-10_16-45-39_UTC.archive
finished
Fri Sep 10 16:46:49 UTC 2021
```


**Archive a single collection to S3 using AWS profile**

Options include:
- backup a single collection from the specified database
- gzip compress the backup
- use a secondary replicaset node rather than the primary node
- use a preconfigured AWS profile for the passing of AWS credentials 
- point in time backup using --oplog
- archive backup (backs up to archive format)

```
docker run --name mongodump-s3 --rm \
  -e "AWS_PROFILE=self" \
  -e "AWS_S3_BUCKET=rl.mongodb" \
  -e "MONGO_READPREFERENCE=secondary" \
  -e "MONGO_URI=mongodb://host1:27017,host2:27017,host3:27017" \
  -e "MONGODUMP_GZIP=true" \
  -e "MONGODUMP_OPLOG=true" \
  -e "MONGODUMP_ARCHIVE=true" \
  -e "MONGODUMP_DB=recipes" \
  -e "MONGODUMP_COLLECTION=ingedient_docs" \
  --mount type=bind,source=/Users/username/.aws,target=/root/.aws \
  recipedude/slim-mongodump-s3:latest 
```

Output will look as thus:

```
Running mongodump
Backup name: 2021-09-10_16-54-59_UTC-recipes-ingredient_docs.archive
Fri Sep 10 16:54:59 UTC 2021
2021-09-10T16:54:59.660+0000	writing recipes.ingredient_docs to archive '2021-09-10_16-54-59_UTC-recipes-ingredient_docs.archive'
2021-09-10T16:55:02.622+0000	[##################......]  recipes.ingredient_docs  2985/3786  (78.8%)
2021-09-10T16:55:04.209+0000	[########################]  recipes.ingredient_docs  3786/3786  (100.0%)
2021-09-10T16:55:04.693+0000	done dumping recipes.ingredient_docs (3786 documents)
Fri Sep 10 16:55:04 UTC 2021
Fri Sep 10 16:55:04 UTC 2021
S3 object: s3://rl.mongodb/2021-09-10_16-54-59_UTC-recipes-ingredient_docs.archive
Running: aws s3 cp "2021-09-10_16-54-59_UTC-recipes-ingredient_docs.archive" "s3://rl.mongodb/2021-09-10_16-54-59_UTC-recipes-ingredient_docs.archive"
upload: ./2021-09-10_16-54-59_UTC-recipes-ingredient_docs.archive to s3://rl.mongodb/2021-09-10_16-54-59_UTC-recipes-ingredient_docs.archive
finished
Fri Sep 10 16:55:08 UTC 2021
```
