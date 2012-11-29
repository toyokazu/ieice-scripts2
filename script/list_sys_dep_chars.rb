#!/usr/bin/env ruby

if ARGV.size < 1
  $stderr.puts "usage: list_sys_dep_chars.rb file1 [file2 file3 ...]"
  exit 1
end

sys_dep_chars = []
ARGV.each do |file|
  open(file) do |f|
    lines = f.readlines
    lines.each do |line|
      sys_dep_chars = (sys_dep_chars + line.scan(/<(\w+\d+\.(jpg|gif))>/).map {|a| a[0]}).uniq
    end
  end
end
puts sys_dep_chars.sort.join("\n")
