#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'fileutils'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = ARGV[0] || "#{ROOT_PATH}/config/count_log_files.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

config = YAML.load_file(config_path)

# configuration file format example
#
# ---
# log_files: search_logs/search_log_*.bak
# output: downloads_count.txt
# ---
#
# search_logs/search_log_*.bak: the file name pattern of the paper search system access log (tsv)
# downloads_count.txt: output file name (tsv)

nkf = "#{ROOT_PATH}/script/nkf.rb -Sw"
Dir["#{ROOT_PATH}/files/#{config["log_files"]}"].each do |filename|
  utf8_filename = "#{filename}-utf8"
  $stderr.puts "#{nkf} #{filename} > #{utf8_filename}"
  system("#{nkf} #{filename} > #{utf8_filename}")
end
