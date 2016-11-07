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

  def coll_search(id)
    query = "/select?&fq=collection:#{id}&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=json"
  end

  def json_parsed_resp(url, query)
    JSON.parse(results("#{url + query}"))
  end

  def parse_json_results(res)
    res["response"]["docs"].each do |i|
      if /[0-9]*/.match(i["id"]) && i["managed_purl_urls"]
        i["managed_purl_urls"].each do |u|
          druid_ids.push(u.gsub!("http:\/\/purl.stanford.edu\/", ""))
        end
      else
        druid_ids.push(i["id"])
      end
    end
  end

  def druid_from_managed_purl(mpu)
    mpu.gsub!("\"", "")
    mpu.gsub!("http:\/\/purl.stanford.edu\/", "")
  end

  def druids_from_SearchWorks(results)
    druids = []
    results.each do | res |
      urls = res.split(",")
      urls.each do | url |
        if (url =~ /^[a-z]/)
          druid_from_managed_purl(url)
          druids.push(url)
        end
      end
    end
    druids
  end

  def collections_druids
    # SearchWorks production collection druids
    # Query is fq=collection_type:"Digital Collection", q=*:*
    # number of rows to output is 10000000
    # output fields are id and managed_purl_urls
    # output format is csv and don't want header data wt=csv&csv.header=false
    query = "/select?&fq=collection_type%3A%22Digital+Collection%22&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=csv&csv.header=false"
    # This first results statement finds all Digital Collections records with druids as ids (id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/))
    # the rest of the results statements look for records with catkeys, ie ids that start with a number
    id_array = ["%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F"] +  (1..9).map { |v| "#{v}*" }
    lb_results = id_array.map { |id| results("#{url + query}&fq=id%3A#{id}").split("\n")}.flatten
    druids_from_SearchWorks(lb_results).uniq.sort
  end

  def collections_ids
    # SearchWorks production collection druids
    # Query is fq=collection_type:"Digital Collection", q=*:*
    # number of rows to output is 10000000
    # output fields are id and managed_purl_urls
    # output format is csv and don't want header data wt=csv&csv.header=false
    query = "/select?&fq=collection_type%3A%22Digital+Collection%22&q=*%3A*&rows=10000000&fl=id&wt=csv&csv.header=false"
    results("#{url + query}").split("\n")
  end

  def items_druids
    ids = []
    # SearchWorks production item druids not in a collection
    # druid_id_query searches for records with druids as ids
    # Query is fq=id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/,  Id is in the format of a druid
    #          fq=building_facet:"Stanford Digital Repository", From SDR
    #          fq=-collection_type:"Digital Collection",  Not a collection record
    #          fq=-collection:*,                          Not associated with a collection
    #          q=*:*
    # output field is id
    # output format is csv and don't want header data wt=csv&csv.header=false
    druid_id_query = "/select?q=*%3A*&fq=id%3A%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F&fq=building_facet%3A%22Stanford+Digital+Repository%22&fq=-collection_type%3A%22Digital+Collection%22&fq=-collection%3A*&rows=10000000&fl=id&wt=csv&csv.header=false"
    # ckey_id_query searches for records with catkeys as ids
    # Query is fq=id:/[0-9]*/,                            Id is in the format of a catkey (all numbers)
    #          fq=building_facet:"Stanford Digital Repository", From SDR
    #          fq=-collection_type:"Digital Collection",  Not a collection record
    #          fq=collection:sirsi,                       Associated with sirsi collection (MARC record)
    #          q=*:*
    # output fields are id, managed_purl_urls, and collection
    # output format is json
    ckey_id_query = "/select?fq=-collection_type%3A%22Digital+Collection%22&fq=collection%3A%22sirsi%22&fq=id%3A%2F%5B0-9%5D*%2F&fq=building_facet%3A%22Stanford+Digital+Repository%22&q=*%3A*&rows=100000&fl=id%2Cmanaged_purl_urls%2Ccollection&wt=json"
    # This first results statement finds all item records with druids as ids (id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/))
    # the rest of the results statements look for records with catkeys, ie ids that start with a number
    ids = results("#{url + druid_id_query}").split("\n").flatten
    ckey_resp = JSON.parse(results("#{url + ckey_id_query}"))
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
          ids.push(druid_from_managed_purl(f))
        end
      end
    end
    ids.uniq.sort
  end

  def collection_members(coll_druid)
    # collection members for searchworks - determined by looking for records that have the collection druid or catkey
    # Query is fq=collection:coll_druid, q=*:*
    # number of rows to output is 10000000
    # output fields are id and managed_purl_urls
    # output format is csv and don't want header data wt=csv&csv.header=false
    druid_ids = []
    query = coll_search(coll_druid)
    res = json_parsed_resp(url, query)
    # if there are no results, the collection has a catkey
    if res["response"]["numFound"] == 0
      # Get the catkey by finding the corresponding managed_purl_urls
      ckey = ckey_from_druid(coll_druid)
      query = coll_search(ckey)
      res = json_parsed_resp(url, query)
    end
    druid_ids += parse_json_results(res)
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
