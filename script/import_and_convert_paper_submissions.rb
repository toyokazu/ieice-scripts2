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
  $stderr.puts "usage: import_and_convert_paper_submissions.rb [YYYYMMDD]"
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

def tsv_submissions(config)
  file_prefixes = []
  config.each do |filename|
    file_prefix = "#{$prefix}/#{filename}_#{$date}"
    if File.exists?("#{file_prefix}-with_paper_id.txt")
      file_prefixes << file_prefix
    else
      next
    end
  end
  file_prefixes
end

$tsv_submissions_ja = tsv_submissions(config["tsv_submissions_ja"])
$tsv_submissions_en = tsv_submissions(config["tsv_submissions_en"])

print <<SQL1
/* TSV ファイルのインポート */
.separator \"\\t\"
SQL1

$tsv_submissions_ja.each do |file_prefix|
  file = "#{file_prefix}-with_paper_id.txt"
  print <<SQL2
.import #{file_prefix}-with_paper_id.txt ja_paper_submissions
SQL2
end
$tsv_submissions_en.each do |file_prefix|
  print <<SQL3
.import #{file_prefix}-with_paper_id.txt en_paper_submissions
SQL3
end
print <<SQL4
/* "" の一括削除 */
update ja_paper_submissions set title_j = replace(title_j, '"', ''), title_e = replace(title_e, '"', ''), volume1 = replace(volume1, '"', '');
update en_paper_submissions set title_j = replace(title_j, '"', ''), title_e = replace(title_e, '"', ''), volume1 = replace(volume1, '"', '');
/* create index */
create index ja_paper_submissions_index on ja_paper_submissions ( paper_id );
create index en_paper_submissions_index on en_paper_submissions ( paper_id );
SQL4
