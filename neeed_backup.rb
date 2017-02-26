require 'open-uri'
require 'mechanize'

require 'pry'

class List
  attr_accessor :name, :id, :items

  def initialize(name, id)
    self.name = name
    self.id = id
  end

  def self.fetch_lists(neeed)
    neeed..homepage.css('li[data-list]').collect do |list_el|
      url = list_el.elements.attribute('href').value
      name, id = url.split('l-')[1].split('~')
      List.new(name, id)
    end
  end

  def fetch_items(neeed)
  end

  def output
    #create sub-sub folder 'list-images'
    #name & write images
  end

  def self.output_all(lists)
    #create one big csv
  end

  private

  def url(offset=20)
    "http://neeed.com/core/process/aru.get.php?t=user&l=#{self.name}&s=#{offset}&ui=#{id}&p=&cols=3"
  end

  def make_csv_line
  end

end

class Item
  attr_accessor :name, :url, :price, :image
end


class NeeedSession
  attr_accessor :agent

  def initialize(user, pass)
    login(user, pass)
    @agent = Mechanize.new
  end

  def homepage
    agent.get 'http://neeed.com'
  end

  private

  def login(user, pass)
    form = agent.get("http://neeed.com/core/static/login.box.static.php").form
    form.email = user
    form.password = pass
    form.submit
  end

end


def backup(username, pass)
  neeed = NeeedSession.new(username, pass)
  lists = List.fetch_lists(neeed.agent)
  lists.map { |list| list.fetch_items(neeed.agent) }

  # lists.map { |list| list.output }
  # List.output_all(lists)
end

backup(ARGV[0], ARGV[1])