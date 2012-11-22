require 'sinatra'
require 'nokogiri'
require 'open-uri'

class MobileFilter < Sinatra::Base
  get '/' do
    proxy_url = URI::parse request.url
    proxy_url.query = ''

    doc_url = params[:url]
    doc_url = 'http://'+doc_url unless doc_url.index('http://') == 0
    doc = Nokogiri::HTML(open(doc_url))
    a = doc

    doc_url_obj = URI::parse doc_url
    doc_url_obj.path = ''
    doc_base_url = doc_url_obj.to_s

    title = doc.search('title').text
    title_node = Nokogiri::XML::Node.new 'title', a
    title_node.content = title

    # kill stuff
    a.search('head').remove
    a.search('style').remove
    a.search('img').remove
    a.search('iframe').remove
    a.search('onclick').remove

    # rewrite anchor tags to go through proxy
    a.search('a').each do |node|
      next unless node.attributes['href']
      node_url = node.attributes['href'].value
      node_url = doc_base_url.to_s + '/' + node_url if node_url and node_url.index('/') == 0
      node.attributes['href'].value = proxy_url.to_s+'url='+node_url.to_s
    end

    a.children.last.children.first.add_previous_sibling(title_node)

    body a.to_html
  end
end
