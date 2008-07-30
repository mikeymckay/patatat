#!/usr/bin/ruby

require 'rubygems'
require 'net/http'
require 'uri'
require 'json'

# $config |= YAML.load(File.open(path_to_patatat + "/tweeter.conf"))

class Tweeter
  attr_accessor :username, :password, :friends

  def initialize(username,password)
    @username = username  
    @password = password
    Tweeter.yell "Patatat initialized"
  end

  def self.yell(msg) 
    # stupid simple logging:
    f = File.open(File.expand_path($config["data_directory"] + "/yell.log"),"a") 
    f.puts msg 
    f.close
  end

  def send_direct_message(recipient, message)
    uri = "http://#{@username}:#{@password}@twitter.com/direct_messages/new.json"
    Tweeter.yell "Sending #{recipient}: #{message}"
    Net::HTTP.post_form(URI.parse(uri), {'user' => recipient, 'text' => message})
  end

  def get_direct_messages(since=nil)
    path = "/direct_messages.json"
    path += "?since=#{since}" unless since.nil?
    authenticated_get(path)
  end
  
  def last_message
    return get_direct_messages.last
  end

  def friends
    return @friends unless @friends.nil?
    path = "/statuses/friends.json?lite=true"
    @friends = authenticated_get(path).collect{|friend|friend['screen_name']} rescue nil
  end

  # No since method on followers right now
  def followers
    path = "/statuses/followers.json?lite=true"
    authenticated_get(path).collect{|follower|follower['screen_name']} rescue nil
  end

  def follow(screen_name)
    Tweeter.yell "Following #{screen_name}"
    @friends << screen_name
    path = "/friendships/create/#{screen_name}.json"
    authenticated_get(path)
  end

  def unfollowed_friends_screenames
    followers_screen_names = followers.collect{|follower|follower['screen_name']}
    friends_screen_names = friends.collect{|friend|friend['screen_name']}
    return followers - friends
  end

  private

  def authenticated_get(path)
    Net::HTTP.start("twitter.com", 80) do |http|
      Tweeter.yell "GETting: #{path} for #{@username}"
      request = Net::HTTP::Get.new(path)
      request.basic_auth(@username, @password)
      response = http.request(request)
      response = JSON.parse(response.body)
      Tweeter.yell "Response: #{response}" rescue Tweeter.yell "Exception trying to GET #{path}: #{$!}\n#{response}"
      response
    end

  end

end
