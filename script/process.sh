#!/bin/bash

FULL_PATH=`realpath $0`
SCRIPT_PATH=`dirname $FULL_PATH`
DB_NAME=`$SCRIPT_PATH/print_config_database.rb paper_db`

cd "$SCRIPT_PATH/../files"
IMPORT_LOG="$SCRIPT_PATH/../logs/import_logs-$1"
IMPORT_LOG_UNIX="$IMPORT_LOG.txt"
IMPORT_LOG_WIN="$IMPORT_LOG-win.txt"
JA_LOG="$SCRIPT_PATH/../logs/ja_logs-$1"
JA_LOG_UNIX="$JA_LOG.txt"
JA_LOG_WIN="$JA_LOG-win.txt"
EN_LOG="$SCRIPT_PATH/../logs/en_logs-$1"
EN_LOG_UNIX="$EN_LOG.txt"
EN_LOG_WIN="$EN_LOG-win.txt"
$SCRIPT_PATH/clear_databases.sh
$SCRIPT_PATH/import_databases.sh $1 2> $IMPORT_LOG_UNIX
$SCRIPT_PATH/output_merged_tsv.rb ja $1 2> $JA_LOG_UNIX
$SCRIPT_PATH/output_merged_tsv.rb en $1 2> $EN_LOG_UNIX
$SCRIPT_PATH/generate_final_tsv.rb $1
$SCRIPT_PATH/nkf.rb -WsLw $IMPORT_LOG_UNIX > $IMPORT_LOG_WIN
$SCRIPT_PATH/nkf.rb -WsLw $JA_LOG_UNIX > $JA_LOG_WIN
$SCRIPT_PATH/nkf.rb -WsLw $EN_LOG_UNIX > $EN_LOG_WIN

