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

# Everything Released Summary, Collections Summary, Individual Items Summary, Collection-specific Summary
report_type = ENV['RPT_TYPE']
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
  puts("SW has #{sw_coll.length} released to #{sw_target}")

  argo_pf_diff = argo_coll.sort - pf_coll.sort
  argo_sw_diff = argo_coll.sort - sw_coll.sort
  pf_sw_diff = pf_coll.sort - sw_coll.sort
  pf_argo_diff = pf_coll.sort - argo_coll.sort
  sw_argo_diff = sw_coll.sort - argo_coll.sort
  sw_pf_diff = sw_coll.sort - pf_coll.sort

  if (argo_pf_diff.length > 0)
    puts("These collections are in Argo as released to #{sw_target} but not in PF")
    puts argo_pf_diff
  else
    puts("Same collections in Argo and PF are released to #{sw_target}")
  end
  if (argo_sw_diff.length > 0)
    puts("These collections are in Argo as released to #{sw_target} but not in SW")
    puts argo_sw_diff
  else
    puts("Same collections in Argo and SW are released to #{sw_target}")
  end
  if (pf_sw_diff.length > 0)
    puts("These collections are in PF as released to #{sw_target} but not in SW")
    puts pf_sw_diff
  else
    puts("Same collections in PF and SW are released to #{sw_target}")
  end
  if (pf_argo_diff.length > 0)
    puts("These collections are in PF as released to #{sw_target} but not in Argo")
    puts pf_argo_diff
  else
    puts("Same collections in PF and Argo are released to #{sw_target}")
  end
  if (sw_pf_diff.length > 0)
    puts("These individual items are in SW but not as released in PF to #{sw_target}")
    puts sw_pf_diff
  else
    puts("Same individual items in PF and SW are released to #{sw_target}")
  end
  if (sw_argo_diff.length > 0)
    puts("These individual items are in SW but not as released in Argo to #{sw_target}")
    puts sw_argo_diff
  else
    puts("Same individual items in PF and Argo are released to #{sw_target}")
  end
end

def individual_items_summary(argo_client, purl_client, sw_client, sw_target)

  argo_items = argo_client.items_druids
  pf_items = purl_client.items_druids
  sw_items = sw_client.items_druids

  puts("Individual Items Statistics")
  puts("Argo has #{argo_items.length} released to #{sw_target}")
  puts("PF has #{pf_items.length} released to #{sw_target}")
  puts("SW has #{sw_items.length} released to #{sw_target}")

  argo_pf_diff = argo_items.sort - pf_items.sort
  argo_sw_diff = argo_items.sort - sw_items.sort
  pf_sw_diff = pf_items.sort - sw_items.sort
  pf_argo_diff = pf_items.sort - argo_items.sort
  sw_argo_diff = sw_items.sort - argo_items.sort
  sw_pf_diff = sw_items.sort - pf_items.sort

  if (argo_pf_diff.length > 0)
    puts("These individual items are in Argo as released to #{sw_target} but not in PF")
    puts argo_pf_diff
  else
    puts("Same individual items in Argo and PF are released to #{sw_target}")
  end
  if (argo_sw_diff.length > 0)
    puts("These individual items are in Argo as released to #{sw_target} but not in SW")
    puts argo_sw_diff
  else
    puts("Same individual items in Argo and SW are released to #{sw_target}")
  end
  if (pf_sw_diff.length > 0)
    puts("These individual items are in PF as released to #{sw_target} but not in SW")
    puts pf_sw_diff
  else
    puts("Same individual items in PF and SW are released to #{sw_target}")
  end
  if (pf_argo_diff.length > 0)
    puts("These individual items are in PF as released to #{sw_target} but not in Argo")
    puts pf_argo_diff
  else
    puts("Same individual items in PF and Argo are released to #{sw_target}")
  end
  if (sw_pf_diff.length > 0)
    puts("These individual items are in SW but not as released in PF to #{sw_target}")
    puts sw_pf_diff
  else
    puts("Same individual items in PF and SW are released to #{sw_target}")
  end
  if (sw_argo_diff.length > 0)
    puts("These individual items are in SW but not as released in Argo to #{sw_target}")
    puts sw_argo_diff
  else
    puts("Same individual items in PF and Argo are released to #{sw_target}")
  end
end

def individual_collection_summary(argo_client, purl_client, sw_client, sw_target, collection_druid)

  fail "Must provide Environment variable COLL_DRUID with this script" if collection_druid.nil?
  argo_mem = argo_client.collection_members(collection_druid)
  pf_mem = purl_client.collection_members(collection_druid)
  sw_mem = sw_client.collection_members(collection_druid)

  puts("Individual Collection Statistics")
  puts("Argo has #{argo_mem.length} members in collection #{collection_druid} released to #{sw_target}")
  puts("PF has #{pf_mem.length} members in collection #{collection_druid} released to #{sw_target}")
  puts("SW has #{sw_mem.length} members in collection #{collection_druid} released to #{sw_target}")

  argo_pf_diff = argo_mem.sort - pf_mem.sort
  argo_sw_diff = argo_mem.sort - sw_mem.sort
  pf_sw_diff = pf_mem.sort - sw_mem.sort
  pf_argo_diff = pf_mem.sort - argo_mem.sort
  sw_argo_diff = sw_mem.sort - argo_mem.sort
  sw_pf_diff = sw_mem.sort - pf_mem.sort

  if (argo_pf_diff.length > 0)
    puts("These members for collection #{collection_druid} are in Argo as released to #{sw_target} but not in PF")
    puts argo_pf_diff
  else
    puts("Same members in Argo and PF for collection #{collection_druid}")
  end
  if (argo_sw_diff.length > 0)
    puts("These members for collection #{collection_druid} are in Argo as released to #{sw_target} but not in SW")
    puts argo_sw_diff
  else
    puts("Same members in Argo and SW for collection #{collection_druid}")
  end
  if (pf_sw_diff.length > 0)
    puts("These members for collection #{collection_druid} are in PF as released to #{sw_target} but not in SW")
    puts pf_sw_diff
  else
    puts("Same members in PF and SW for collection #{collection_druid}")
  end
  if (pf_argo_diff.length > 0)
    puts("These members for collection #{collection_druid} are in PF as released to #{sw_target} but not in Argo")
    puts pf_argo_diff
  else
    puts("Same members in PF and Argo for collection #{collection_druid}")
  end
  if (sw_pf_diff.length > 0)
    puts("These individual items are in SW but not as released in PF to #{sw_target}")
    puts sw_pf_diff
  else
    puts("Same individual items in PF and SW are released to #{sw_target}")
  end
  if (sw_argo_diff.length > 0)
    puts("These individual items are in SW but not as released in Argo to #{sw_target}")
    puts sw_argo_diff
  else
    puts("Same individual items in PF and Argo are released to #{sw_target}")
  end
end

def everything_released_summary(argo_client, purl_client, sw_client, sw_target)
  argo_all = argo_client.all_druids
  pf_all = purl_client.all_druids
  sw_all = sw_client.all_druids

  puts("Everything Statistics")
  puts("Argo has #{argo_all.length} released to #{sw_target}")
  puts("PF has #{pf_all.length} released to #{sw_target}")
  puts("SW has #{sw_all.length} released to #{sw_target}")

  argo_pf_diff = argo_all.sort - pf_all.sort
  argo_sw_diff = argo_all.sort - sw_all.sort
  pf_sw_diff = pf_all.sort - sw_all.sort
  pf_argo_diff = pf_all.sort - argo_all.sort
  sw_argo_diff = sw_all.sort - argo_all.sort
  sw_pf_diff = sw_all.sort - pf_all.sort
  
  if (argo_pf_diff.length > 0)
    puts("These druids are in Argo as released to #{sw_target} but not in PF")
    puts argo_pf_diff
  else
    puts("Same druids in Argo and PF are released to #{sw_target}")
  end
  if (argo_sw_diff.length > 0)
    puts("These druids are in Argo as released to #{sw_target} but not in SW")
    puts argo_sw_diff
  else
    puts("Same druids in Argo and SW are released to #{sw_target}")
  end
  if (pf_sw_diff.length > 0)
    puts("These druids are in PF as released to #{sw_target} but not in SW")
    puts pf_sw_diff
  else
    puts("Same druids in PF and SW are released to #{sw_target}")
  end
  if (pf_argo_diff.length > 0)
    puts("These druids are in PF as released to #{sw_target} but not in Argo")
    puts pf_argo_diff
  else
    puts("Same druids in PF and Argo are released to #{sw_target}")
  end
  if (sw_pf_diff.length > 0)
    puts("These individual items are in SW but not as released in PF to #{sw_target}")
    puts sw_pf_diff
  else
    puts("Same individual items in PF and SW are released to #{sw_target}")
  end
  if (sw_argo_diff.length > 0)
    puts("These individual items are in SW but not as released in Argo to #{sw_target}")
    puts sw_argo_diff
  else
    puts("Same individual items in PF and Argo are released to #{sw_target}")
  end
end

case report_type
when "Collections Summary"
  collections_summary(argo_client, purl_client, sw_client, sw_target)
when "Individual Items Summary"
  individual_items_summary(argo_client, purl_client, sw_client, sw_target)
when "Collection-specific Summary"
  individual_collection_summary(argo_client, purl_client, sw_client, sw_target, collection_druid)
when "Everything Released Summary"
  everything_released_summary(argo_client, purl_client, sw_client, sw_target)
else
  collections_summary(argo_client, purl_client, sw_client, sw_target)
end
