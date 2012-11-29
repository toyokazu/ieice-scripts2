#!/usr/bin/env ruby

require 'yaml'
require 'sqlite3'

ROOT_PATH = File.expand_path('../../',  __FILE__)

tsv_config_path = "#{ROOT_PATH}/config/tsv_files.yml"
db_config_path = "#{ROOT_PATH}/config/database.yml"

if !File.exists?(db_config_path)
    puts "can not find configuration file: #{db_config_path}"
      exit 1
end

$db_config = YAML.load_file(db_config_path)

sql = "select remote_addr, count(*) as num from access_logs where log_date between ? and ? group by remote_addr order by num desc;"

$db = SQLite3::Database.new("#{ROOT_PATH}/files/#{$db_config["log_db"]}")

