#!/usr/bin/env ruby

# get a list of collection druids and catkeys from argo index
# get a list of collection druids and catleys from purl-fetcher API
# get a list of collection druids and catkeys from searchworks index

# compare those lists
#   - make a list of agree'd upon collection druids

# for each collection get druid ids with releases & catkeys from:
#   - argo index
#   - purl-fetcher
#   - searchworks index

require 'rubygems'
require 'net/http'
require 'uri'
require './argo_client'
require './purl_client'
require './sw_client'


# Environment variables
argo_url = ENV['ARGO_URL']
pf_url = ENV['PF_URL']
sw_url = ENV['SW_URL']
sw_target = ENV['SW_TGT']

def results(url)
  res_url = URI.parse(url)
  Net::HTTP.get_response(res_url).body
end


def coll_members(collection_ids, url)
  members = []
  collection_ids.each do | druid |
    members += results(url)
  end
  members
end



# Get sw records that have druids as IDs but are not collections
def records_with_druid_ids(url)
  results("#{sw_url}/select?fq=-collection_type%3A%22Digital+Collection%22&q=*%3A*&fq=id%3A%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F&fl=id,managed_purl_urls&wt=csv&rows=10000000&csv.header=false").split("\n")
end


argo_res = ArgoClient.new(argo_url, sw_target).collections_druids
pf_res = PurlClient.new(pf_url, sw_target).collections_druids
sw_res = SwClient.new(sw_url).collections_druids

puts("Collections Statistics")
puts("Argo has #{argo_res.length} released to #{sw_target}")
puts("PF has #{pf_res.length} released to #{sw_target}")
puts("SW has #{sw_res.length} released in #{sw_target}")

puts("These druids are in Argo as released but not in PF")
puts argo_res.sort - pf_res.sort
puts("These druids are in Argo as released but not in SW")
puts argo_res.sort - sw_res.sort
puts("These druids are in PF as released but not in SW")
puts pf_res.sort - sw_res.sort
puts("These druids are in PF as released but not in Argo")
puts pf_res.sort - argo_res.sort
