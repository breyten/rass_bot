#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'json'
require 'open-uri'

require 'nokogiri'
require 'twitter'
require 'inifile'
require 'bitly'

def config
  IniFile.load('rass_bot.ini')
end

def random_letter
  ('A'..'Z').to_a.sample
end

def get_random_item(config)
  letter = random_letter
  acronyms_url = 'http://en.wikipedia.org/wiki/List_of_acronyms:_' + letter

  page = Nokogiri::HTML(open(acronyms_url))
  acronyms = page.css('#mw-content-text').css('li').map do |li|
    li.css('a').map { |a| a.text }
  end

  candidate_rasses = acronyms.select { |a| !a[0].nil? && a[0].upcase == a[0] && a.length == 2 && a[1].split(/\s+/).length > 1 }
  rass = candidate_rasses.sample

  {
    :url => acronyms_url,
    :acronym => rass[0],
    :full => rass[1],
    :rass => rass[0] + " " + rass[1].split(/\s+/)[-1]
  }
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

# bitly = Bitly.new(@config['bitly']['user'], @config['bitly']['apikey'])
# @short_url = bitly.shorten(@item_url).short_url
@short_url = @item[:url]

message = "%{rass} (%{full})" % @item
tweet_text = "%s : %s" % [message[0, 100], @short_url]

# puts tweet_text

send_tweet(tweet_text, config)
