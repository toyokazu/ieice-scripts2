#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'sqlite3'

# usage:
# output_merged_tsv.rb ja 2> logs/log_ja.txt
# output_merged_tsv.rb en 2> logs/log_en.txt

ROOT_PATH = File.expand_path('../../',  __FILE__)

tsv_config_path = "#{ROOT_PATH}/config/tsv_files.yml"
db_config_path = "#{ROOT_PATH}/config/database.yml"

if !File.exists?(db_config_path)
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
  $submissions = "ja_paper_submissions"
  $metadata = "ja_paper_metadata"
  $en_ja_metadata = "en_ja_paper_metadata"
  $output_file = open("#{ROOT_PATH}/files/#{$tsv_config["tsv_tran_ja"]}_#{$date}.txt", "w")
  $en_ja_output_file = open("#{ROOT_PATH}/files/#{$tsv_config["tsv_tran_en_ja"]}_#{$date}.txt", "w")
when 'en'
  $submissions = "en_paper_submissions"
  $metadata = "en_paper_metadata"
  $output_file = open("#{ROOT_PATH}/files/#{$tsv_config["tsv_tran_en"]}_#{$date}.txt", "w")
else
  error_and_exit
end


$db = SQLite3::Database.new("#{ROOT_PATH}/files/#{$db_config["paper_db"]}")

# *_paper_submissions schema
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
  metadata[15].gsub("　", " ").gsub(/\s+/, " ").split("＠")
end

def normalize(name)
  names = name.split(" ").map {|s| s.capitalize}
  # if name is empty (""), return itself ("").
  if names[-1].nil?
    return name
  end
  names[-1] = names[-1].upcase
  names.join(" ")
end

def authorname(submission, target = $target)
  case target
  when 'ja'
    normalize(submission[13].gsub("　", " ").gsub(/\s+/, " "))
  when 'en'
    normalize(submission[14].gsub("　", " ").gsub(/\s+/, " "))
  end
end

def submit_authors(submissions, target = $target)
  submissions.map {|s| authorname(s, target)}
end

def orgname(submission, target = $target)
  orgname = nil
  case target
  when 'ja'
    orgname = submission[17].gsub("　", " ").gsub(/\s+/, " ")
  when 'en'
    orgname =submission[18].gsub("　", " ").gsub(/\s+/, " ")
  end
  (orgname.nil? || orgname.empty?) ? "" : "＠#{orgname}"
end

def membernum(submission)
  membernum = submission[15]
  (membernum.nil? || membernum.empty?) ? "" : "（#{membernum}）"
end

# == authors_with_affiliations
# add "（member_number）＠affiliation" which are extracted from submissions to the authors
# authors: author data extracted from the paper search system data (metadata)
# submissions: paper submission system data (submit)
# target: 'ja'/'en'
def authors_with_affiliations(authors, submissions, target = $target)
  authors_with_affiliations = []
  authors.each_with_index do |author, i|
    s = submissions[i]
    # DIFF_NUM_META_JA_EN
    if s.nil?
      return authors_with_affiliations
    end
    authors_with_affiliations << "#{author}#{membernum(s)}#{orgname(s, target)}"
  end
  authors_with_affiliations
end

# == comment
# generate comment for helping error correction
# authors1: metadata_authors or ja metadata_authors
# authors2: submit_authors or en metadata_authors
def comment(error_msg, authors1, authors2, submissions, target = $target)
  "#{error_msg}：【#{authors1.join("＠")}】：【#{authors2.join("＠")}】：【#{authors_with_affiliations(authors2, submissions, target).join("；")}】"
end

def output_paper(file, paper, author, comment = "COMPLETED")
  file.puts "#{paper[0..14].join("\t")}\t#{author}\t#{paper[16..28].join("\t")}\t#{comment}"
end

$papers = $db.execute("select paper_id from #{$submissions} where paper_id != 'NO_PAGES' and paper_id != 'NO_VOLUME' group by paper_id order by paper_id asc;")
$papers = $papers.map {|p| p[0]}

# == ERROR MESSAGES
# The output tsv file includes comment for each line. The comment includes the following messages.
#
# COMPLETED: the paper_id and the authors are matched between the paper submission system data
# (submit) and paper search system data (metadata).
#
# DIFF_NUM_SUBMIT: the number of authors in 'submit' is different from 'metadata'.
# the differences are shown in succesion.
#
# e.g., DIFF_NUM_SUBMIT：【meta_author1＠meta_author2＠meta_author3】：【submit_author1＠submit_author2＠submit_author3＠submit_author4】：【submit_author1＠affiliation1；submit_author2（membernum2）＠affiliation2；submit_author3（membernum3）＠affiliation3；submit_author4（membernum4）＠affiliation4】
#
# If you want to adapt this collation as production data, you must replace submit_authorX to
# meta_authorX. In case of reorder, you must carefully replace them (in this example, you must
# remove submit_author4).
#
# DIFF_OTHER_SUBMIT: the order of the authors or the characters of author names in 'submit' are different
# from 'metadata'.
#
# e.g., DIFF_OTHER_SUBMIT：【meta_author1＠meta_author2＠meta_author3】：【submit_author1＠submit_author2＠submit_author3】：【submit_author1＠affiliation1；submit_author2（membernum2）＠affiliation2；submit_author3（membernum3）＠affiliation3】
#
# If you want to adapt this collation as production data, you must replace submit_authorX to
# meta_authorX. In case of reorder, you must carefully replace them.
#
# DIFF_NUM_META_JA_EN: the number of authors in 'ja' 'metadata' is different from 'en' 'metadata'.
#
# e.g., DIFF_NUM_META_JA_EN：【ja_meta_author1＠ja_meta_author2＠ja_meta_author3】：【en_meta_author1＠en_meta_author2＠en_meta_author3】：【en_meta_author1＠affiliation1；en_meta_author2（membernum2）＠affiliation2；en_meta_author3（membernum3）＠affiliation3】
#
# NO_MATCH: no 'submit' data is found.
#
# if there are papers found in 'submit' but not in 'metadata', they are printed to stderr
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
  submissions = $db.execute("select * from #{$submissions} where paper_id = ? order by inputnum asc;", paper_id)
  # author list
  authors = authors(paper)
  en_ja_authors = nil
  if $target == 'ja' && !en_ja_paper.nil?
    en_ja_authors = authors(en_ja_paper)
  end
  # submissions author list
  # s[13]: author (name_j)
  submit_authors = submit_authors(submissions)
  # compare author list
  if authors.size != submit_authors.size
    $stderr.puts "the number of author list does not match @#{paper_id}"
    $stderr.puts "metadata: #{authors.join("＠")}"
    $stderr.puts "submit  : #{submit_authors.join("＠")}"
    output_paper($output_file, paper, authors(paper).join("；"), comment("DIFF_NUM_SUBMIT", authors, submit_authors, submissions))
    if $target == 'ja' && !en_ja_paper.nil?
      output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), comment("DIFF_NUM_SUBMIT", authors(en_ja_paper), submit_authors(submissions, 'en'), submissions, 'en'))
    end
    next
  elsif authors.join("＠").gsub(/\s/, "") != submit_authors.join("＠").gsub(/\s/, "") # ignore spaces to reduce exceptions
    $stderr.puts "author list does not match @#{paper_id}"
    $stderr.puts "metadata: #{authors.join("＠")}"
    $stderr.puts "submit  : #{submit_authors.join("＠")}"
    output_paper($output_file, paper, authors(paper).join("；"), comment("DIFF_OTHER_SUBMIT", authors, submit_authors, submissions))
    if $target == 'ja' && !en_ja_paper.nil?
      output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), comment("DIFF_OTHER_SUBMIT", authors(en_ja_paper), submit_authors(submissions, 'en'), submissions, 'en'))
    end
    next
  end
  output_paper($output_file, paper, authors_with_affiliations(authors, submissions).join("；"))

  if $target == 'ja' && !en_ja_paper.nil?
    if en_ja_authors.size != authors.size
      $stderr.puts "the number of ja/en author list does not match @#{paper_id}"
      $stderr.puts "ja metadata: #{authors.join("＠")}"
      $stderr.puts "en metadata: #{en_ja_authors.join("＠")}"
      output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), comment("DIFF_NUM_META_JA_EN", authors, en_ja_authors, submissions, 'en'))
      next
    end
    output_paper($en_ja_output_file, en_ja_paper, authors_with_affiliations(en_ja_authors, submissions, 'en').join("；"))
  end
end

$rest_papers = $db.execute("select * from #{$metadata} where id not in (select paper_id from #{$submissions} where paper_id != 'NO_PAGES' and paper_id != 'NO_VOLUME' group by paper_id order by paper_id asc) order by id;")
# output the rest of papers exactly as it was
$rest_papers.each do |paper|
  output_paper($output_file, paper, authors(paper).join("；"), "NO_MATCH")
end
$output_file.close

if $target == 'ja'
  $en_ja_rest_papers = $db.execute("select * from #{$en_ja_metadata} where id not in (select paper_id from #{$submissions} where paper_id != 'NO_PAGES' and paper_id != 'NO_VOLUME' group by paper_id order by paper_id asc) order by id;")
  $en_ja_rest_papers.each do |en_ja_paper|
    output_paper($en_ja_output_file, en_ja_paper, authors(en_ja_paper).join("；"), "NO_MATCH")
  end
  $en_ja_output_file.close
end
