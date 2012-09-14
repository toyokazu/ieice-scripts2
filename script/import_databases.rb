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
  system("#{ROOT_PATH}/script/generate_paper_id.rb")
  system("sqlite3 #{$config["paper_db"]} < #{ROOT_PATH}/script/createtable_paper_submissions.sql")
  system("sqlite3 #{$config["paper_db"]} < #{ROOT_PATH}/script/import_and_convert_paper_submissions.sql")
  system("sqlite3 #{$config["paper_db"]} < #{ROOT_PATH}/script/createtable_paper_metadata.sql")
  system("sqlite3 #{$config["paper_db"]} < #{ROOT_PATH}/script/import_and_convert_paper_metadata.sql")
end
