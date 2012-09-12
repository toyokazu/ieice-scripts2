#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

if ARGV.size < 1
  exit 1
end

f = open(ARGV[0])

hash = {}
lines = f.readlines
lines.each_with_index do |line, i|
  record = line.gsub(/\r*\n/, "").split("\t", 29)
  if hash[record[0]].nil?
    hash[record[0]] = record
  else
    $stderr.puts "#{record[0]}"
  end
end
f.close
