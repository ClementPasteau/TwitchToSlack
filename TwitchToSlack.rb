#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'time'



def send_slack(stream_infos)
  if stream_infos
    name = stream_infos["channel"]["display_name"]
    game = stream_infos["game"]
    viewers = stream_infos["viewers"]
    stream_url = stream_infos["channel"]["url"]
    parms = { "text" => "#{name} just gone live streaming #{game} with #{viewers} viewers !!! GOGOGO : #{stream_url}" }
  else
    parms = { "text" => "Stream is now offline :(" }
  end

  url = ENV['SLACK_WEBHOOK_URL']

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = parms.to_json
  http.request(request)
end



def check_twitch(streamer)
  uri = URI("https://api.twitch.tv/kraken/streams/#{streamer}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  headers = {
    'Accept' => "application/vnd.twitchtv.v3+json",
    'Client-ID' => ENV['TWITCH_CLIENT_ID']
  }
  resp = http.get(uri.path, headers)
  json = JSON.parse(resp.body)

  return json["stream"]
end






streamers = ["twoeasy", "kolento", "kronovi", "pashabiceps", "scream", "danzhizzle", "followgrubby", "scrubkillarl_"]

streamers.each do |streamer|
  stream_infos	= check_twitch(streamer)

  if stream_infos

    stream_start = stream_infos["created_at"]
    online_since = (Time.now - Time.parse(stream_start))

    # Send Slack notification only if the stream started less than 30min ago
    if online_since < 1800
      puts "Sent Slack notification !"
      send_slack(stream_infos)
    elsif
      puts "#{streamer.capitalize} stream started more than 30min ago, didn't sent Slack notification !"
    end

  else

    puts "#{streamer.capitalize} stream offline, didn't sent Slack notification !"

  end
end

