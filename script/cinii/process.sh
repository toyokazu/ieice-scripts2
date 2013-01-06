#!/bin/bash

FULL_PATH=`realpath $0`
CINII_PATH=`dirname $FULL_PATH`
SCRIPT_PATH=`dirname $CINII_PATH`
DB_NAME=`$SCRIPT_PATH/print_config_database.rb paper_db`

cd "$SCRIPT_PATH/../files/cinii"
IMPORT_LOG="$SCRIPT_PATH/../logs/cinii_import_logs-$1"
IMPORT_LOG_UNIX="$IMPORT_LOG.txt"
IMPORT_LOG_WIN="$IMPORT_LOG-win.txt"
JA_LOG="$SCRIPT_PATH/../logs/cinii_ja_logs-$1"
JA_LOG_UNIX="$JA_LOG.txt"
JA_LOG_WIN="$JA_LOG-win.txt"
EN_LOG="$SCRIPT_PATH/../logs/cinii_en_logs-$1"
EN_LOG_UNIX="$EN_LOG.txt"
EN_LOG_WIN="$EN_LOG-win.txt"
$CINII_PATH/clear_databases.sh
$CINII_PATH/import_databases.sh $1 2> $IMPORT_LOG_UNIX
$CINII_PATH/output_merged_tsv.rb ja $1 2> $JA_LOG_UNIX
$CINII_PATH/output_merged_tsv.rb en $1 2> $EN_LOG_UNIX
$CINII_PATH/generate_final_tsv.rb $1
$SCRIPT_PATH/nkf.rb -WsLw $IMPORT_LOG_UNIX > $IMPORT_LOG_WIN
$SCRIPT_PATH/nkf.rb -WsLw $JA_LOG_UNIX > $JA_LOG_WIN
$SCRIPT_PATH/nkf.rb -WsLw $EN_LOG_UNIX > $EN_LOG_WIN

