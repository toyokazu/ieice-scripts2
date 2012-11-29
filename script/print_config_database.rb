#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'shell'

ROOT_PATH = File.expand_path('../../',  __FILE__)
config_path = "#{ROOT_PATH}/config/database.yml"

if !File.exists?(config_path)
  puts "can not find configuration file: #{config_path}"
  exit 1
end

$config = YAML.load_file(config_path)
print $config[ARGV[0]]
