require 'sinatra'
require 'nokogiri'
require 'open-uri'

class MobileFilter < Sinatra::Base
  get '/' do
    proxy_url = URI::parse request.url
    proxy_url.query = ''

    doc_url = params[:url]
    doc_url = 'http://'+doc_url unless doc_url.index('http') == 0
    doc = Nokogiri::HTML(open(doc_url))

    doc_url_obj = URI::parse doc_url
    doc_url_obj.path = ''
    doc_base_url = doc_url_obj.to_s

    title = doc.search('title').text
    title_node = Nokogiri::XML::Node.new 'title', doc
    title_node.content = title

    # kill stuff
    doc.search('img').remove
    doc.search('iframe').remove
    doc.search('script').remove
    doc.search('link').remove
    doc.search('ul').remove
    doc.search('form').remove
    doc.search('style').remove

    killthese = ['style', 'onclick', 'onmousedown', 'onmouseup', 'margin', 'display']
    onthese = ['div', 'td', 'th', 'table', 'span', 'a']

    onthese.each do |tag_name|
      doc.search(tag_name).each do |node|
        killthese.each do |attr_name|
          attribute = node.attributes[attr_name]
          attribute.value = '' if attribute
        end
      end
    end

    doc.css('#header').remove
    doc.css('#footer').remove

    if doc_url.index('news.google.com')
      doc.css('.main-appbar').remove
      doc.css('.kd-appbar').remove
      doc.css('.esc-layout-thumbnail-cell').remove
      doc.css('.media-strip-table').remove
    end

    # rewrite anchor tags to go through proxy
    doc.search('a').each do |node|
      next unless node.attributes['href']
      node_url = node.attributes['href'].value
      node_url = doc_base_url.to_s + '/' + node_url if node_url and node_url.index('/') == 0
      node.attributes['href'].value = proxy_url.to_s+'url='+node_url.to_s
    end

    # <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0">
    meta_node = Nokogiri::XML::Node.new "meta", doc
    meta_node['content'] = 'width=device-width, user-scalable=false'
    meta_node.parent = doc.search('head').first

    body doc.to_html
  end
end
