require 'rubygems'
require 'net/http'
require 'uri'
require 'json'

class SwClient
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def results(url_with_params)
    res_url = URI.parse(url_with_params)
    Net::HTTP.get_response(res_url).body
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

  def collections_druids
    #SearchWorks production collection druids
    query = "/select?&fq=collection_type%3A%22Digital+Collection%22&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=csv&csv.header=false"
    # This first results statement finds all Digital Collections records with druids as ids (id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/))
    # the rest of the results statements look for records with catkeys, ie ids that start with a number
    id_array = ["%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F"] +  (1..9).map { |v| "#{v}*" }
    lb_results = id_array.map { |id| results("#{url + query}&fq=id%3A#{id}").split("\n")}.flatten
    druids_from_SearchWorks(lb_results).uniq.sort
  end

  def items_druids
    ids = []
    #SearchWorks production item druids not in a collection
    druid_id_query = "/select?q=*%3A*&fq=id%3A%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F&fq=building_facet%3A%22Stanford+Digital+Repository%22&fq=-collection_type%3A%22Digital+Collection%22&fq=-collection%3A*&rows=10000000&fl=id&wt=csv&csv.header=false"
    query = "/select?fq=-collection_type%3A%22Digital+Collection%22&fq=collection%3A%22sirsi%22&fq=id%3A%2F%5B0-9%5D*%2F&fq=building_facet%3A%22Stanford+Digital+Repository%22&q=*%3A*&rows=100000&fl=id%2Cmanaged_purl_urls,collection&wt=json"
    # This first results statement finds all item records with druids as ids (id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/))
    # the rest of the results statements look for records with catkeys, ie ids that start with a number
    ids = results("#{url + druid_id_query}").split("\n").flatten
    ckey_resp = JSON.parse(results("#{url + query}"))
    inter = []
    ckey_resp["response"]["docs"].each do |c|
      if c["collection"].length < 2
        inter.push(c)
      end
    end
    inter.each do |i|
      if i["managed_purl_urls"]
        flat = i["managed_purl_urls"].flatten
        flat.each do |f|
          ids.push(f.gsub("http:\/\/purl.stanford.edu\/", ""))
        end
      end
    end
    ids.uniq.sort
  end

  def collection_members(coll_druid)
    # coll_members_from_sw
    query = "/select?&fq=collection:#{coll_druid}&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=csv&csv.header=false"
    id_array = ["%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F"] +  (1..9).map { |v| "#{v}*" }
    lb_results = id_array.map { |id| results("#{url + query}&fq=id%3A#{id}").split("\n")}.flatten
    # if the collection searchworks id is not a druid but is a catkey instead, the lb_results will be an empty Array
    # So need to determine the catkey of the collection.  The best way to determine that is to look for the collection
    # druid in the managed_purl_urls and returning the id
    if lb_results.length == 0
      coll_ckey = ckey_from_druid(coll_druid)
      member_query = "/select?fq=collection%3A#{coll_ckey}&fl=id&rows=100000&wt=csv&&csv.header=false"
      lb_results = results("#{url + member_query}").split("\n").flatten
      druid_ids=[]
      lb_results.each do |item|
        if item =~ /^[0-9]/
          druid_ids.push(druid_from_ckey(item))
        else
          druid_ids.push(item)
        end
      end
    end
    druid_ids.uniq.sort
  end

  def ckey_from_druid(druid)
    query = "/select?fq=managed_purl_urls%3A*#{druid}&fl=id&wt=csv&&csv.header=false"
    results("#{url + query}").gsub!("\n","")
  end

  def druid_from_ckey(ckey)
    query = "/select?fq=id%3A#{ckey}&fl=managed_purl_urls&wt=csv&&csv.header=false"
    results("#{url + query}").gsub!("\n","").gsub!("http:\/\/purl.stanford.edu\/", "")
  end

  def all_druids
    # All SearchWorks production druids from the digital repository
    query = "/select?&fq=managed_purl_urls%3A*&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=csv&csv.header=false"
    # This first results statement finds all records with druids as ids (id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/))
    # the rest of the results statements look for records with catkeys, ie ids that start with a number
    druid_id_query = "/select?q=*%3A*&fq=id%3A%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=csv&indent=true"
    druid_ids = results("#{url + druid_id_query}").split(",\n").flatten
    druid_ids += results("#{url + query}").split("\n").flatten
    druids_from_SearchWorks(druid_ids).uniq.sort
  end

end
