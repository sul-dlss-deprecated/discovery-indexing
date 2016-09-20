#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'net/http'
require 'uri'

def get_ids_from_purl_fetcher(collections)
  collections.each do | coll |
    coll["true_targets"].map!(&:downcase)
    if coll["true_targets"].include? "searchworks"
      @purl_ids.push(coll["druid"].gsub(/druid:/, ''))
    end
  end
  @purl_ids
end

# curl "https://purl-fetcher-prod.stanford.edu/purls" - not sure if collections are included here

uri = URI.parse("https://purl-fetcher-prod.stanford.edu/collections")
response = Net::HTTP.get_response(uri)
colls = JSON.parse(response.body)
no_pages = colls["pages"]["total_pages"]

@purl_ids = []
@purl_ids = get_ids_from_purl_fetcher(colls["collections"])

(2..no_pages).each do |i|
  uri = URI.parse("https://purl-fetcher-prod.stanford.edu/collections?page=#{i}")
  response = Net::HTTP.get_response(uri)
  colls = JSON.parse(response.body)
  @purl_ids = get_ids_from_purl_fetcher(colls["collections"])
end

puts @purl_ids.sort
