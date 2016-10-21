require 'rubygems'
require 'net/http'
require 'uri'

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

  def collection_members(coll_druid)
    # coll_members_from_sw
    query = "/select?&fq=collection:#{coll_druid}&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls&wt=csv&csv.header=false"
    id_array = ["%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F"] +  (1..9).map { |v| "#{v}*" }
    lb_results = id_array.map { |id| results("#{url + query}&fq=id%3A#{id}").split("\n")}.flatten
    druids_from_SearchWorks(lb_results).uniq.sort
  end
end
