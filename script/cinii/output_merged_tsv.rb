#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'sqlite3'

# usage:
# output_merged_tsv.rb ja 2> logs/log_ja.txt
# output_merged_tsv.rb en 2> logs/log_en.txt

ROOT_PATH = File.expand_path('../../../',  __FILE__)

tsv_config_path = "#{ROOT_PATH}/config/cinii_files.yml"
db_config_path = "#{ROOT_PATH}/config/database.yml"

if !File.exists?(tsv_config_path)
  puts "can not find configuration file: #{tsv_config_path}"
  exit 1
elsif !File.exists?(db_config_path)
  puts "can not find configuration file: #{db_config_path}"
  exit 1
end

$tsv_config = YAML.load_file(tsv_config_path)
$db_config = YAML.load_file(db_config_path)

def error_and_exit
  $stderr.puts "usage: output_merged_tsv.rb ja|en [YYYYMMDD]"
  $stderr.puts "arguments:"
  $stderr.puts "    must: ja|en"
  $stderr.puts "    optional: YYYYMMDD"
  exit 1
end

if ARGV.size < 1
  error_and_exit
end

$target = ARGV[0]

# generate input/output file name postfix
$date = ARGV[1] || Time.now.strftime("%Y%m%d")

# initialize language dependent parameters
case $target
when 'ja'
  $metadata = "ja_paper_metadata"
  $en_ja_metadata = "en_ja_paper_metadata"
  $output_file = open("#{ROOT_PATH}/files/cinii/#{$tsv_config["tsv_tran_ja"]}_#{$date}-with_comment.txt", "w")
  $en_ja_output_file = open("#{ROOT_PATH}/files/cinii/#{$tsv_config["tsv_tran_en_ja"]}_#{$date}-with_comment.txt", "w")
when 'en'
  $metadata = "en_paper_metadata"
  $output_file = open("#{ROOT_PATH}/files/cinii/#{$tsv_config["tsv_tran_en"]}_#{$date}-with_comment.txt", "w")
else
  error_and_exit
end


$db = SQLite3::Database.new("#{ROOT_PATH}/files/cinii/#{$db_config["paper_db"]}")

# cinii_metadata schema
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

def authors(metadata)
  return [] if metadata[15].nil?
  metadata[15].gsub("　", " ").gsub(/\s+/, " ").split("；").map{|name| normalize(name)}
end

# normalize names (both cinii_metadata and paper_metadata)
# examples:
# Shingaku Tarou
# Shingaku Comm Tarou
def normalize(name)
  names = name.split(" ").map {|s| s.capitalize}
  # if name is empty (""), return itself ("").
  if names[-1].nil?
    return name
  end
  # if you want to normalize like "Shingaku TAROU", uncomment the followings.
  names[-1] = names[-1].upcase
  names.join(" ")
end

def cinii_authors(cinii_metadata, target = $target)
  case target
  when 'ja'
    cinii_authors = cinii_metadata[7].split(/\s*\/\s*/).map {|s| normalize(s.gsub("\"","").gsub(",", " "))}
  when 'en'
    # english names in CiNii is reverse order to IEICE
    cinii_authors = cinii_metadata[9].split(/\s*\/\s*/).map {|s| normalize(s.gsub("\"","").split(",").reverse.join(" "))}
  end
  cinii_authors
end

def cinii_orgnames(cinii_metadata, target = $target)
  cinii_orgnames = []
  case target
  when 'ja'
    cinii_orgnames = cinii_metadata[10].gsub("\"", "").split(/\s*\/\s*/)
  when 'en'
    cinii_orgnames = cinii_metadata[11].gsub("\"", "").split(/\s*\/\s*/)
  end
  cinii_orgnames
end

# == authors_with_affiliations
# add "（member_number）＠affiliation" which are extracted from cinii_metadata to the authors
# authors: author data extracted from the paper search system data (paper_metadata)
# cinii_metadata: cinii metadata (cinii_metadata)
# target: 'ja'/'en'
def authors_with_affiliations(authors, cinii_metadata, target = $target)
  authors_with_affiliations = []
  cinii_orgnames = cinii_orgnames(cinii_metadata, target)
  authors.each_with_index do |author, i|
    authors_with_affiliations << "#{author}＠#{cinii_orgnames[i]}"
  end
  authors_with_affiliations
end

# == comment
# generate comment for helping error correction
# authors1: metadata_authors or ja metadata_authors
# authors2: cinii_authors or en metadata_authors
def comment(error_msg, authors1, authors2, cinii_metadata, target = $target)
  "#{error_msg}：【#{authors1.join("＠")}】：【#{authors2.join("＠")}】：【#{authors_with_affiliations(authors2, cinii_metadata, target).join("；")}】"
end

def output_paper(file, paper, author, comment = "COMPLETED")
  file.puts "#{paper[0..14].join("\t")}\t#{author}\t#{paper[16..28].join("\t")}\t#{comment}"
end

$target_cond = ''
case $target
when 'ja'
  $target_cond = "'j%'"
when 'en'
  $target_cond = "'e%'"
end
$papers = $db.execute("select paper_id from cinii_metadata where paper_id like #{$target_cond} and paper_id != 'NO_PAGES' and paper_id != 'NO_VOLUME' group by paper_id order by paper_id asc;")
$papers = $papers.map {|p| p[0]}

# == ERROR MESSAGES
# The output tsv file includes comment for each line. The comment includes the following messages.
#
# COMPLETED: the paper_id and the authors are matched between the cinii data
# (cinii_metadata) and paper search system data (paper_metadata).
#
# DIFF_NUM_CINII: the number of authors in 'cinii_metadata' is different from 'paper_metadata'.
# the differences are shown in succesion.
#
# e.g., DIFF_NUM_CINII：【meta_author1＠meta_author2＠meta_author3】：【cinii_author1＠cinii_author2＠cinii_author3＠cinii_author4】：【cinii_author1＠affiliation1；cinii_author2＠affiliation2；cinii_author3＠affiliation3】
#
# If you want to adapt this collation as production data, you must replace cinii_authorX to
# meta_authorX. In case of reorder, you must carefully replace them (in this example, you must
# remove cinii_author4).
#
# DIFF_OTHER_CINII: the order of the authors or the characters of author names in 'cinii_metadata' are different
# from 'paper_metadata'.
#
# e.g., DIFF_OTHER_CINII：【meta_author1＠meta_author2＠meta_author3】：【cinii_author1＠cinii_author2＠cinii_author3】：【cinii_author1＠affiliation1；cinii_author2＠affiliation2；cinii_author3＠affiliation3】
#
# If you want to adapt this collation as production data, you must replace cinii_authorX to
# meta_authorX. In case of reorder, you must carefully replace them.
#
# DIFF_NUM_META_JA_EN: the number of authors in 'ja' 'metadata' is different from 'en' 'metadata'.
#
# e.g., DIFF_NUM_META_JA_EN：【ja_meta_author1＠ja_meta_author2＠ja_meta_author3】：【en_meta_author1＠en_meta_author2＠en_meta_author3】：【en_meta_author1＠affiliation1；en_meta_author2（membernum2）＠affiliation2；en_meta_author3（membernum3）＠affiliation3】
#
# NO_MATCH: no 'cinii_metadata' data is found.
#
# if there are papers found in 'cinii_metadata' but not in 'paper_metadata', they are printed to stderr
# as "#{paper_id} is not found in #{metadata}".

$papers.each do |paper_id|
  paper = $db.execute("select * from #{$metadata} where id = ?;", paper_id).first
  en_ja_paper = nil
  # if 'ja' is specified, en_ja_metadata should also be handled together
  if $target == 'ja'
    en_ja_paper = $db.execute("select * from #{$en_ja_metadata} where id = ?;", paper_id).first
  end
  # 
  if paper.nil? || paper.empty?
    $stderr.puts "#{paper_id} is not found in #{$metadata}"
    next
  end
  cinii_metadata = $db.execute("select * from cinii_metadata where paper_id = ?;", paper_id).first
  # author list
  authors = authors(paper)
  en_ja_authors = nil
  if $target == 'ja' && !en_ja_paper.nil?
    en_ja_authors = authors(en_ja_paper)
  end
  cinii_authors = cinii_authors(cinii_metadata)
  # compare author list
  if authors.size != cinii_authors.size
    $stderr.puts "the number of author list does not match @#{paper_id}"
    $stderr.puts "metadata: #{authors.join("＠")}"
    $stderr.puts "cinii  : #{cinii_authors.join("＠")}"
    output_paper($output_file, paper, authors(paper).join("；"), comment("DIFF_NUM_CINII", authors, cinii_authors, cinii_metadata))
    if $target == 'ja' && !en_ja_paper.nil?
      output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), comment("DIFF_NUM_CINII", authors(en_ja_paper), cinii_authors(cinii_metadata, 'en'), cinii_metadata, 'en'))
    end
    next
  elsif authors.join("＠").gsub(/\s/, "") != cinii_authors.join("＠").gsub(/\s/, "") # ignore spaces to reduce exceptions
    $stderr.puts "author list does not match @#{paper_id}"
    $stderr.puts "metadata: #{authors.join("＠")}"
    $stderr.puts "cinii  : #{cinii_authors.join("＠")}"
    output_paper($output_file, paper, authors(paper).join("；"), comment("DIFF_OTHER_CINII", authors, cinii_authors, cinii_metadata))
    if $target == 'ja' && !en_ja_paper.nil?
      output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), comment("DIFF_OTHER_CINII", authors(en_ja_paper), cinii_authors(cinii_metadata, 'en'), cinii_metadata, 'en'))
    end
    next
  end
  output_paper($output_file, paper, authors_with_affiliations(authors, cinii_metadata).join("；"))

  if $target == 'ja' && !en_ja_paper.nil?
    if en_ja_authors.size != authors.size
      $stderr.puts "the number of ja/en author list does not match @#{paper_id}"
      $stderr.puts "ja metadata: #{authors.join("＠")}"
      $stderr.puts "en metadata: #{en_ja_authors.join("＠")}"
      output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), comment("DIFF_NUM_META_JA_EN", authors, en_ja_authors, cinii_metadata, 'en'))
      next
    end
    output_paper($en_ja_output_file, en_ja_paper, authors_with_affiliations(en_ja_authors, cinii_metadata, 'en').join("；"))
  end
end

$rest_papers = $db.execute("select * from #{$metadata} where id not in (select paper_id from cinii_metadata where paper_id != 'NO_PAGES' and paper_id != 'NO_VOLUME' group by paper_id order by paper_id asc) order by id;")
# output the rest of papers exactly as it was
$rest_papers.each do |paper|
  output_paper($output_file, paper, authors(paper).join("；"), "NO_MATCH")
end
$output_file.close

if $target == 'ja'
  $en_ja_rest_papers = $db.execute("select * from #{$en_ja_metadata} where id not in (select paper_id from cinii_metadata where paper_id != 'NO_PAGES' and paper_id != 'NO_VOLUME' group by paper_id order by paper_id asc) order by id;")
  $en_ja_rest_papers.each do |en_ja_paper|
    output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), "NO_MATCH")
  end
  $en_ja_output_file.close
end
