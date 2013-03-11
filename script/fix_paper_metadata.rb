#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'fileutils'

def error_and_exit
  $stderr.puts "usage: fix_paper_metadata.rb input_file_name [30columns]"
  exit 1
end

if ARGV.size < 1
  error_and_exit
end

# *_paper_metadata schema
# 0: id, 文献ID
# 1: vol, 巻 (年, ソサイエティ) Vol
# 2: num, 号 Num
# 3: s_page, 開始ページ番号
# 4: e_page, 終了ページ番号
# 5: date, 発行年月
# 6: title, タイトル【検索用】
# 7: author, 著者【検索用】
# 8: abstract, 概要【検索用】
# 9: keyword, キーワード（全角カンマ区切り）【検索用】
# 10: special, 特集号名
# 11: category1, 論文種別 (論文, レター)
# 12: category2, 専門分野分類コード（大項目）
# 13: category3, 専門分野分類名（大項目）※目次の見出しに利用
# 14: disp_title, タイトル【表示用】
# 15: disp_author, 著者名【表示用】
# 16: disp_abstract, 概要【表示用】
# 17: disp_keyword, キーワード（全角カンマ区切り）【表示用】
# 18: err_fname, 正誤Web PDF
# 19: err_comm, 正誤内容
# 20: nodisp_comm, 非表示
# 21: delflg, 削除
# 22: mmflg, MM情報
# 23: l_auth_pdf, レター著者PDF
# 24: l_auth_link, レター著者内容
# 25: err_1, 訂正元ファイル名
# 26: err_2, 訂正先ファイル名
# 27: recommend, 推薦論文
# 28: 目次脚注正誤PDF
# 29: XXXX

$filename = ARGV[0]
$line_num = 0
$col30 = (ARGV[1] == "true")

def output_error_msg(record, message)
  $stderr.puts "#{message} @#{record[0]}, file: #{$filename}, line: #{$line_num}"
end

open($filename) do |f|
  begin
    while true do
      line = f.readline
      $line_num += 1
      record = line.gsub(/\r*\n/, "").split("\t", 30).map{|i| i.gsub(/\t$/, "")}
      if record.size == 29
        $stdout.puts "#{record.join("\t")}\t"
      elsif record.size == 30 && $col30
        $stdout.puts record.join("\t")
      else
        output_error_msg(record, "The number of columns is assumed to be 29 or 30, but #{record.size}.")
      end
    end
  rescue EOFError => e
  end
end
