require 'open-uri'
require 'mechanize'
require 'pry'

class Item
  attr_accessor :id, :name, :vendor, :url, :price, :image_url
end

class List
  attr_accessor :name, :id, :items

  def initialize(name, id)
    self.name = name
    self.id = id
  end

  def output
    #create sub-sub folder 'list-images'
    #name & write images
  end

  def self.output_all(lists)
    #create one big csv
  end

  private

  def make_csv_line
  end

end

class NeeedAgent
  attr_accessor :agent, :u_id

  def initialize(user, pass)
    @agent = Mechanize.new
    login(user, pass)
  end

  def fetch_lists
    homepage.css('li[data-list]').collect do |list_el|
      url = list_el.elements.attribute('href').value
      name, id = url.split('l-').last.split('~')
      List.new(name, id)
    end
  end

  def fetch_items(list, offset=20)
    result = agent.get(list_url(list.name, offset))

    if result.links.empty?
      []
    else
      result.css('div[data-product]').map { |item|
        build_item(item)
      }.concat( fetch_items(list, offset+20) )
    end
  end


  private

  def build_item(item_source)
    item = Item.new
    item.id = item_source.attributes['id'].value
    item.image_url = item_source.css('.prod-img').first.css('img').first.attributes['src'].value
    item.name = item_source.css('.prod-img').first.css('img').first.attributes['alt'].value
    item.vendor = item_source.css("a[itemprop='brand']").text.strip
    item.price = item_source.css('.price').text

    item.url =
      begin
        agent.get( item_source.css('.prod-img').first.attributes['href'].value ).uri.to_s
      rescue Mechanize::ResponseCodeError
        agent.history[-1].uri.to_s
      end
  end

  def homepage
    self.agent.get 'http://neeed.com'
  end

  def list_url(list_name, offset)
    "http://neeed.com/core/process/aru.get.php?t=user&l=#{list_name}&s=#{offset}&ui=#{u_id}&p=&cols=3"
  end

  def login(user, pass)
    form = agent.get("http://neeed.com/core/static/login.box.static.php").form
    form.email = user
    form.password = pass
    form.submit
    @u_id = homepage.xpath("//*[@data-usr]").first.attributes['data-usr'].value.to_i
  end
end


def backup(username, pass)
  neeed = NeeedAgent.new(username, pass)
  lists = neeed.fetch_lists
  lists.each { |list| lists.items = neeed.fetch_items(list) }

  #lists.each { |list| list.output }
  # List.output_all(lists)
end

backup(ARGV[0], ARGV[1])