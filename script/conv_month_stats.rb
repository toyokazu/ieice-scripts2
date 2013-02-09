#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'shell'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/count_log_files.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

$config = YAML.load_file(config_path)

$reset = ARGV[0].nil?

# configuration file format example
#
# ---
# log_files: search_logs/search_log_*.bak
# month_stats: month_stats.yml
# month_stats_db: month_stats.db
# output: downloads_count.txt
# ---
#
# search_logs/search_log_*.bak: the file name pattern of the paper search system access log (tsv)
# downloads_count.txt: output file name (tsv)

# stats hash format
# '200801':                         # target month
#   paper:
#     e91-c_1_113.pdf:              # paper_id
#       paper:  30                  # paper access count per month
#       remote_addr_uniq: 20        # remote address per paper per month (unique)
#       remote_addr: 30             # remote address per paper per month
#     e90-c_8_1627.pdf:
#       paper: 2
#       remote_addr_uniq: 2
#       remote_addr: 2
#   remote_addr:
#     133.13.48.71:                 # IP addresses
#       remote_addr: 11             # access count from the IP address per month
#       paper_uniq: 4               # paper accesses per IP address per month (unique (paper_id count))
#       paper: 11                   # paper accesses per IP address per month
#     192.168.1.200, 192.168.2.18:  # currently only the first entry is handled in ranking procedure
#       remote_addr: 26
#       paper_uniq: 19
#       paper: 26
#
# convert stats to DB table format
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
# 8 columns
#
# create table address_stats (
#   ip_address varchar(128),
#   stats_date varchar(16),
#   stats_datetime datetime,
#   access_count integer,
#   uniq_paper_count integer,
#   paper_count integer,
#   access_rank integer,
#   uniq_access_rank integer,
#   network_address varchar(256),
#   network_owner_jpnic varchar(256),
#   network_owner_radb varchar(256)
# );
# 11 columns

def load_hash(config)
  filename = "#{ROOT_PATH}/files/#{config["month_stats"]}"
  log_hash = {}
  if !File.exist?(filename)
    return log_hash
  end
  open(filename) do |f|
    log_hash = YAML.load_file(filename)
  end
  log_hash
end

# craete databases
$sh = Shell.new
if $reset
  $sh.transact do
    cd("#{ROOT_PATH}/files")
    system("sqlite3 #{$config["month_stats_db"]} < #{ROOT_PATH}/script/createtable_month_stats.sql")
  end
end

# load hash
$log_hash = load_hash($config)

# csv file names
$paper_csv = "#{ROOT_PATH}/files/#{$config["month_stats"].gsub(".yml", "")}-paper.csv"
$address_csv = "#{ROOT_PATH}/files/#{$config["month_stats"].gsub(".yml", "")}-address.csv"
$month_csv = "#{ROOT_PATH}/files/#{$config["month_stats"].gsub(".yml", "")}-month.csv"
# clear older csv files
$sh.transact do
  cd("#{ROOT_PATH}/files")
  system("rm #{$paper_csv}")
  system("rm #{$address_csv}")
  system("rm #{$month_csv}")
end

# create csv file for importing
open($paper_csv, "w") do |f_paper|
  open($address_csv, "w") do |f_addr|
    open($month_csv, "w") do |f_month|
      $log_hash.keys.each do |stats_date|
        # create csv for paper_stats table
        #
        # '200801':                         # target month
        #   paper:
        #     e91-c_1_113.pdf:              # paper_id
        #       paper:  30                  # paper access count per month
        #       remote_addr_uniq: 20        # remote address per paper per month (unique)
        #       remote_addr: 30             # remote address per paper per month
        #
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
        # 8 columns
        # 6 columns are derived from hash data
        $log_hash[stats_date]["paper"].each do |paper_id, stats|
          f_paper.puts "#{paper_id}\t#{stats_date}\t#{Time.new(stats_date)}\t#{stats["paper"]}\t#{stats["remote_addr_uniq"]}\t#{stats["remote_addr"]}\t#{Array.new(2,"").join("\t")}"
        end

        # create csv for paper_stats table
        #
        # '200801':                         # target month
        #   remote_addr:
        #     133.13.48.71:                 # IP address
        #       remote_addr: 11             # access count from the IP address per month
        #       paper_uniq: 4               # paper accesses per IP address per month (unique (paper_id count))
        #       paper: 11                   # paper accesses per IP address per month
        #     192.168.1.200, 192.168.2.18:  # currently only the first entry is handled in ranking procedure
        #       remote_addr: 26
        #       paper_uniq: 19
        #       paper: 26
        #
        # create csv for address_stats table
        # create table address_stats (
        #   ip_address varchar(128),
        #   stats_date varchar(16),
        #   stats_datetime datetime,
        #   access_count integer,
        #   uniq_paper_count integer,
        #   paper_count integer,
        #   access_rank integer,
        #   uniq_access_rank integer,
        #   network_address varchar(256),
        #   network_owner_jpnic varchar(256),
        #   network_owner_radb varchar(256)
        # );
        # 11 columns
        # 6 columns are derived from hash data
        $log_hash[stats_date]["remote_addr"].each do |ip_address, stats|
          f_addr.puts "#{ip_address.split(/\s*,\s*/).first}\t#{stats_date}\t#{Time.new(stats_date)}\t#{stats["remote_addr"]}\t#{stats["paper_uniq"]}\t#{stats["paper"]}\t#{Array.new(5,"").join("\t")}"
        end

        # create csv for month_stats table
        #
        # create table month_stats (
        #   stats_date varchar(16),
        #   stats_datetime datetime,
        #   avg_paper integer,
        #   var_paper integer,
        #   dev_paper float,
        #   num_paper integer,
        #   thresh_num_paper integer,
        #   avg_remote_addr integer,
        #   var_remote_addr integer,
        #   dev_remote_addr float,
        #   num_remote_addr integer,
        #   thresh_num_remote_addr integer,
        #   num_bots integer,
        #   num_others integer
        # );
        month_stats = $log_hash[stats_date]
        f_month.print "#{stats_date}\t#{Time.new(stats_date)}\t#{month_stats["avg_paper"]}\t"
        f_month.print "#{month_stats["var_paper"]}\t#{month_stats["dev_paper"]}\t#{month_stats["num_paper"]}\t"
        f_month.print "#{month_stats["thresh_num_paper"]}\t#{month_stats["avg_remote_addr"]}\t"
        f_month.print "#{month_stats["var_remote_addr"]}\t#{month_stats["dev_remote_addr"]}\t"
        f_month.print "#{month_stats["num_remote_addr"]}\t#{month_stats["thresh_num_remote_addr"]}\t"
        f_month.print "#{month_stats["num_bots"]}\t#{month_stats["num_others"]}\n"
      end
    end
  end
end

# create import csv sql
$import_sql = "#{ROOT_PATH}/files/#{$config["month_stats"].gsub(".yml", "")}-import.sql"
$sh.transact do
  cd("#{ROOT_PATH}/files")
  system("rm #{$import_sql}")
end

open($import_sql, "w") do |f|
  f.print <<-SQL
.separator \"\t\"
.import #{$paper_csv} paper_stats
.import #{$address_csv} address_stats
.import #{$month_csv} month_stats
  SQL
end

$sh.transact do
  cd("#{ROOT_PATH}/files")
  system("sqlite3 #{$config["month_stats_db"]} < #{$import_sql}")
end
