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
require 'json'
require 'net/http'
require 'uri'

# Environment variables
argo_url = ENV['ARGO_URL']
pf_url = ENV['PF_URL']
sw_url = ENV['SW_URL']
sw_target = ENV['SW_TGT']

def results(url)
  res_url = URI.parse(url)
  Net::HTTP.get_response(res_url).body
end

def ids_from_purl_fetcher(data, tgt)
  data_ids = []
  data.each do | d |
    if !d["true_targets"].nil? && !d["true_targets"].empty?
      d["true_targets"].map!(&:downcase)
      if d["true_targets"].include? tgt
        if d["catkey"].nil? || d["catkey"].empty?
          data_ids.push(d["druid"].gsub(/druid:/, ''))
        else
          data_ids.push([d["druid"].gsub(/druid:/, ''), d["catkey"]])
        end
      end
    end
  end
  data_ids
end

def druids_from_results(id_array)
  druids = []
  id_array.each do | id |
    if (id.is_a?(String))
      druids.push(id)
    elsif (id.is_a?(Array))
      druids.push(id[0])
    end
  end
  druids
end

def coll_members(collection_ids, url)
  members = []
  collection_ids.each do | druid |
    members += results(url)
  end
  members
end

def no_pages(data)
  data["pages"]["total_pages"]
end

def druids_from_SearchWorks(results)
  druids = []
  results.each do | res |
    urls = res.split(",")
    urls.each do | url |
      if (url =~ /^[a-z]/)
        url.gsub!("\"", "")
        url.gsub!("http:\/\/purl.stanford.edu\/", "")
        druids.push(url)
      end
    end
  end
  druids
end

def argo_druids(url, tgt)
  # Argo collection druids
  query = "/select?&fq=objectType_ssim:%22collection%22&fl=id,released_to_ssim,catkey_id_ssim&rows=10000&sort=id%20asc&wt=csv&csv.header=false"
  argo_coll_results = results("#{url + query}").split("\n")
  individual_items_released_in_argo_to_tgt(argo_coll_results, tgt)
end

def pf_druids(url, tgt)
  # Purl_fetcher collection druids
  query = "/collections"
  coll = JSON.parse(results("#{url + query}"))

  coll_ids = []
  coll_ids += ids_from_purl_fetcher(coll["collections"], tgt)

  (2..no_pages(coll)).each do |i|
    coll = JSON.parse(results("#{url + query}?page=#{i}"))
    coll_ids += ids_from_purl_fetcher(coll["collections"], tgt)
  end

  druids_from_results(coll_ids)
end

# Get sw records that have druids as IDs but are not collections
def records_with_druid_ids(url)
  results("#{sw_url}/select?fq=-collection_type%3A%22Digital+Collection%22&q=*%3A*&fq=id%3A%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F&fl=id,managed_purl_urls&wt=csv&rows=10000000&csv.header=false").split("\n")
end

def sw_druids(url)
  #SearchWorks production collection druids
  query = "/select?&fq=collection_type%3A%22Digital+Collection%22&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=csv&csv.header=false"
  # This first results statement finds all Digital Collections records with druids as ids (id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/))
  # the rest of the results statements look for records with catkeys, ie ids that start with a number
  id_array = ["%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F"] +  (1..9).map { |v| "#{v}*" }
  lb_results = id_array.map { |id| results("#{url + query}&fq=id%3A#{id}").split("\n")}.flatten
  druids_from_SearchWorks(lb_results).uniq.sort
end

def individual_items_released_in_argo_to_tgt(argo_ind_items, tgt)
  # Only care about druids released to specified tgt
  druids = []
  argo_ind_items.each do | res |
    pieces = res.split(',')
    # Look for searchworks in the second column for each result
    # and remove druid: prefix on druid in first column
    if ((!pieces[1].nil? && pieces[1].downcase == tgt) || tgt == "searchworkspreview")
      pieces[0].gsub! "druid:", ""
      druids.push(pieces[0])
    end
  end
  druids
end

argo_res = argo_druids(argo_url, sw_target)
pf_res = pf_druids(pf_url, sw_target)
sw_res = sw_druids(sw_url)

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
