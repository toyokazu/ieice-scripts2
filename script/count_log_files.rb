#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'tempfile'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = ARGV[0] || "#{ROOT_PATH}/config/count_log_files.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

config = YAML.load_file(config_path)

# configuration file format example
#
# ---
# log_files: search_logs/search_log_*.bak
# output: downloads_count.txt
# ---
#
# search_logs/search_log_*.bak: the file name pattern of the paper search system access log (tsv)
# downloads_count.txt: output file name (tsv)

class ArrayHash < Hash
  def []=(key, value)
    if self[key].class != Array
      super(key, [])
    end
    self[key] << value
  end
end

class DataParser
  class Record
    # define the line format specification of the input tsv file
  end

  def parse!
    # define how to parse the input file
  end
end

class AccessLogParser < DataParser
  class Record
    def initialize(line)
      # for debug
      #$stderr.puts line
      @columns = line.gsub(/\r*\n$/, "").split("\t")
    end

    # 0: 項番  id  int8    
    # 1: 閲覧日時  log_date  varchar 10  yyyymmdd hhmmss
    # 2: ログインユーザ  user_id varchar 100 "環境変数　REMOTE_USER ID or メールアドレス"
    # 3: 会員ソサイエティ  society varchar 5 
    # 4: 閲覧ファイル名  f_name  varchar 100 
    # 5: 分冊  category  varchar 100 
    # 6: 大分類  type  varchar 100 
    # 7: リモートホストアドレス  remote_addr varchar 200 環境変数　REMOTE_ADDR
    # 8: リモートホスト名  remote_host varchar 200 環境変数　REMOTE_HOST
    # 9:  ユーザエージェント  user_agent  varchar 100 環境変数　HTTP_USER_AGENT
    # 10:  リクエストURI uri varchar 500 
    # 11:  ブラウザ  browser varchar 50  
    # 12:  クライアントOS  os  varchar 500 
    # 13:  閲覧状態  err int   "ファイル閲覧時：1 ログイン成功時：2"
    # 14:  ホスト名  host  varchar 200 ホスト名
    # 15:  アクセス種別  access  varchar 1 "・通常ユーザ認証時 ： 0 ・サイトライセンス認証時 ： 1 ・サイトライセンス認証時＋ユーザ認証 ： 2"
    # 16:  あらまし（Summary)閲覧  summary_view  varchar 1 あらまし閲覧時　：　1
    # 17:  archive閲覧フラグ table_of_contents_view  varchar 1 archive閲覧時：1
    # 18:  最新号閲覧フラグ  index_view  varchar 1 最新号閲覧時：1
    # 19:  環境変数：X-Forwarded-For x_forwarded_for varchar 200 環境変数：X-Forwarded-For

    # not used
    def id
      @columns[0]
    end

    def log_date
      @columns[1]
    end

    def user_id
      @columns[2]
    end

    def society
      @columns[3]
    end

    def f_name
      @columns[4]
    end

    def paper_id
      f_name.downcase
      #f_name.downcase.gsub(/\.pdf$/, "")
    end

    def category
      @columns[5]
    end

    def type
      @columns[6]
    end

    def remote_addr
      @columns[7]
    end

    def remote_host
      @columns[8]
    end

    def user_agent
      @columns[9]
    end

    def uri
      @columns[10]
    end

    def browser
      @columns[11]
    end

    def os
      @columns[12]
    end

    def err
      @columns[13]
    end

    def host
      @columns[14]
    end

    def access
      @columns[15]
    end

    def summary_view
      @columns[16]
    end

    def table_of_contents_view
      @columns[17]
    end

    def index_view
      @columns[18]
    end

    def x_forwarded_for
      @columns[19]
    end
  end

  attr_reader :records, :paper_hash, :login_hash
  def initialize(filename)
    @target_file = filename
    # for debug
    $stderr.puts "start processing #{filename}"

    # public attributes
    @records = []
    @paper_hash = ArrayHash.new
    @login_hash = ArrayHash.new

    # private attributes
    # used for parsing multiple lines
    @record = nil
  end

  def already_parsed?
    !@records.empty?
  end

  # detect bot access from user agent string
  # the rules match larger number of entries examined first
  # reference:
  # http://memorva.jp/memo/website/search_engine_robot_agent.php
  # % grep 'bot/' files/search_logs/search_log_201207.bak-utf8 | wc
  # 652511 14338842 184762082
  # % grep 'spider' files/search_logs/search_log_201207.bak-utf8 | wc
  # 315335 6518440 87162940
  # % grep 'robot' files/search_logs/search_log_201207.bak-utf8 | wc
  # 67430 1463960 16879040
  # % grep 'Crawler' files/search_logs/search_log_201207.bak-utf8 | wc
  # 61384 1467339 17533613
  # % grep 'crawler' files/search_logs/search_log_201207.bak-utf8 | wc
  # 57165 1369272 16096563
  # % grep 'Yeti/' files/search_logs/search_log_201207.bak-utf8 | wc
  # 51714 1095863 12436754
  # % grep bot-Mobile search_logs/search_log_201207.bak-utf8 | wc
  # 21443  543728 7547284
  # % grep 'Bot/' files/search_logs/search_log_201207.bak-utf8 | wc
  # 21886  495656 6201784
  # % grep 'Spider' files/search_logs/search_log_201207.bak-utf8 | wc
  # 4462   98209 1417390
  # % grep 'Slurp/' files/search_logs/search_log_201207.bak-utf8 | wc
  # 12     292    3706
  #
  # abuse?
  # % grep e92-b_9_2773.pdf files/search_logs/search_log_201104.bak-utf8 | grep 202.115.65.119 | wc
  # 10277  308308 3174459
  def is_bot?
    if @record.user_agent =~ /bot\// || @record.user_agent =~ /spider/ ||
      @record.user_agent =~ /robot/ || @record.user_agent =~ /Crawler/ ||
      @record.user_agent =~ /crawler/ || @record.user_agent =~ /Yeti\// ||
      @record.user_agent =~ /bot-Mobile/ || @record.user_agent =~ /Bot\// ||
      @record.user_agent =~ /Spider/ || @record.user_agent =~ /Slurp\//
      return true
    end
    false
  end

  def parse!
    if already_parsed?
      return false
    end
    open(@target_file) do |f|
      # skip two lines (maybe changed)
      f.readline
      @lines = f.readlines
    end
    @lines.each do |line|
      @record = Record.new(line)
      #@records << @record
      case @record.type
      when "type"
        #@paper_hash[@record.paper_id] = @record
        #if @record.paper_id !~ /\.pdf$/ || @record.paper_id =~ /\_000\.pdf$/ || @record.err != "1" || @record.summary_view == "1"
        if is_bot? || @record.paper_id !~ /\.pdf$/ || @record.paper_id =~ /\_000\.pdf$/ || @record.err != "1" || @record.summary_view == "1"
          next
        end
        @paper_hash[@record.paper_id] = @record.log_date
      when "login"
        #@login_hash[@record.user_id] = @record
        #@login_hash[@record.user_id] = @record.log_date
      end
    end
  end
end

def load_hash(filename)
  paper_hash = {}
  if !File.exist?(filename)
    return paper_hash
  end
  open(filename) do |f|
    # skip two lines (maybe changed)
    f.readline
    @lines = f.readlines
  end
  @lines.each do |line|
    @columns = line.gsub(/\r*\n$/, "").split(", ")
    paper_hash[@columns[0]] = @columns[1].to_i
  end
  paper_hash
end

def save_hash(paper_hash, config)
  open("#{ROOT_PATH}/files/#{config["output"]}", "w") do |file|
    paper_hash.sort {|a,b| b[1] <=> a[1]}.each do |k, v|
      file.puts "#{k}, #{v}"
    end
  end
end

paper_hash = load_hash("#{ROOT_PATH}/files/#{config["output"]}")
Dir["#{ROOT_PATH}/files/#{config["log_files"]}"].each do |filename|
  utf8_filename = "#{filename}-utf8"
  log = AccessLogParser.new(utf8_filename)
  log.parse!
  # 論文ごとの参照回数を出力
  log.paper_hash.sort.each do |k, v|
    # for debug
    #$stderr.puts "#{k}\t#{v}"
    if paper_hash[k].nil?
      paper_hash[k] = v.size
    else
      paper_hash[k] += v.size
    end
  end
  # 中断・再開できるように途中出力
  save_hash(paper_hash, config)
end

save_hash(paper_hash, config)
