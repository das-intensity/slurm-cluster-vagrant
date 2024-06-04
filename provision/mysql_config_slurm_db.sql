create user 'slurmdb_admin'@'localhost' identified by 'somepass';
grant all on slurmdb.* TO 'slurmdb_admin'@'localhost';
create database slurmdb;
