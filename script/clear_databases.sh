#!/bin/bash

FULL_PATH=`realpath $0`
SCRIPT_PATH=`dirname $FULL_PATH`
DB_NAME=`$SCRIPT_PATH/print_config_database.rb paper_db`

cd $SCRIPT_PATH/../files
rm *-utf8.txt
rm *-utf8-with_header.txt
rm *-with_paper_id.txt
rm $DB_NAME
