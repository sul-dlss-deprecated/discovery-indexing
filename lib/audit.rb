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

report_type = ENV['RPT_TYPE'] # Collections Summary, Individual Items Summary, Collection-specific Summary
collection_druid = ENV['COLL_DRUID']

argo_client = ArgoClient.new(argo_url, sw_target)
purl_client = PurlClient.new(pf_url, sw_target)
sw_client = SwClient.new(sw_url)


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

def collections_summary(argo_client, purl_client, sw_client, sw_target)

  argo_coll = argo_client.collections_druids
  pf_coll = purl_client.collections_druids
  sw_coll = sw_client.collections_druids

  puts("Collections Statistics")
  puts("Argo has #{argo_coll.length} released to #{sw_target}")
  puts("PF has #{pf_coll.length} released to #{sw_target}")
  puts("SW has #{sw_coll.length} released in #{sw_target}")

  puts("These druids are in Argo as released but not in PF")
  puts argo_coll.sort - pf_coll.sort
  puts("These druids are in Argo as released but not in SW")
  puts argo_coll.sort - sw_coll.sort
  puts("These druids are in PF as released but not in SW")
  puts pf_coll.sort - sw_coll.sort
  puts("These druids are in PF as released but not in Argo")
  puts pf_coll.sort - argo_coll.sort
end

def individual_collection_summary(argo_client, purl_client, sw_client, sw_target, collection_druid)
  puts collection_druid
  fail "Must provide Environment variable COLL_DRUID with this script" if collection_druid.nil?
  argo_mem = argo_client.collection_members(collection_druid)
  pf_mem = purl_client.collection_members(collection_druid)
  # sw_mem = sw_client.collection_members(collection_druid)
  # puts sw_mem
end

case report_type
when "Collections Summary"
  collections_summary(argo_client, purl_client, sw_client, sw_target)
when "Individual Items Summary"
when "Collection-specific Summary"
  individual_collection_summary(argo_client, purl_client, sw_client, sw_target, collection_druid)
else
  collections_summary(argo_client, purl_client, sw_client, sw_target)
end

# argo_coll.each do | id |
#   argo_client.collection_members(id)
# end
