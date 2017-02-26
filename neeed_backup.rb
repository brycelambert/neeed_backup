require 'open-uri'
require 'mechanize'
require 'csv'
require 'pry'

class Item
  attr_accessor :id, :name, :vendor, :url, :price, :image_url

  def to_csv
    [id, name, vendor, price, url, image_url]
  end

end

class List
  attr_accessor :name, :id, :items

  def initialize(name, id)
    self.name = name
    self.id = id
  end

  def output(path)
    img_output_path = "#{path}#{name}"
    Dir.mkdir(img_output_path) unless File.directory?(img_output_path)

    items.each do |item|
      IO.copy_stream(open(item.image_url),
        "#{img_output_path}/#{item.id}.jpg")
    end

    CSV.open("#{path}#{name}.csv", "w") do |csv|
      items.each { |item| csv << item.to_csv }
    end

  end

  def self.output_all_as_csv(lists, path)
    CSV.open("#{path}#{all_lists}.csv", "w") do |csv|
      lists.each { |list| list.items.each { |item| csv << item.to_csv } }
    end
  end

end

class NeeedAgent
  attr_accessor :agent, :u_id

  def initialize(user, pass)
    @agent = Mechanize.new
    login(user, pass)
    # agent.redirection_limit = 2
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
    item.image_url = 'http://neeed.com/' + item_source.css('.prod-img').first.css('img').first.attributes['src'].value
    item.name = item_source.css('.prod-img').first.css('img').first.attributes['alt'].value
    item.vendor = item_source.css("a[itemprop='brand']").text.strip
    item.price = item_source.css('.price').text

    item.url =
      begin
        agent.get( item_source.css('.prod-img').first.attributes['href'].value ).uri.to_s
      rescue Mechanize::ResponseCodeError, Mechanize::RedirectLimitReachedError => e
        e.page.uri.to_s
      end

    item
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
  [lists.first].each { |list| list.items = neeed.fetch_items(list) }

  output_dir_name = "need_backup_#{Time.now.strftime("%d-%m-%y")}"
  suffix, i = '', 0
  until !File.directory?(output_dir_name + suffix) do
    i += 1
    suffix = " #{i}"
  end

  output_dir_name.concat(suffix)
  output_dir = Dir.mkdir(output_dir_name)
  output_path = "#{Dir.pwd}/#{output_dir_name}/"
  
  lists.each { |list| list.output(output_path) }
  List.output_all_as_csv(lists)
end

backup(ARGV[0], ARGV[1])