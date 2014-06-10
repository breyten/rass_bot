#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'json'

require 'httparty'
require 'twitter'
require 'inifile'
require 'bitly'

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
    HTTParty.post(
        config['ocd']['url'],
        :body => JSON.generate(random_item_query)
    )['hits']['hits'][0]
end

def get_item_url(item, config)
    item['_source']['meta']['original_object_urls']['html']
end

def send_tweet(tweet, ocd_config)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ocd_config['twitter']['api_key']
      config.consumer_secret     = ocd_config['twitter']['api_secret']
      config.access_token        = ocd_config['twitter']['token']
      config.access_token_secret = ocd_config['twitter']['token_secret']
    end
    client.update(tweet)
end

@config = config
@item = get_random_item(@config)
@item_url = get_item_url(@item, @config)

bitly = Bitly.new(@config['bitly']['user'], @config['bitly']['apikey'])
@short_url = bitly.shorten(@item_url).short_url

message = "%{title} / %{institution}" % {
    title: @item['_source']['title'],
    institution: @item['_source']['meta']['collection']
}
tweet_text = "%s : %s" % [message[0, 120], @short_url]

send_tweet(tweet_text, config)
