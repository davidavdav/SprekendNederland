# SprekendNederland
Tools for extracting and analyzing data from a Sprekend Nederland database dump

This package contains some tools for preparing the SQL database dump for usage in Python/SQLAlchemy.  
This allows an Object Relational Mapper (ORM) view on the database from withing python.  Further, we
have some tools to extract the data and metadata from the structured database into plain CSV tables, 
ready for import in R or other analysis tools. 

These tools assume some form of unix-like environment, a bash shell, python 2.7, R, and optionally an SQL server 
if you want to extract tables from the raw database data. 

## Install from git

```sh
git clone https://github.com/davidavdav/SprekendNederland.git
cd SprekendNederland
export PYTHONPATH=.
```

## Database and extracting the plain tables

### MySQL as database

I only have experience with MySQL as a database, I find that quite complicated as it is, thank you very much.  
I personally run MySQL in a VirtualBox Linux (Debian/GNU) Virtual Machine, but you can equally well run it on your
localhost.  

I will not discuss here how you set up and configure mysql.  This would typically involve setting up a password for a 
MySQL admin user called `root`. 

#### Preparing MySQL

```mysql
create database sn;
grant usage, select on `sn` to 'sn'@'%';
```
Beware, this gives passwordless access to the data from any host.  In a Virtual Machine this is OK, but if you run this
on your local computer, you may want to replace the `%` by `localhost`.

The next thing to do is to load the data into the database.  Assume you have received the database dump as `dump.sql`, you
need to insert the data into database, using administrator rights to do so:

```sh
cat dump.sql | bin/fix-mysql-dump.py | mysql sn -u root -p ## and type password
```
The `fix-mysql-dump.py` script changes the database engine from `MyISAM` to `InnoDB`, adds foreign key constraints to the tables, 
and removes references to unavailable tables.  This makes it possible for SALAlchemy to do its clever object relation mapping 
for us.  

Test the database with a normal user:
```sh
mysql sn -u sn -e "select id, question from questions;"
```

## Extract the metadata

```sh
bin/meta.py > meta.csv
```

## Extract the answers to all questions
```sh 
bin/answers.py > answers.csv
```

## Read in the metadata into R
```R
m <- read.csv("meta.csv", row.names="pid")
```

### Split a location-type column into longitude, lattitude and zoom-level values
```R
spl <- function(x, n) as.numeric(strsplit(as.character(x), "/")[[1]][n]) ## sorry about this
q03long <- mapply(spl, m$q03, 1)
q03lat <- mapply(spl, m$q03, 2)
```

