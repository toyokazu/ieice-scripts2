#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'fileutils'

ROOT_PATH = File.expand_path('../../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/cinii_files.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

def error_and_exit
  $stderr.puts "usage: import_and_convert_cinii_metadata.rb"
  exit 1
end

if ARGV.size > 1
  error_and_exit
end

config = YAML.load_file(config_path)

$prefix = "#{ROOT_PATH}/files"

print <<SQL1
/* TSVファイルのインポート */
.separator \"\\t\"
SQL1
Dir["#{ROOT_PATH}/files/#{config["cinii_files"]}-with_paper_id.txt"].each do |filename|
  print <<SQL2
.import #{filename} cinii_metadata
SQL2
end
print <<SQL3
create index cinii_metadata_index on cinii_metadata ( paper_id );
SQL3
