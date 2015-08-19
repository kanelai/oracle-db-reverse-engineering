#!/bin/sh

################################################################################
#
#	exptrg
#
#	A tool to export triggers from Oracle Database 
#
#	This tool has been tested in Oracle Database 7 to give immediately loadable
#	triggers
#
#	Known issues:
#	- exported wrapped source could not be loaded back to the DB; extra new lines should be removed every 4000 characters
#
#   Version	Date		Modified by	Descriptions
#  --------------------------------------------------------------------------
#   1.0.0	20090110	Kane Lai	First release
#   1.0.1	20090113	Kane Lai	Simplified script
#   1.0.2	20090319	Kane Lai	Fixed a bug when the name of trg
#						contains a dollar sign
#   1.0.3	20090916	Kane Lai	Added trigger status support
#
################################################################################


version="1.0.3"

if [ $# -lt 2 ]; then
	echo "exptrg v$version - A tool to export triggers from Oracle Database"
	echo "Exported triggers will be named (trigger_name).sql in the current directory"
	echo "Usage:	`basename $0` [db_conn_str trigger_name]"
	echo "    \"db_conn_str\": Oracle Database connection string to be passed to sqlplus, e.g. admin/mypassword@ora10g"
	echo "    \"trigger_name\": Oracle trigger name, which is case in-sensitive, e.g. card_spending_trg"
	exit 1
fi

db_conn_str=$1
is_conn_str_ok=`echo $db_conn_str | grep -ic /`
if [ $is_conn_str_ok -ne 1 ]; then
echo "Oracle Database connection string must be of the format \"username/password[@connect_identifier]\""
        exit 1
fi

# change trigger name to upper case
trg_name="`echo $2 | tr "[:lower:]" "[:upper:]"`"

# get the lower case trigger name
trg_name_lower="`echo $trg_name | tr "[:upper:]" "[:lower:]"`"
trg=`echo trg_$trg_name_lower".sql" | tr '[$]' '[_]'`

# execute SQL script
sqlplus -SL $db_conn_str << EOSQL >> /dev/null
set echo off
set maxdata 50000
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
spool $trg
select 'create or replace trigger ' || description from user_triggers where trigger_name='$trg_name';
select 'when (' || when_clause || ')' from user_triggers where trigger_name='$trg_name' and when_clause is not null;
select trigger_body from user_triggers where trigger_name='$trg_name';
prompt /
prompt show err
prompt
select 'alter trigger $trg_name_lower ' || decode(status, 'ENABLED', 'enable', 'DISABLED', 'disable') || ';' from user_triggers where trigger_name='$trg_name';
prompt
spool off
exit
EOSQL

# confirm the export was successful
is_ok=`grep -ic $trg_name $trg`
if [ $is_ok -lt 1 ]; then
	echo "Failed to export trigger \"$trg_name\", probably because the trigger does not exist or is inaccessible"
	rm $trg
	exit 1
fi

# export successful
echo "Trigger \"$trg_name\" exported successfully"
