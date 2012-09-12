#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

if ARGV.size < 1
  $stderr.puts "usage: check_final_en_ja.rb ./logs/ja_logs.txt ./files/final_en_ja.txt"
  $stderr.puts "usage: check_final_en_ja.rb ./logs/ja_logs.txt ./files/output_ej.txt"
  exit 1
end

fin = open(ARGV[0])
fout = open(ARGV[1])

lines = fin.readlines
not_founds = {}
lines.each do |line|
  line =~ /(\w+\d+\-\w+(\-I+)*_\d+_\d+) is not found in/
  paper_id = $1
  not_founds[paper_id] = true
end
$stderr.puts "not_founds: #{not_founds.size}"
lines = fout.readlines
count = 0
lines.each do |line|
  line =~ /^(\w+\d+\-\w+(\-I+)*_\d+_\d+)\t/
  paper_id = $1
  if !not_founds[paper_id].nil?
    $stderr.puts paper_id
    count += 1
  end
end
$stderr.puts "count = #{count}"
fin.close
fout.close
