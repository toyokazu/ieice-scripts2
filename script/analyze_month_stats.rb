#!/usr/bin/env ruby

require 'yaml'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/count_log_files.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

config = YAML.load_file(config_path)

month_stats = YAML.load_file("#{ROOT_PATH}/files/#{config["month_stats"]}")

stat_types = ["avg", "var", "dev", "num", "thresh_num"]
month_stats.each do |month, hash|
  open("#{ROOT_PATH}/files/#{config["analyzed_month_stats"]}/#{month}", "w") do |file|
    file.puts "--- paper ---"
    file.puts hash["paper"].sort {|a,b| b[1]["paper"] <=> a[1]["paper"]}.to_yaml
    file.puts "--- paper (#{stat_types.join(",")}) ---"
    stat_types.each do |stat_type|
      file.puts "#{stat_type}_paper: #{hash["#{stat_type}_paper"]}"
    end
    file.puts "--- remote_addr ---"
    file.puts hash["remote_addr"].sort {|a,b| b[1]["remote_addr"] <=> a[1]["remote_addr"]}.to_yaml
    file.puts "--- remote_addr (#{stat_types.join(",")}) ---"
    stat_types.each do |stat_type|
      file.puts "#{stat_type}_remote_addr: #{hash["#{stat_type}_remote_addr"]}"
    end
    file.puts "num_bots: #{hash["num_bots"]}"
    file.puts "num_others: #{hash["num_others"]}"
  end
end

