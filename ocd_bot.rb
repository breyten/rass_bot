#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'json'

require 'httparty'
require 'twitter'
require 'inifile'

def config
  IniFile.load('ocd_bot.ini')
end

def random_item_query
  {
    "query" => {
      "function_score" => {
        "query" => { "match_all" => {} },
        "random_score" => { "seed" => Time.now.to_i }
      }
    },
    "size" => 1
  }
end

def get_random_item(config)
    HTTParty.post(config['ocd']['url'], :body => JSON.generate(random_item_query))
end

@config = config
puts JSON.generate(get_random_item(@config))
