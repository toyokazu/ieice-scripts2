#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'fileutils'

ROOT_PATH = File.expand_path('../../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/cinii_files.yml"

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
# cinii_files: cinii/NII/*/bib-with_paper_id.txt
# tsv_tran_ja: "cinii/tran_ja"
# tsv_tran_en_ja: "cinii/tran_en_ja"
# tsv_tran_en: "cinii/tran_en"

$nkf = "#{ROOT_PATH}/script/nkf.rb -SwLu"
$prefix = "#{ROOT_PATH}/files"
# generate input/output file name postfix
$date = ARGV[0] || Time.now.strftime("%Y%m%d")

$cinii_files = []
Dir["#{ROOT_PATH}/files/#{config["cinii_files"]}.txt"].each do |filename|
  # convert character code
  utf8_filename = "#{filename.match(/([^\s]+)\.txt$/)[1]}-utf8.txt"
  system("#{$nkf} #{filename} > #{utf8_filename}")
  $cinii_files << utf8_filename
end

# from generate_paper_id.rb

# input file format
# 0: id　　　　　　雑誌書誌ID
# 1: vol　　　　　　巻号
# 2: publish_date　　年月次
# 3: type_sym　　　　ページ属性
# 4: title_j　　　　　論文名（日）
# 5: title_jr　　　　　論文名よみ
# 6: title_e　　　　　論文名（英）
# 7: author_j　　　　著者（日）
# 8: author_jr　　　　著者よみ
# 9: author_e　　　　著者（英）
# 10: org_j　　　　　著者所属（日）
# 11: org_e　　　　　著者所属（英）
# 12: pages　　　　　ページ
# 13: type_name_j　　記事種別（日）
# 14: type_name_e　　記事種別（英）
# 15: lang　　　　　言語
# 16: abstract_j　　抄録（日）
# 17: abstract_e　　抄録（英）
# 18: keyword_j　　　キーワード（日）
# 19: keyword_e　　　キーワード（英）
# 20: presen_num　　レポート・講演番号
# 21: pdf_name　　　PDFファイル名
# 22: uri　　　　　　URL
# 23: disp_order　　表示順
# 24: file_name　　　アクション番号（PDFファイル名の拡張子を除いたもの）
# 25: del_flag　　　削除フラグ
# 26: paper_id　　　論文ID
#
# !!!! input file preprocessing required !!!!
# * not required rows (e.g. blank rows) or columns (intermediate data?) should be deleted

def skip?(record)
  # pages または author_j & author_e または org_j & org_e が空欄のものはスキップする？
  record[12].empty? || (record[7].empty? && record[9].empty?) || (record[10].empty? && record[11].empty?)
end

def paper_id(vol, no, ps)
  vol = vol.gsub(/-I$/, "1").gsub(/-II$/, "2").gsub(/-1$/, "1").gsub(/-2$/, "2")
  "#{vol.downcase}_#{no.downcase}_#{ps.downcase}"
end

def output_error_msg(record, message, filename, line_num)
  # the line_num is the array index (-1), so thus we show line_num plus 1.
  $stderr.puts "#{message} @#{record[7]}, file: #{filename}, line: #{line_num + 1}"
end

def output_with_paper_id(file, record, paper_id)
  file.puts "#{record.join("\t")}\t#{paper_id}"
end

def parse_vol(record, file, filename, line_num)
  record[1] =~ /(\w+\-\w+(\-[\dI]+)*)\((\d+)\)\s*/
  vol = $1
  no = $3
  record[12] =~ /(\d+)(\-(\d+))*/
  ps = $1
  pe = $3
  if vol.nil?
    # record NO_VOLUME in paper_id
    output_error_msg(record, "vol is null", filename, line_num)
    output_with_paper_id(file, record, "NO_VOLUME")
  elsif no.nil?
    # currently no entry maches
    output_error_msg(record, "no is null", filename, line_num)
  elsif ps.nil?
    # record NO_PAGES in paper_id
    output_error_msg(record, "ps is null", filename, line_num)
    output_with_paper_id(file, record, "NO_PAGES")
  #elsif pe.nil?
    # currently no entry maches
  #  output_error_msg(record, "pe is null", filename, line_num)
  else
    output_with_paper_id(file, record, paper_id(vol, no, ps))
  end
end

columns = 26

# process ja_paper_submissions
$cinii_files.each do |filename|
  output = "#{filename.match(/([^\s]+)\-utf8\.txt$/)[1]}-with_paper_id.txt"
  fr = open(filename)
  fw = open(output, "w")
  line_num = 0
  begin
    while true do
      line = fr.readline
      record = line.gsub(/\r*\n/, "").split("\t", columns).map{|i| i.gsub(/\t$/, "")}
      if skip?(record)
        line_num += 1
        next
      end
      # debug
      if record[-1] =~ /\t/
        output_error_msg(record, "#{columns} columns are assumed but we got #{columns + record[-1].split("\t", columns).size - 1}", filename, line_num)
      end
      while record.size < columns
        # debug
        output_error_msg(record, "line is concatenated because record size (#{record.size}) is smaller than columns (#{columns})", filename, line_num)
        line = fr.readline
        record_tail = line.gsub(/\r*\n/, "").split("\t").map{|i| i.gsub(/\t$/, "")}
        record[-1] = record[-1] + record_tail[0]
        record = record + record_tail[1..-1]
      end
      parse_vol(record, fw, filename, line_num)
      line_num += 1
    end
  rescue EOFError => e
  rescue => e
    $stderr.puts e.message
  end
  fr.close
  fw.close
end
