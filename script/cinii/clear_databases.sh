#!/bin/bash

FULL_PATH=`realpath $0`
CINII_PATH=`dirname $FULL_PATH`
SCRIPT_PATH=`dirname $CINII_PATH`
DB_NAME=`$SCRIPT_PATH/print_config_database.rb paper_db`

cd $SCRIPT_PATH/../files/cinii
rm $DB_NAME
