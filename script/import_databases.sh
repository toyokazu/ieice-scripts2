#!/bin/bash

FULL_PATH=`realpath $0`
SCRIPT_PATH=`dirname $FULL_PATH`
DB_NAME=`$SCRIPT_PATH/print_config_database.rb paper_db`

cd "$SCRIPT_PATH/../files"
$SCRIPT_PATH/preproc.rb $1
#$SCRIPT_PATH/generate_paper_id.rb
sqlite3 $DB_NAME < $SCRIPT_PATH/createtable_paper_submissions.sql
$SCRIPT_PATH/import_and_convert_paper_submissions.rb $1 | sqlite3 $DB_NAME
#sqlite3 $DB_NAME < $SCRIPT_PATH/import_and_convert_paper_submissions.sql
sqlite3 $DB_NAME < $SCRIPT_PATH/createtable_paper_metadata.sql
$SCRIPT_PATH/import_and_convert_paper_metadata.rb $1 | sqlite3 $DB_NAME
#sqlite3 $DB_NAME < $SCRIPT_PATH/import_and_convert_paper_metadata.sql
