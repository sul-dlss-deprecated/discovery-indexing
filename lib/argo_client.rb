require 'rubygems'
require 'net/http'
require 'uri'

class ArgoClient
  attr_reader :url, :tgt

  def initialize(url, tgt)
    @url = url
    @tgt = tgt
  end

  def results(url_with_params)
    res_url = URI.parse(url_with_params)
    Net::HTTP.get_response(res_url).body
  end

  def collections_druids
    # Argo collection druids
    query = "/select?&fq=objectType_ssim:%22collection%22&fl=id,released_to_ssim,catkey_id_ssim&rows=10000&sort=id%20asc&wt=csv&csv.header=false"
    argo_coll_results = results("#{url + query}").split("\n")
    individual_items_released_to_tgt(argo_coll_results)
  end

  def individual_items_released_to_tgt(argo_ind_items)
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

end