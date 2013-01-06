#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'sqlite3'

# usage:
# generate_final_tsv.rb 2> logs/final_tsv.txt

ROOT_PATH = File.expand_path('../../../',  __FILE__)

tsv_config_path = "#{ROOT_PATH}/config/cinii_files.yml"

if !File.exists?(tsv_config_path)
  puts "can not find configuration file: #{tsv_config_path}"
  exit 1
end

$tsv_config = YAML.load_file(tsv_config_path)

def error_and_exit
  $stderr.puts "usage: generate_final_tsv.rb [YYYYMMDD]"
  $stderr.puts "arguments:"
  $stderr.puts "    optional: YYYYMMDD"
  exit 1
end

# generate input/output file name postfix
$date = ARGV[0] || Time.now.strftime("%Y%m%d")

files =[
  "#{ROOT_PATH}/files/cinii/#{$tsv_config["tsv_tran_ja"]}_#{$date}",
  "#{ROOT_PATH}/files/cinii/#{$tsv_config["tsv_tran_en_ja"]}_#{$date}",
  "#{ROOT_PATH}/files/cinii/#{$tsv_config["tsv_tran_en"]}_#{$date}"
]

columns = 30
files.each do |filename|
  if !File.exists?("#{filename}-with_comment.txt")
    next
  end
  open("#{filename}-with_comment.txt") do |fr|
    open("#{filename}.txt", "w") do |fw|
      begin
        while true
          line = fr.readline
          record = line.gsub(/\r*\n/, "").split("\t", columns).map{|i| i.gsub(/\t$/, "")}
          fw.puts record[0..-2].join("\t")
        end
      rescue EOFError => e
      rescue => e
        $stderr.puts e.message
      end
    end
  end
end
