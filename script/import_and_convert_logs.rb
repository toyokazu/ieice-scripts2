#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

ROOT_PATH = File.expand_path('../../',  __FILE__)

# TSV ファイルのインポート
puts '.separator "\t"'
#Dir.open("#{ROOT_PATH}/files/search_logs") do |dir|
Dir.open("#{ROOT_PATH}/files") do |dir|
  while (file = dir.read) do
    if file =~ /(search_log_\d{4}-*\d{2}\.bak)$/
      puts ".import #{$1} access_logs"
      #puts ".import search_logs/#{$1} access_logs"
    end
  end
end
puts <<-SQL
create index access_logs_log_date_index on access_logs (log_date);
create index access_logs_f_name_index on access_logs (f_name);
create index access_logs_err_index on access_logs (err);
create index access_logs_summary_view_index on access_logs (summary_view);
SQL
