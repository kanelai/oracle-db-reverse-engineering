@echo off

REM ################################################################################
REM #
REM #	exppkg
REM #
REM #	A tool to export packages from Oracle Database
REM #
REM #
REM #   Version	Date		Modified by	Descriptions
REM #  --------------------------------------------------------------------------
REM #   1.0.0	20111215	Kane Lai	First release (based on exppkg for
REM #						*nix 1.0.3)
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
	echo exppkg v%version% - A tool to export packages from Oracle Database
	echo Exported package header and body will be named ^(package_name^)_header.sql and ^(package_name^)_body.sql in the current directory
	echo Usage:	%0 [db_conn_str package_name]
	echo     "db_conn_str": Oracle Database connection string to be passed to sqlplus, e.g. admin/mypassword@ora10g
	echo     "package_name": Oracle package name, which is case in-sensitive, e.g. pkg_paygo
	goto :EOF
)

set db_conn_str=%1

REM change package name to upper case
set pkg_name=%2
call :TO_UPPER pkg_name

REM get the lower case package name
set pkg_name_lower=%pkg_name%
call :TO_LOWER pkg_name_lower
set pkg_header=%pkg_name_lower%_header.sql
set pkg_body=%pkg_name_lower%_body.sql

REM execute SQL script
(
	echo set echo off
	echo set maxdata 60000
	echo set long 50000
	echo set longchunksize 1000
	echo set pages 0 lines 32767
	echo set heading off
	echo set verify off
	echo set termout off
	echo set feedback off
	echo set trims on
	echo set scan off
	echo set timing off
	echo spool %pkg_header%
	echo prompt create or replace
	echo select TEXT from user_source where TYPE='PACKAGE' and NAME='%pkg_name%';
	echo prompt /
	echo prompt show err
	echo spool off
	echo spool %pkg_body%
	echo prompt create or replace
	echo select TEXT from user_source where TYPE='PACKAGE BODY' and NAME='%pkg_name%';
	echo prompt /
	echo prompt show err
	echo spool off
) | sqlplus -SL %db_conn_str% > nul


REM confirm the export of package header was successful

findstr /I /C:%pkg_name% %pkg_header% > NUL
if errorlevel 1 (
	echo Failed to export package "%pkg_name%", probably because the package does not exist or is inaccessible
	del %pkg_header% %pkg_body%
	goto :EOF
)

findstr /I /C:%pkg_name% %pkg_body% > NUL
if errorlevel 1 (
	echo No package body was found for "%pkg_name%"
	del %pkg_body%
)

REM export successful
echo Package "%pkg_name%" exported successfully

goto :EOF


:TO_LOWER
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF


:TO_UPPER
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF
