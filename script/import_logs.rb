#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'shell'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/database.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

$config = YAML.load_file(config_path)

$sh = Shell.new
$sh.transact do
  cd("#{ROOT_PATH}/files")
  system("sqlite3 #{$config["log_db"]} < #{ROOT_PATH}/script/createtable_logs.sql")
  system("sqlite3 #{$config["log_db"]} < #{ROOT_PATH}/script/import_and_convert_logs.sql")
end
