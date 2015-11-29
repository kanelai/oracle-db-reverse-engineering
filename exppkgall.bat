@echo off

REM ################################################################################
REM #
REM #	exppkgall
REM #
REM #	A tool to export all packages from Oracle Database 
REM #
REM #
REM #   Version	Date		Modified by	Descriptions
REM #  --------------------------------------------------------------------------
REM #   1.0.0	20111216	Kane Lai	First release (based on exppkgall
REM #						for *nix 1.0.4)
REM #
REM ###############################################################################


set version=1.0.0

set is_failed=0
if [%1]==[] (
	set is_failed=1
)
if not [%2]==[] (
	set is_failed=1
)

if %is_failed%==1 (
	echo exppkgall v%version% - A tool to export all packages from Oracle Database
	echo Exported package header and body will be named ^(package_name^)_header.sql and ^(package_name^)_body.sql in the current directory
	echo Usage:	%0 [db_conn_str]
	echo     "db_conn_str": Oracle Database connection string to be passed to sqlplus, e.g. admin/mypassword@ora10g
	goto :EOF
)

set db_conn_str=%1

set pkglist=pkglist.bat
set load_pkg_script=load_pkg.sql

REM change package name to upper case
set pkg_name=%2
call :TO_UPPER pkg_name

REM generate export script
set export_script=%TEMP%\export.sql
echo. > %export_script%
echo set echo off >> %export_script%
echo set pages 0 lines 32767 >> %export_script%
echo set heading off >> %export_script%
echo set verify off >> %export_script%
echo set termout off >> %export_script%
echo set feedback off >> %export_script%
echo set trims on >> %export_script%
echo set scan off >> %export_script%
echo set timing off >> %export_script%
echo. >> %export_script%
echo spool %pkglist% >> %export_script%
echo select 'cmd /c exppkg %db_conn_str% '^|^|object_name from user_objects where object_type='PACKAGE' and object_name not like '%%/%%' order by object_name; >> %export_script%
echo spool off >> %export_script%
echo. >> %export_script%
echo exit >> %export_script%
echo. >> %export_script%

REM execute export script
sqlplus -SL %db_conn_str% @%export_script% > NUL

%pkglist%
del %pkglist%

goto :EOF


:TO_LOWER
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF


:TO_UPPER
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF
