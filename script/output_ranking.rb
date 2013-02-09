#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'sqlite3'
require 'systemu'

ROOT_PATH = File.expand_path('../../',  __FILE__)
tsv_config_path = "#{ROOT_PATH}/config/tsv_files.yml"
stats_config_path = "#{ROOT_PATH}/config/count_log_files.yml"

if !File.exists?(tsv_config_path)
  puts "can not find configuration file: #{tsv_config_path}"
  exit 1
elsif !File.exists?(stats_config_path)
  puts "can not find configuration file: #{stats_config_path}"
  exit 1
end


$tsv_config = YAML.load_file(tsv_config_path)
$stats_config = YAML.load_file(stats_config_path)

def error_and_exit
  $stderr.puts "usage: output_ranking.rb ja|en [YYYYMMDD]"
  $stderr.puts "arguments:"
  $stderr.puts "    must: ja|en|addr"
  $stderr.puts "    optional: YYYYMMDD"
  exit 1
end

if ARGV.size < 1
  error_and_exit
end

# 689.6698924637 is determined by statistics of all paper and remote_addr data.
MAX_PAPER_PER_MONTH = 689.6698924637

# configuration file format example
#
# ---
# log_files: search_logs/search_log_*.bak
# month_stats: month_stats.yml
# month_stats_db: month_stats.db
# ranking_output: downloads_ranking.txt
# output: downloads_count.txt
# ---
#
# search_logs/search_log_*.bak: the file name pattern of the paper search system access log (tsv)
# downloads_count.txt: output file name (tsv)

$db = SQLite3::Database.new("#{ROOT_PATH}/files/#{$stats_config["month_stats_db"]}")

$target = ARGV[0]

# generate input/output file name postfix
$date = ARGV[1] || Time.now.strftime("%Y%m%d")

# initialize language dependent parameters
case $target
when 'ja'
  $prefix = "'j%'"
  $search_file = "#{ROOT_PATH}/files/#{$tsv_config["tsv_tran_ja"]}_#{$date}.txt"
when 'en'
  $prefix = "'e%'"
  $search_file = "#{ROOT_PATH}/files/#{$tsv_config["tsv_tran_en"]}_#{$date}.txt"
when 'addr'
else
  error_and_exit
end

def paper_id(paper)
  paper[0].gsub(".pdf","")
end

def access_count(paper)
  paper[3]
end

def uniq_access_count(paper)
  paper[4]
end

def title(description)
  description[14]
end

def authors(description)
  description[15]
end

def keywords(description)
  description[17]
end

def ip_address(addr)
  addr[0]
end

def addr_access_count(addr)
  addr[3]
end

stats_dates = $db.execute("select stats_date from paper_stats group by stats_date").map {|i| i.first}
stats_dates.each do |stats_date|
  if $target == 'ja' || $target == 'en'
    # create table paper_stats (
    #   paper_id varchar(32),
    #   stats_date varchar(16),
    #   stats_datetime datetime,
    #   access_count integer,
    #   uniq_address_count integer,
    #   address_count integer,
    #   access_rank integer,
    #   uniq_access_rank integer
    # );
    papers = $db.execute("select * from paper_stats where stats_date = ? and paper_id like #{$prefix} order by access_count desc limit 10;", stats_date)
    puts "#{stats_date} Paper Top 10 ====="
    papers.each_with_index do |paper, i|
      status, stdout, stderr = systemu("grep #{paper_id(paper)} #{$search_file}")
      description = stdout.gsub(/\r*\n/,"").split("\t")
      puts "Ranking #{i+1}: #{paper_id(paper)} (#{uniq_access_count(paper)}/#{access_count(paper)})"
      puts "  Title: #{title(description)}"
      puts "  Authors: #{authors(description)}"
      puts "  Keywords: #{keywords(description)}"
    end
  else
    # remote address top 10
    # network address base aggregation may be required
    remote_addrs = $db.execute("select * from address_stats where stats_date = ? order by access_count desc limit 10;", stats_date)
    puts "#{stats_date} Address Top 10 ====="
    remote_addrs.each_with_index do |addr, i|
      description = stdout.gsub(/\r*\n/,"").split("\t")
      puts "Ranking #{i+1}: #{ip_address(addr)} (#{uniq_access_count(addr)}#{addr_access_count(addr)})"
    end
  end
end
