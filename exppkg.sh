#!/bin/sh

################################################################################
#
#	exppkg
#
#	A tool to export packages from Oracle Database 
#
#	This tool has been tested in Oracle Database 7 to 11g to give immediately
#       loadable package header and body
#
#	Known issues:
#	- exported wrapped source could not be loaded back to the DB; extra new
#	  lines should be removed every 4000 characters
#
#
#   Version	Date		Modified by	Descriptions
#  --------------------------------------------------------------------------
#   1.0.0	20081217	Kane Lai	First release
#   1.0.1	20090110	Kane Lai	Reversed the order of the input
#                                               parameters
#                                               Fixed bugs
#   1.0.2	20090113	Kane Lai	Simplified script
#   1.0.3	20090319	Kane Lai	Fixed a bug when the name of pkg
#						contains a dollar sign
#						Minor changes
#   1.0.4	20120207	Kane Lai	Fixed problem of exporting
#						source code in wrong order
#
################################################################################


version="1.0.4"

if [ $# -lt 2 ]; then
	echo "exppkg v$version - A tool to export packages from Oracle Database"
	echo "Exported package header and body will be named (package_name)_header.sql and (package_name)_body.sql in the current directory"
	echo "Usage:	`basename $0` [db_conn_str package_name]"
	echo "    \"db_conn_str\": Oracle Database connection string to be passed to sqlplus, e.g. admin/mypassword@ora10g"
	echo "    \"package_name\": Oracle package name, which is case in-sensitive, e.g. pkg_paygo"
	exit 1
fi

db_conn_str=$1
is_conn_str_ok=`echo $db_conn_str | grep -ic /`
if [ $is_conn_str_ok -ne 1 ]; then
	echo "Oracle Database connection string must be of the format \"username/password[@connect_identifier]\""
	exit 1
fi

# change package name to upper case
pkg_name="`echo $2 | tr "[:lower:]" "[:upper:]"`"

# get the lower case package name
pkg_name_lower="`echo $pkg_name | tr "[:upper:]" "[:lower:]"`"
pkg_header=`echo $pkg_name_lower"_header.sql" | tr '[$]' '[_]'`
pkg_body=`echo $pkg_name_lower"_body.sql" | tr '[$]' '[_]'`

# execute SQL script
sqlplus -SL $db_conn_str << EOSQL >> /dev/null
set echo off
set maxdata 60000
set long 50000
set longchunksize 1000
set pages 0 lines 32767
set heading off
set verify off
set termout off
set feedback off
set trims on
set scan off
set timing off
spool $pkg_header
prompt create or replace
select TEXT from user_source where TYPE='PACKAGE' and NAME='$pkg_name' order by LINE;
prompt /
prompt show err
spool off
spool $pkg_body
prompt create or replace
select TEXT from user_source where TYPE='PACKAGE BODY' and NAME='$pkg_name' order by LINE;
prompt /
prompt show err
spool off
exit
EOSQL

# confirm the export of package header was successful
is_header_ok=`grep -ic $pkg_name $pkg_header`
is_body_ok=`grep -ic $pkg_name $pkg_body`
if [ $is_header_ok -lt 1 ]; then
	echo "Failed to export package \"$pkg_name\", probably because the package does not exist or is inaccessible"
	rm $pkg_header $pkg_body
	exit 1
fi

# confirm the export of package body was successful
if [ $is_body_ok -lt 1 ]; then
	echo "No package body was found for \"$pkg_name\""
	rm $pkg_body
fi

# export successful
echo "Package \"$pkg_name\" exported successfully"
 
