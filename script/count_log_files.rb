#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'tempfile'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/count_log_files.yml"

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

  attr_reader :records, :paper_hash, :remote_addr_hash, :login_hash
  def initialize(filename)
    @target_file = filename
    # for debug
    $stderr.puts "start processing #{filename}"

    # extract month
    @target_file =~ /search_log_(\d{6}).bak-utf8/
    @month = $1

    # public attributes
    @records = []
    @paper_hash = {}
    @remote_addr_hash = {}
    @num_bots = 0
    @num_others = 0
    @login_hash = {}

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
        if is_bot?
          @num_bots += 1
          next
        elsif @record.paper_id !~ /[ej]\d{2}-[a-d]_\d+_\d+\.pdf$/ || @record.paper_id =~ /\_000\.pdf$/ || @record.err != "1" || @record.summary_view == "1"
          # to skip entries like j94-b_2_156_seigo.pdf and e88-b_3_1294year=2005
          # specify filename pattern more strictly
          @num_others += 1
          next
        end
        calc_stat(@record.paper_id, @record.remote_addr)
      when "login"
        #@login_hash[@record.user_id] = @record
        #@login_hash[@record.user_id] = @record.log_date
      end
    end
  end

  def calc_stat(paper_id, remote_addr)
    # count paper access
    if @paper_hash[paper_id].nil?
      @paper_hash[paper_id] = {"paper" => 1, "remote_addr" => {}}
    else
      @paper_hash[paper_id]["paper"] += 1
    end

    # count remote_addr
    if @remote_addr_hash[remote_addr].nil?
      @remote_addr_hash[remote_addr] = {"paper" => {}, "remote_addr" => 1}
    else
      @remote_addr_hash[remote_addr]["remote_addr"] += 1
    end

    # count remote_addr per paper
    if @paper_hash[paper_id]["remote_addr"][remote_addr].nil?
      @paper_hash[paper_id]["remote_addr"][remote_addr] = 1
    else
      @paper_hash[paper_id]["remote_addr"][remote_addr] += 1
    end

    # count paper per remote_addr
    if @remote_addr_hash[remote_addr]["paper"][paper_id].nil?
      @remote_addr_hash[remote_addr]["paper"][paper_id] = 1
    else
      @remote_addr_hash[remote_addr]["paper"][paper_id] += 1
    end
  end

  def month_stat
    # extract month stat
    paper_hash = {}
    remote_addr_hash = {}
    
    # calc paper count
    # -> these codes must be fixed (not finished yet)
    # -> paper_hash, remote_addr_hash should be replaced as a stats hash to save memory and strage space
    @paper_hash.each do |paper_id, entry|
      if paper_hash[paper_id].nil?
        paper_hash[paper_id] = {"paper" => entry["paper"],
                                "remote_addr_uniq" => entry["remote_addr"].keys.size,
                                "remote_addr" => entry["remote_addr"].values.inject(0) {|sum, i| sum + i}}
      else
        paper_hash[paper_id]["paper"] += entry["paper"]
        paper_hash[paper_id]["remote_addr_uniq"] += entry["remote_addr"].keys.size
        paper_hash[paper_id]["remote_addr"] += entry["remote_addr"].values.inject(0) {|sum, i| sum + i}
      end
    end

    @remote_addr_hash.each do |remote_addr, entry|
      if remote_addr_hash[remote_addr].nil?
        remote_addr_hash[remote_addr] = {"remote_addr" => entry["remote_addr"],
                                         "paper_uniq" => entry["paper"].keys.size,
                                         "paper" => entry["paper"].values.inject(0) {|sum, i| sum + i}}
      else
        remote_addr_hash[remote_addr]["remote_addr"] += entry["remote_addr"]
        remote_addr_hash[remote_addr]["paper_uniq"] += entry["paper"].keys.size
        remote_addr_hash[remote_addr]["paper"] += entry["paper"].values.inject(0) {|sum, i| sum + i}
      end
    end

    # calc avg_paper, var_paper, dev_paper
    avg_paper = 0
    num_paper = 0
    thresh_num_paper = 0
    paper_threshold = 4
    @paper_hash.values.each do |v|
      if v["paper"] > paper_threshold
        avg_paper += v["paper"]
        thresh_num_paper += 1
      end
      num_paper += 1
    end
    avg_paper = avg_paper / thresh_num_paper
    var_paper = 0
    paper_hash.values.each do |v|
      if v["paper"] > paper_threshold
        var_paper += (v["paper"] - avg_paper) ** 2
      end
    end
    var_paper = var_paper / thresh_num_paper
    dev_paper = Math::sqrt(var_paper)

    # calc avg_remote_addr, var_remote_addr, dev_remote_addr
    avg_remote_addr = 0
    num_remote_addr = 0
    thresh_num_remote_addr = 0
    remote_addr_threshold = 4
    remote_addr_hash.values.each do |v|
      if v["remote_addr"] > remote_addr_threshold
        avg_remote_addr += v["remote_addr"]
        thresh_num_remote_addr += 1
      end
      num_remote_addr += 1
    end
    avg_remote_addr = avg_remote_addr / thresh_num_remote_addr
    var_remote_addr = 0
    remote_addr_hash.values.each do |v|
      if v["remote_addr"] > remote_addr_threshold
        var_remote_addr += (v["remote_addr"] - avg_remote_addr) ** 2
      end
    end
    var_remote_addr = var_remote_addr / thresh_num_remote_addr
    dev_remote_addr = Math::sqrt(var_remote_addr)
    {@month => {
        "paper" => paper_hash,
        "avg_paper" => avg_paper,
        "var_paper" => var_paper,
        "dev_paper" => dev_paper,
        "num_paper" => num_paper,
        "thresh_num_paper" => thresh_num_paper,
        #"paper" => @paper_hash,
        "remote_addr" => remote_addr_hash,
        "avg_remote_addr" => avg_remote_addr,
        "var_remote_addr" => var_remote_addr,
        "dev_remote_addr" => dev_remote_addr,
        "num_remote_addr" => num_remote_addr,
        "thresh_num_remote_addr" => thresh_num_remote_addr,
        "num_bots" => @num_bots,
        "num_others" => @num_others,
        #"remote_addr" => @remote_addr_hash,
        #"login" => @login_hash
      }
    }
  end
end

def load_hash(config)
  filename = "#{ROOT_PATH}/files/#{config["month_stats"]}"
  log_hash = {}
  if !File.exist?(filename)
    return log_hash
  end
  open(filename) do |f|
    log_hash = YAML.load_file(filename)
  end
  log_hash
end

def save_hash(log_hash, config)
  open("#{ROOT_PATH}/files/#{config["month_stats"]}", "w") do |file|
    file.puts log_hash.to_yaml
  end
end

# 689.6698924637 is determined by statistics of all paper and remote_addr data.
MAX_PAPER_PER_MONTH = 689.6698924637
def save_stat(log_hash, config)
  paper_hash = {}
  remote_addr_hash = {}
  log_hash.sort.each do |k, hash|
    hash["paper"].sort.each do |paper_id, entry|
      if paper_hash[paper_id].nil?
        paper_hash[paper_id] = {"paper" => entry["paper"],
                                "remote_addr_uniq" => entry["remote_addr_uniq"],
                                "remote_addr" => entry["remote_addr"]}
      else
        if entry["paper"] < MAX_PAPER_PER_MONTH
          paper_hash[paper_id]["paper"] += entry["paper"]
        else
          paper_hash[paper_id]["paper"] += MAX_PAPER_PER_MONTH.to_i
        end
        paper_hash[paper_id]["remote_addr_uniq"] += entry["remote_addr_uniq"]
        paper_hash[paper_id]["remote_addr"] += entry["remote_addr"]
      end
    end
    hash["remote_addr"].sort.each do |remote_addr, entry|
      if remote_addr_hash[remote_addr].nil?
        remote_addr_hash[remote_addr] = {"remote_addr" => entry["remote_addr"],
                                         "paper_uniq" => entry["paper_uniq"],
                                         "paper" => entry["paper"]}
      else
        remote_addr_hash[remote_addr]["remote_addr"] += entry["remote_addr"]
        remote_addr_hash[remote_addr]["paper_uniq"] += entry["paper_uniq"]
        remote_addr_hash[remote_addr]["paper"] += entry["paper"]
      end
    end
  end

  # output paper rank
  open("#{ROOT_PATH}/files/#{config["output"]}", "w") do |file|
    paper_hash.sort {|a,b| b[1]["paper"] <=> a[1]["paper"]}.each do |k,v|
      file.puts "#{k.gsub("\.pdf", "")},#{v["paper"]}"
    end
  end

  # output stats
  #open("#{ROOT_PATH}/files/#{config["stats_output"]}", "w") do |file|
  #  file.puts stats_hash.to_yaml
  #end

  # $stderr.puts "remote_addr_uniq / paper count ---"
  # paper_hash.sort {|a,b| b[1]["remote_addr_uniq"] <=> a[1]["remote_addr_uniq"]}.each do |k,v|
  #   $stderr.puts "#{k},#{v["remote_addr_uniq"]}"
  # end
  # $stderr.puts "remote_addr / paper count ---"
  # paper_hash.sort {|a,b| b[1]["remote_addr"] <=> a[1]["remote_addr"]}.each do |k,v|
  #   $stderr.puts "#{k},#{v["remote_addr"]}"
  # end

  # $stderr.puts "remote_addr count ---"
  # remote_addr_hash.sort {|a,b| b[1]["remote_addr"] <=> a[1]["remote_addr"]}.each do |k,v|
  #   $stderr.puts "#{k},#{v["remote_addr"]}"
  # end

  # $stderr.puts "paper_uniq / remote_addr count ---"
  # remote_addr_hash.sort {|a,b| b[1]["paper_uniq"] <=> a[1]["paper_uniq"]}.each do |k,v|
  #   $stderr.puts "#{k},#{v["paper_uniq"]}"
  # end

  # $stderr.puts "paper / remote_addr count ---"
  # remote_addr_hash.sort {|a,b| b[1]["paper"] <=> a[1]["paper"]}.each do |k,v|
  #   $stderr.puts "#{k},#{v["paper"]}"
  # end
end

$log_hash = load_hash(config)
Dir["#{ROOT_PATH}/files/#{config["log_files"]}"].each do |filename|
  log = AccessLogParser.new(filename)
  log.parse!
  $log_hash = $log_hash.merge(log.month_stat)
  # 中断・再開できるように途中出力
  save_hash($log_hash, config)
end

save_stat($log_hash, config)
