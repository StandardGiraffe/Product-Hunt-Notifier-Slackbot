# `$ foreman start` to run the bot.

require 'slack-ruby-bot'
require 'producthunt-bot/commands/hello'
require 'producthunt-bot/bot'
require 'net/http'
require 'json'
require 'date'


class Article
  attr_reader :id, :title, :url, :tagline, :timestamp, :topics

  def initialize(id:, title:, url:, tagline:, timestamp:, topics:)
    @id = id
    @title = title
    @url = url
    @tagline = tagline
    @timestamp = timestamp
    @topics = topics
  end
end

class Collection
  def initialize
    @HOT_TOPICS = %w[email emails emailing emailer mailer email-marketing email-newsletters]

    @stored_articles = [ ]

    @uri = URI('https://api.producthunt.com/v1/posts/all')
    @latest_id = 14100
    @params = {
      access_token: ENV['PRODUCT_HUNT_KEY'],
      newer: @latest_id
    }
    update_params
  end

  def update_collection
    posts = get_posts
    posts.each do |post|
      article = build_article(post)
      if is_interesting?(article)
        @stored_articles.push(article)
        puts "++++ Found an article! ++++"
        puts @stored_articles.last.inspect
        # TODO: Have slackbot report on @stored_articles.last
      end
    end
  end

private
  def is_interesting?(article)
    (article.topics & @HOT_TOPICS).length > 0 || (article.tagline.split & @HOT_TOPICS).length > 0
  end

  def update_params
    @params[:newer] = @latest_id
    puts "@params updated?  @params[:newer] = #{@params[:newer]}"
    @uri.query = URI.encode_www_form(@params)
  end

  def update_latest_id(id)
    if id > @latest_id
      @latest_id = id
    end
  end

  def get_posts
    update_params
    res = Net::HTTP.get_response(@uri)
    response = JSON.parse(res.body)
    response['posts']
  end

  def build_article(post)
    update_latest_id(post['id'])

    Article.new(
      id: post['id'],
      title: post['name'],
      url: post['redirect_url'],
      tagline: post['tagline'].downcase,
      timestamp: Date.parse(post['created_at']),
      topics: find_topics(post)
    )
  end

  def find_topics(post)
    post['topics'].map do |topic|
      topic['slug']
    end
  end
end


Thread.new do
  collector = Collection.new
  collector.update_collection
  count = 0

  while true do
    count += 1
    puts '====================='
    puts "Starting a search... Iteration No. #{count.to_s}"
    puts '====================='
    collector.update_collection
    sleep(10)
  end
end