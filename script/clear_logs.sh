#!/bin/bash

FULL_PATH=`realpath $0`
SCRIPT_PATH=`dirname $FULL_PATH`
DB_NAME=`$SCRIPT_PATH/print_config_database.rb log_db`

cd $SCRIPT_PATH/../files
rm $DB_NAME
