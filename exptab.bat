@echo off

REM ################################################################################
REM #
REM #	exptab
REM #
REM #	A tool to export table definitions from Oracle Database 
REM #
REM #
REM #   Version	Date		Modified by	Descriptions
REM #  --------------------------------------------------------------------------
REM #   1.0.0	20111216	Kane Lai	First release
REM #
REM ################################################################################


set version=1.0.0

set is_failed=0
if [%2]==[] (
	set is_failed=1
)
if not [%3]==[] (
	set is_failed=1
)

if %is_failed%==1 (
	echo exptab v%version% - A tool to export table definitions from Oracle Database
	echo Exported table definitions will be named tab_^(table_name^).sql in the current directory
	echo Usage:	%0 [db_conn_str table_name]
	echo     "db_conn_str": Oracle Database connection string to be passed to sqlplus, e.g. admin/mypassword@ora10g
	echo     "table_name": Oracle table name, which is case in-sensitive, e.g. card_info
	goto :EOF
)

set db_conn_str=%1

set export_script=%TEMP%\export.sql

REM change table name to upper case
set tab_name=%2
call :TO_UPPER tab_name

REM get the lower case table name
set tab_name_lower=%tab_name%
call :TO_LOWER tab_name_lower
set tab=tab_%tab_name_lower%.sql

REM execute SQL script
(
	echo set echo off
	echo set maxdata 50000
	echo set long 50000
	echo set longchunksize 1000
	echo set pages 0 lines 32767
	echo set heading off
	echo set verify off
	echo set termout off
	echo set feedback off
	echo set trims on
	echo set serveroutput on
	echo set scan off
	echo set timing off
	echo spool %tab%
	echo.
	echo.
	echo.
	echo.
	echo ----------------------------------
	echo -- write create statement
	echo ----------------------------------
	echo.
	echo select 'define DATA_TABLESPACE = ''^&DATA_TABLESPACE'';' from user_tables where table_name = '%tab_name%' and temporary = 'N';
	echo select 'define INDEX_TABLESPACE = ''^&INDEX_TABLESPACE'';' from user_tables where table_name = '%tab_name%' and temporary = 'N';
	echo select '' from user_tables where table_name = '%tab_name%' and temporary = 'N';
	echo select 'REM drop table %tab_name_lower%;' from dual;
	echo prompt
	echo select decode^(temporary, 'N', 'create table %tab_name_lower%^(', 'create global temporary table %tab_name_lower%^('^) from user_tables where table_name = '%tab_name%';
	echo.
	echo declare
	echo 	v_str		varchar2^(32767^);
	echo 	v_data_default	varchar2^(32760^);
	echo 	v_col_count	number;
	echo 	v_col_index	number;
	echo begin
	echo 	select	count^(*^)
	echo 	into	v_col_count
	echo 	from	user_tab_columns
	echo 	where	table_name = '%tab_name%'
	echo 	and	column_id is not null;
	echo.
	echo 	for v_col_index in 1..v_col_count loop
	echo 		begin
	echo 			select	data_default
	echo 			into	v_data_default
	echo 			from	user_tab_columns
	echo 			where	table_name = '%tab_name%'
	echo 			and	column_id = v_col_index
	echo 			and	default_length is not null;
	echo 		exception
	echo 			when no_data_found then
	echo 				null;
	echo 		end;
	echo.
	echo 		select	chr^(9^)^|^|lower^(column_name^)^|^|' '^|^|
	echo 			lower^(decode^(data_type,'VARCHAR2','VARCHAR2^('^|^|char_length^|^|'^)',
	echo 					 'NVARCHAR2','NVARCHAR2^('^|^|char_length^|^|'^)',
	echo 					 'CHAR','CHAR^('^|^|char_length^|^|'^)',
	echo 					 'NCHAR','NCHAR^('^|^|char_length^|^|'^)',
	echo 					 'RAW','RAW^('^|^|data_length^|^|'^)',
	echo 					 'NUMBER','NUMBER'^|^|decode^(data_precision,null,null,'^('^|^|data_precision^|^|decode^(data_scale,0,null,','^|^|data_scale^)^|^|'^)'^),
	echo 					 data_type^)^)^|^|
	echo 			decode^(default_length,null,'',' default '^|^|v_data_default^)^|^|
	echo 			decode^(nullable,'N',' not null',null^)^|^|
	echo 			decode^(column_id,^(select max^(column_id^) from user_tab_columns where table_name = '%tab_name%'^),null,','^)
	echo 		into	v_str
	echo 		from	user_tab_columns
	echo 		where	table_name = '%tab_name%'
	echo 		and	column_id = v_col_index;
	echo.
	echo 		dbms_output.put_line^(v_str^);
	echo 	end loop;
	echo end;
	echo /
	echo.
	echo select decode^(temporary, 'N', '^)'^|^|chr^(10^)^|^|
	echo 				'tablespace ^&DATA_TABLESPACE'^|^|chr^(10^)^|^|
	echo 				'storage^( '^|^|
	echo 				nvl2^(initial_extent,'initial '^|^|initial_extent^|^|' ',''^)^|^|
	echo 				nvl2^(next_extent,'next '^|^|next_extent^|^|' ',''^)^|^|
	echo 				nvl2^(min_extents,'minextents '^|^|min_extents^|^|' ',''^)^|^|
	echo 				nvl2^(max_extents,'maxextents '^|^|decode^(max_extents,2147483645,'unlimited',max_extents^)^|^|' ',''^)^|^|
	echo 				nvl2^(pct_increase,'pctincrease '^|^|pct_increase^|^|' ',''^)^|^|
	echo 				'^);',
	echo 			 decode^(duration, 'SYS\$TRANSACTION', '^) on commit delete rows;',
	echo 					  'SYS\$SESSION', '^) on commit preserve rows;',
	echo 					  '###ERROR###'^)^) from user_tables where table_name = '%tab_name%';
	echo.
	echo prompt
	echo.
	echo.
	echo.
	echo declare
	echo 	v_tab_count	pls_integer;
	echo.
	echo 	v_con_count	pls_integer;
	echo.
	echo 	v_con_type	user_constraints.constraint_type%%type;
	echo 	v_con_name	user_constraints.constraint_name%%type;
	echo 	v_con_status	user_constraints.status%%type;
	echo.
	echo 	v_col_count	pls_integer;
	echo 	v_col_name	user_cons_columns.column_name%%type;
	echo.
	echo 	v_ref_tab_name	user_cons_columns.table_name%%type;
	echo 	v_ref_col_count	pls_integer;
	echo 	v_ref_col_name	user_cons_columns.column_name%%type;
	echo.
	echo 	v_idx_count	pls_integer;
	echo 	v_idx_name	user_indexes.index_name%%type;
	echo 	v_idx_type	user_indexes.index_type%%type;
	echo 	v_idx_uniqueness	user_indexes.uniqueness%%type;
	echo 	v_idx_col_count	pls_integer;
	echo 	v_idx_col_name	user_ind_columns.column_name%%type;
	echo.
	echo 	v_str		varchar2^(1000^);
	echo begin
	echo.
	echo 	----------------------------------
	echo 	-- check for existence of the table
	echo 	----------------------------------
	echo.
	echo 	select	count^(*^)
	echo 	into	v_tab_count
	echo 	from	user_tables
	echo 	where	table_name = '%tab_name%';
	echo 	if v_tab_count != 1 then
	echo 		dbms_output.put_line^('###ERROR###'^);
	echo 		return;
	echo 	end if;
	echo.
	echo 	----------------------------------
	echo 	-- write constraint statement
	echo 	----------------------------------
	echo.
	echo 	select	count^(*^)
	echo 	into	v_con_count
	echo 	from	user_constraints
	echo 	where	table_name = '%tab_name%'
	echo 	and	constraint_type in ^('P', 'U', 'R'^);
	echo.
	echo 	for v_con_index in 1..v_con_count loop
	echo 		select	constraint_type,
	echo 			constraint_name,
	echo 			status
	echo 		into	v_con_type,
	echo 			v_con_name,
	echo 			v_con_status
	echo 		from ^(	select	constraint_type,
	echo 				constraint_name,
	echo 				status,
	echo 				rownum r
	echo 			from	user_constraints
	echo 			where	table_name = '%tab_name%'
	echo 			and	constraint_type in ^('P', 'U', 'R'^)
	echo 			order by constraint_type, constraint_name^)
	echo 		where	r = v_con_index;
	echo.
	echo 		if v_con_type = 'P' then
	echo 			-- primary key
	echo 			v_str := 'alter table %tab_name_lower% add constraint '^|^|lower^(v_con_name^)^|^|' primary key ^(';
	echo 		elsif v_con_type = 'U' then
	echo 			-- unique
	echo 			v_str := 'alter table %tab_name_lower% add constraint '^|^|lower^(v_con_name^)^|^|' unique ^(';
	echo 		elsif v_con_type = 'R' then
	echo 			-- foreign key
	echo 			v_str := 'alter table %tab_name_lower% add constraint '^|^|lower^(v_con_name^)^|^|' foreign key ^(';
	echo 		end if;
	echo.
	echo 		select	count^(*^)
	echo 		into	v_col_count
	echo 		from	user_cons_columns
	echo 		where	table_name = '%tab_name%'
	echo 		and	constraint_name = v_con_name
	echo 		and	position is not null;
	echo.
	echo 		for v_col_index in 1..v_col_count loop
	echo 			select	lower^(column_name^)
	echo 			into	v_col_name
	echo 			from ^(	select	column_name,
	echo 					position,
	echo 					rownum r
	echo 				from	user_cons_columns
	echo 				where	table_name = '%tab_name%'
	echo 				and	constraint_name = v_con_name
	echo 				and	position is not null
	echo 				order by position^)
	echo 			where	r = v_col_index;
	echo.
	echo 			if v_col_index != v_col_count then
	echo 				v_str := v_str^|^|v_col_name^|^|', ';
	echo 			else
	echo 				if v_con_type in ^('P', 'U'^) then
	echo 					v_str := v_str^|^|v_col_name^|^|'^) using index tablespace ^&INDEX_TABLESPACE;';
	echo 				elsif v_con_type = 'R' then
	echo 					v_str := v_str^|^|v_col_name^|^|'^) references ';
	echo.
	echo 					select	unique table_name
	echo 					into	v_ref_tab_name
	echo 					from	user_cons_columns
	echo 					where	constraint_name = ^(	select	r_constraint_name
	echo 									from	user_constraints
	echo 									where	constraint_name = v_con_name^);
	echo 					v_str := v_str^|^|lower^(v_ref_tab_name^)^|^|' ^(';
	echo.
	echo 					select	count^(*^)
	echo 					into	v_ref_col_count
	echo 					from	user_cons_columns
	echo 					where	constraint_name = ^(	select	r_constraint_name
	echo 									from	user_constraints
	echo 									where	constraint_name = v_con_name^)
	echo 					and	position is not null;
	echo.
	echo 					for v_ref_col_index in 1..v_ref_col_count loop
	echo 						select	lower^(column_name^)
	echo 						into	v_ref_col_name
	echo 						from ^(	select	column_name,
	echo 								position,
	echo 								rownum r
	echo 							from	user_cons_columns
	echo 							where	constraint_name = ^(	select	r_constraint_name
	echo 											from	user_constraints
	echo 											where	constraint_name = v_con_name^)
	echo 							and	position is not null
	echo 							order by position^)
	echo 						where	r = v_ref_col_index;
	echo.
	echo 						if v_ref_col_index != v_ref_col_count then
	echo 							v_str := v_str^|^|v_ref_col_name^|^|', ';
	echo 						else
	echo 							v_str := v_str^|^|v_ref_col_name^|^|'^);';
	echo 						end if;
	echo 					end loop;
	echo.
	echo 				end if;
	echo 			end if;
	echo 		end loop;
	echo.
	echo 		dbms_output.put_line^(v_str^);
	echo 	end loop;
	echo.
	echo 	----------------------------------
	echo 	-- write index statement
	echo 	----------------------------------
	echo.
	echo 	select	count^(*^)
	echo 	into	v_idx_count
	echo 	from	user_indexes
	echo 	where	table_name = '%tab_name%'
	echo 	and	index_name not in ^(select constraint_name from user_constraints^);
	echo.
	echo 	for v_idx_index in 1..v_idx_count loop
	echo 		select	index_name,
	echo 			index_type,
	echo 			uniqueness
	echo 		into	v_idx_name,
	echo 			v_idx_type,
	echo 			v_idx_uniqueness
	echo 		from ^(	select	index_name,
	echo 				decode^(index_type,'BITMAP','bitmap '^) index_type,
	echo 				decode^(uniqueness,'UNIQUE','unique ',''^) uniqueness,
	echo 				rownum r
	echo 			from	user_indexes
	echo 			where	table_name = '%tab_name%'
	echo 			and	index_name not in ^(select constraint_name from user_constraints^)
	echo 			order by index_name^)
	echo 		where	r = v_idx_index;
	echo.
	echo 		v_str := 'create '^|^|v_idx_type^|^|v_idx_uniqueness^|^|'index '^|^|lower^(v_idx_name^)^|^|' on %tab_name%_lower^(';
	echo.
	echo 		select	count^(*^)
	echo 		into	v_idx_col_count
	echo 		from	user_ind_columns
	echo 		where	table_name = '%tab_name%'
	echo 		and	index_name = v_idx_name;
	echo.
	echo 		for v_idx_col_index in 1..v_idx_col_count loop
	echo 			select	column_name
	echo 			into	v_idx_col_name
	echo 			from	user_ind_columns
	echo 			where	table_name = '%tab_name%'
	echo 			and	index_name = v_idx_name
	echo 			and	column_position = v_idx_col_index;
	echo.
	echo 			if v_idx_col_name like 'SYS_NC%' then
	echo 				select	column_expression
	echo 				into	v_idx_col_name
	echo 				from	user_ind_expressions
	echo 				where	table_name = '%tab_name%'
	echo 				and	index_name = v_idx_name
	echo 				and	column_position = v_idx_col_index;
	echo.
	echo 				v_idx_col_name := translate^(v_idx_col_name, 'x"', 'x');
	echo 			end if;
	echo.
	echo 			if v_idx_col_index != v_idx_col_count then
	echo 				v_str := v_str^|^|lower^(v_idx_col_name^)^|^|', ';
	echo 			else
	echo 				v_str := v_str^|^|lower^(v_idx_col_name^)^|^|'^) tablespace ^&INDEX_TABLESPACE;';
	echo 			end if;
	echo 		end loop;
	echo.
	echo 		if v_idx_col_count ^> 0 then
	echo 			dbms_output.put_line^(v_str^);
	echo 		end if;
	echo 	end loop;
	echo.
	echo exception
	echo 	when others then
	echo 		dbms_output.put_line^('###ERROR###'^);
	echo 		dbms_output.put_line^('Error '^|^|sqlcode^|^|' - '^|^|sqlerrm^);
	echo end;
	echo /
	echo.
	echo.
	echo.
	echo.
	echo prompt
	echo spool off
	echo exit
) > %export_script%
sqlplus -SL %db_conn_str% @%export_script%


REM confirm the export of table was successful

findstr /I /C:%tab_name% %tab% > NUL
if errorlevel 1 (
	echo echo Failed to export definitions of table "%tab_name%", probably because the table does not exist or is inaccessible
	echo del %tab%
	echo goto :EOF
)

REM export successful
echo Definitions of table "%tab_name%" exported successfully

goto :EOF


:TO_LOWER
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF


:TO_UPPER
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF
