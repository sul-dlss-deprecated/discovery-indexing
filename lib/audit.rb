#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'net/http'
require 'uri'

uri = URI.parse("http://searchworks-solr-lb:8983/solr/current/select?q=*%3A*&fq=id%3A%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F&fl=id&wt=csv&rows=10000000&csv.header=false")
response = Net::HTTP.get_response(uri)
body = response.body.split("\n")
# no_pages = colls["pages"]["total_pages"]
#
# @purl_ids = []
# @purl_ids = get_ids_from_purl_fetcher(colls["collections"])
#
# (2..no_pages).each do |i|
#   uri = URI.parse("https://purl-fetcher-prod.stanford.edu/collections?page=#{i}")
#   response = Net::HTTP.get_response(uri)
#   colls = JSON.parse(response.body)
#   @purl_ids = get_ids_from_purl_fetcher(colls["collections"])
# end
#
# puts @purl_ids.sort
