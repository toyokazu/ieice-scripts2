#!/usr/bin/env ruby

require 'systemu'

ROOT_PATH = File.expand_path('../../',  __FILE__)

if ARGV.size < 2
  $stderr.puts "usage: count_access_log.rb target_paper_id target_log_date1 [target_log_date2 ...]"
  $stderr.puts "    target_log_date format: YYYYMMDD"
  exit 1
end

$paper_id = ARGV[0]
$target_logs = ARGV[1..-1].map {|date| "#{ROOT_PATH}/files/search_logs/search_log_#{date}.bak-utf8"}

def execute(command)
  $stderr.puts command
  status, stdout, stderr = systemu(command)
  $stderr.puts [status, stdout, stderr].inspect
  stdout
end

def output_count(command, title)
  stdout = execute(command)
  stdout.match(/\s+(\d+)\s+(\d+)\s+(\d+)/)
  count = $1
  $stdout.puts "#{title}: #{count}"
end

if $target_logs.size > 2
  $target_span = "#{ARGV[1]}_#{ARGV[-1]}"
else
  $target_span = ARGV[1]
end
$log_file = "#{ROOT_PATH}/files/access_analysis/#{$paper_id}-#{$target_span}.txt"

# generate log file
if !File.exists?($log_file)
  execute("grep #{$paper_id}.pdf #{$target_logs.join(" ")} > #{$log_file}")
end
# bots
$bots = 'google|super-goo\.com|[Bb]ot\/|[Rr]obot|[Ss]pider|[Cc]rawler|Blekkobot|bot\-Mobile|Slurp\/|Yeti\/|baidu'
output_count("grep -E '#{$bots}' #{$log_file} | wc", "bots")
# corporations
$corporations = '\.co\.jp|\.com|\.kddilabs\.jp|\.konicaminolta\.jp|\.tew\.jp'
output_count("grep -E '#{$corporations}' #{$log_file} | grep -v -E '#{$bots}' | wc", "corporations")
# universities and research organizations
$universities = '\.ac\.jp|\-u\.jp|\.nict\.go\.jp|\.kek\.jp|\-ct\.jp|\.jaxa\.jp|\.naist\.jp|\.jaist\.jp|\.aist\.jp'
output_count("grep -E '#{$universities}' #{$log_file} | wc", "universities")
# isp
$isp = '\.net|\.ad.jp|\.ne\.jp|\.or\.jp|\.uqwimax\.jp|\.itscom\.jp|\.bbexcite\.jp|\.fenics\.jp|\.gmo-isp\.jp'
output_count("grep -E '#{$isp}' #{$log_file} | grep -v -E '#{$bots}' | wc", "isp")
# governments
$governments = '\.go\.jp|\.pref\..*\.jp'
$not_gov = '\.nict\.go\.jp'
output_count("grep -E '#{$governments}' #{$log_file} | grep -v '#{$not_gov}' | wc", "governments")
# others
output_count("grep -v -E '#{$corporations}|#{$universities}|#{$isp}|#{$governments}' #{$log_file} | grep -v -E '#{$bots}' | wc", "others")
