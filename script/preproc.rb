#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'fileutils'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = ARGV[0] || "#{ROOT_PATH}/config/preproc.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

config = YAML.load_file(config_path)

# configuration file format example
#
# ---
# a_j: output_a_j
# b_j: output_b_j
# c_j: output_c_j
# d_j: output_d_j
# a_e: output_a_e
# b_e: output_b_e
# c_e: output_c_e
# d_e: output_d_e
# output: output_a-d_j-e.txt

nkf = "#{ROOT_PATH}/script/nkf.rb -Sw"
prefix = "#{ROOT_PATH}/files"
#output = "#{prefix}/#{config["output"]}"
#if File.exists?(output)
#  FileUtils.remove(output)
#  FileUtils.touch(output)
#end

#fout = open(output, "w")
["j", "e"].each do |l|
  ("a".."d").each do |s|
    label = "#{s}_#{l}"
    # convert character code
    system("#{nkf} #{prefix}/#{config[label]}.txt > #{prefix}/#{config[label]}-utf8-with_header.txt")
    # cut header lines
    open("#{prefix}/#{config[label]}-utf8.txt", "w") do |fw|
      open("#{prefix}/#{config[label]}-utf8-with_header.txt") do |fr|
        fr.readline
        fw.puts fr.read
      end
    end
    # sort
    #system("sort -g -k 1,2 -k 7 #{prefix}/#{config[label]}-utf8.txt > #{prefix}/#{config[label]}-utf8-sorted.txt")
#    if l == "j"
#      open("#{prefix}/#{config[label]}-utf8-sorted.txt") do |f|
#        f.readline
#        fout.puts f.read
#      end
#    else
#      open("#{prefix}/#{config[label]}-utf8-sorted.txt") do |f|
#        f.readline
#        f.readline
#        fout.puts f.read
#      end
#    end
  end
end
#fout.close
