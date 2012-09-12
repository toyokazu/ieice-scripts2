#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/tsv_files.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

$config = YAML.load_file(config_path)
$files = $config["tsv_submissions"]

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

def output_error_msg(record, target, basename, line_num)
  # the first line (column names) is deleted before processing
  # and the line_num is the array index (-1), so thus we show line_num plus 2.
  $stderr.puts "#{target} is null @#{record[7]}, file: #{basename}, line: #{line_num + 2}"
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
    output_error_msg(record, "vol", basename, line_num)
    output_with_paper_id(file, record, "NO_VOLUME")
  elsif no.nil?
    # currently no entry maches
    output_error_msg(record, "no", basename, line_num)
  elsif ps.nil?
    # record NO_PAGES in paper_id
    output_error_msg(record, "ps", basename, line_num)
    output_with_paper_id(file, record, "NO_PAGES")
  elsif pe.nil?
    # currently no entry maches
    output_error_msg(record, "pe", basename, line_num)
  else
    output_with_paper_id(file, record, paper_id(vol, no, ps))
  end
end

# process ja_paper_submissions
$files.each do |file|
  extension = File.extname(file)
  basename = File.basename(file, extension)
  output_file = "#{basename}-with_paper_id#{extension}"
  fr = open("#{ROOT_PATH}/files/#{file}")
  fw = open("#{ROOT_PATH}/files/#{output_file}", "w")
  lines = fr.readlines
  lines.each_with_index do |line, i|
    record = line.gsub(/\r*\n/, "").split("\t", 19)
    parse_volume1(record, fw, basename, i)
  end
  fr.close
  fw.close
end
