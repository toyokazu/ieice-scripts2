#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'fileutils'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/tsv_files.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

def error_and_exit
  $stderr.puts "usage: import_and_convert_paper_metadata.rb [YYYYMMDD]"
  $stderr.puts "arguments:"
  $stderr.puts "    optional: YYYYMMDD"
  exit 1
end

if ARGV.size > 2 || (!ARGV[0].nil? && ARGV[0] !~ /\d{6}/)
  error_and_exit
end

config = YAML.load_file(config_path)

$prefix = "#{ROOT_PATH}/files"
# generate input/output file name postfix
$date = ARGV[0] || Time.now.strftime("%Y%m%d")

$tsv_tran_ja = "#{$prefix}/input_#{config["tsv_tran_ja"]}_#{$date}.txt"
$tsv_tran_en_ja = "#{$prefix}/input_#{config["tsv_tran_en_ja"]}_#{$date}.txt"
$tsv_tran_en = "#{$prefix}/input_#{config["tsv_tran_en"]}_#{$date}.txt"

print <<SQL1
/* TSVファイルのインポート */
.separator \"\\t\"
SQL1
print <<SQL2
.import #{$tsv_tran_ja} ja_paper_metadata
.import #{$tsv_tran_en_ja} en_ja_paper_metadata
.import #{$tsv_tran_en} en_paper_metadata
SQL2
print <<SQL3
create index ja_paper_metadata_index on ja_paper_metadata ( id );
create index en_ja_paper_metadata_index on en_ja_paper_metadata ( id );
create index en_paper_metadata_index on en_paper_metadata ( id );
SQL3
