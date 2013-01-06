#!/bin/bash

FULL_PATH=`realpath $0`
CINII_PATH=`dirname $FULL_PATH`
SCRIPT_PATH=`dirname $CINII_PATH`
DB_NAME=`$SCRIPT_PATH/print_config_database.rb paper_db`

cd "$SCRIPT_PATH/../files/cinii"
$CINII_PATH/preproc.rb
sqlite3 $DB_NAME < $CINII_PATH/createtable_cinii_metadata.sql
$CINII_PATH/import_and_convert_cinii_metadata.rb $1 | sqlite3 $DB_NAME
sqlite3 $DB_NAME < $CINII_PATH/createtable_paper_metadata.sql
$CINII_PATH/import_and_convert_paper_metadata.rb $1 | sqlite3 $DB_NAME
