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
  $stderr.puts "usage: preproc.rb [YYYYMMDD]"
  $stderr.puts "arguments:"
  $stderr.puts "    optional: YYYYMMDD"
  exit 1
end

if ARGV.size > 2 || (!ARGV[0].nil? && ARGV[0] !~ /\d{6}/)
  error_and_exit
end

config = YAML.load_file(config_path)

# configuration file format example
#
# ---
# tsv_submissions_ja: ["wabun-a",
#   "wabun-b",
#   "wabun-c",
#   "wabun-d"]
# tsv_submissions_en: ["trans-a",
#   "trans-b",
#   "trans-c",
#   "trans-d"]
# tsv_tran_ja: "tran_ja"
# tsv_tran_en_ja: "tran_en_ja"
# tsv_tran_en: "tran_en"

$nkf = "#{ROOT_PATH}/script/nkf.rb -Sw"
$prefix = "#{ROOT_PATH}/files"
# generate input/output file name postfix
$date = ARGV[0] || Time.now.strftime("%Y%m%d")

$tsv_submissions = []
(config["tsv_submissions_ja"] + config["tsv_submissions_en"]).each do |filename|
  file_prefix = "#{$prefix}/#{filename}_#{$date}"
  tsv_submission = nil
  if File.exists?("#{file_prefix}.txt")
    tsv_submission = {:file_prefix => file_prefix}
  else
    next
  end
  # convert character code
  system("#{$nkf} #{file_prefix}.txt > #{file_prefix}-utf8-with_header.txt")
  # cut header lines
  open("#{file_prefix}-utf8.txt", "w") do |fw|
    open("#{file_prefix}-utf8-with_header.txt") do |fr|
      line = fr.readline
      record = line.gsub(/\r*\n/, "").split("\t")
      tsv_submission[:columns] = record.size
      fw.puts fr.read
    end
  end
  $tsv_submissions << tsv_submission
end

# from generate_paper_id.rb

# input file format
# 0: id1　　　　受付番号の西暦部分
# 1: id2　　　　受付番号4ケタ
# 2: tmp_id1
# 3: tmp_id2
# 4: tmp_id3
# 5: tmp_id4
# 6: tmp_id5
# 7: submission_id　受付番号
# 8: soccode  特集号コード
# 9: title_j     　和文タイトル
# 10: title_e 　　　英文タイトル
# 11: volume1　掲載号
# 12: inputnum 著者順番
# 13: name_j　　著者名（日本語）
# 14: name_e 　著者名（英語）
# 15: membernum　会員番号
# 16: orgcode　　機関コード
# 17: name_j　　　機関コード名（日本語）
# 18: name_e　　 機関コード名（英語）
# 
# !!!! input file preprocessing required !!!!
# * the first line (column names) should be deleted
# * not required rows (e.g. blank rows) or columns (intermediate data?) should be deleted
#
# processing log can be recorded as follows:
# % ./script/generate_paper_id.rb > log.txt 2>&1

def paper_id(vol, no, ps)
  vol = vol.gsub(/-I$/, "1").gsub(/-II$/, "2")
  "#{vol.downcase}_#{no.downcase}_#{ps.downcase}"
end

def output_error_msg(record, message, basename, line_num)
  # the first line (column names) is deleted before processing
  # and the line_num is the array index (-1), so thus we show line_num plus 2.
  $stderr.puts "#{message} @#{record[7]}, file: #{basename}, line: #{line_num + 2}"
end

def output_with_paper_id(file, record, paper_id)
  file.puts "#{record.join("\t")}\t#{paper_id}"
end

def parse_volume1(record, file, basename, line_num)
  record[11] =~ /Vol.(\w+\d+\-\w+(\-I+)*)\s*,*\s*No.(\d+)\s*,*\s*/
  vol = $1
  no = $3
  record[11] =~ /Vol.\w+\d+\-\w+(\-I+)*\s*,*\s*No.\d+\s*,*\s*pp.(\d+)-(\d+)/
  ps = $2
  pe = $3
  if vol.nil?
    # record NO_VOLUME in paper_id
    output_error_msg(record, "vol is null", basename, line_num)
    output_with_paper_id(file, record, "NO_VOLUME")
  elsif no.nil?
    # currently no entry maches
    output_error_msg(record, "no is null", basename, line_num)
  elsif ps.nil?
    # record NO_PAGES in paper_id
    output_error_msg(record, "ps is null", basename, line_num)
    output_with_paper_id(file, record, "NO_PAGES")
  elsif pe.nil?
    # currently no entry maches
    output_error_msg(record, "pe is null", basename, line_num)
  else
    output_with_paper_id(file, record, paper_id(vol, no, ps))
  end
end

# process ja_paper_submissions
$tsv_submissions.each do |tsv_submission|
  file_prefix = "#{tsv_submission[:file_prefix]}"
  columns = tsv_submission[:columns]
  # for debug
  $stderr.puts "columns = #{columns}"
  basename = File.basename(file_prefix)
  fr = open("#{file_prefix}-utf8.txt")
  fw = open("#{file_prefix}-with_paper_id.txt", "w")
  line_num = 0
  begin
    while true do
      line = fr.readline
      record = line.gsub(/\r*\n/, "").split("\t", columns).map{|i| i.gsub(/\t$/, "")}
      # debug
      if record[-1] =~ /\t/
        output_error_msg(record, "#{columns} columns are assumed but we got #{columns + record[-1].split("\t").size - 1}", basename, line_num)
      end
      while record.size < columns
        # debug
        output_error_msg(record, "line is concatenated because record size (#{record.size}) is smaller than columns (#{columns})", basename, line_num)
        line = fr.readline
        record_tail = line.gsub(/\r*\n/, "").split("\t").map{|i| i.gsub(/\t$/, "")}
        record = record + record_tail
      end
      parse_volume1(record, fw, basename, line_num)
      line_num += 1
    end
  rescue EOFError => e
  rescue => e
    $stderr.puts e.message
  end
  fr.close
  fw.close
end
