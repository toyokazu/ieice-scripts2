#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'shell'

ROOT_PATH = File.expand_path('../../../',  __FILE__)
SCRIPT_PATH = "#{ROOT_PATH}/script"
CINII_PATH = "#{ROOT_PATH}/script/cinii"
config_path = "#{ROOT_PATH}/config/database.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

$config = YAML.load_file(config_path)

$sh = Shell.new
$sh.transact do
  cd("#{ROOT_PATH}/files/cinii")
  system("#{CINII_PATH}/preproc.rb")
  system("sqlite3 #{$config["paper_db"]} < #{CINII_PATH}/createtable_cinii_metadata.sql")
  system("#{CINII_PATH}/import_and_convert_cinii_metadata.rb #{ARGV[0]} | sqlite3 #{$config["paper_db"]}")
  system("sqlite3 #{$config["paper_db"]} < #{CINII_PATH}/createtable_paper_metadata.sql")
  system("#{CINII_PATH}/import_and_convert_paper_metadata.rb #{ARGV[0]} | sqlite3 #{$config["paper_db"]}")
end
