require 'sinatra'
require 'nokogiri'
require 'open-uri'

class MobileFilter < Sinatra::Base
  get '/' do
    url = params[:url]
    url = 'http://'+url unless url.index('http://') == 0
    doc = Nokogiri::HTML(open(url))
    a = doc

    title = doc.search('title').text
    title_node = Nokogiri::XML::Node.new 'title', a
    title_node.content = title
    a.search('head').remove

    a.children.last.children.first.add_previous_sibling(title_node)

    body a.to_html
  end
end
