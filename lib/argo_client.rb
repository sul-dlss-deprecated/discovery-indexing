require 'rubygems'
require 'net/http'
require 'uri'

class ArgoClient
  attr_reader :url, :tgt

  def initialize(url, tgt)
    @url = url
    @tgt = tgt.downcase
  end

  def results(query)
    res_url = URI.parse("#{url + query}")
    JSON.parse(Net::HTTP.get_response(res_url).body)
  end

  def collections_info
    # Argo collection information
    # Query is fq=objectType_ssim:"collection", fq=released_to_ssim:*
    # number of rows to output is 10000
    # output fields are id, catkey_id_ssim, and title_info_0_main_title_ssim
    # output ascending sorted by id
    # output format is json
    query = "/select?&fq=objectType_ssim%3A%22collection%22&fl=id,catkey_id_ssim,title_info_0_main_title_ssim&rows=10000&sort=id%20asc&wt=json"
    results(query)
  end

  def collections_druids
    # Argo collection druids
    # Query is fq=objectType_ssim:"collection", fq=released_to_ssim:*
    # number of rows to output is 10000
    # output fields are id, released_to_ssim, catkey_id_ssim, processing_status_text_ssi, rights_descriptions_ssim
    # output ascending sorted by id
    # output format is json
    query = "/select?&fq=objectType_ssim%3A%22collection%22&fq=released_to_ssim%3A*&fl=id,released_to_ssim,catkey_id_ssim,processing_status_text_ssi,rights_descriptions_ssim&rows=10000&sort=id%20asc&wt=json"
    individual_items_released_to_tgt(results(query))
  end

  def items_druids
    # Argo item druids released but not in a collection
    # Query is fq=-is_member_of_collection_ssim:*, fq=objectType_ssim:"item", fq=released_to_ssim:*
    # number of rows to output is 10000
    # output fields are id, released_to_ssim, catkey_id_ssim, processing_status_text_ssi, rights_descriptions_ssim
    # output ascending sorted by id
    # output format is json
    query = "/select?fq=-is_member_of_collection_ssim%3A*&fq=objectType_ssim%3A%22item%22&fq=released_to_ssim%3A*&fl=id,released_to_ssim,catkey_id_ssim,processing_status_text_ssi,rights_descriptions_ssim&rows=10000&sort=id%20asc&wt=json"
    individual_items_released_to_tgt(results(query))
  end

  def all_druids
    # All Argo druids released to target
    # Query is fq=released_to_ssim:*
    # number of rows to output is 1000000
    # output fields are id, released_to_ssim, catkey_id_ssim, processing_status_text_ssi, rights_descriptions_ssim
    # output ascending sorted by id
    # output format is json
    query = "/select?&fq=released_to_ssim%3A*&q=*%3A*&fl=id,released_to_ssim,catkey_id_ssim,processing_status_text_ssi,rights_descriptions_ssim&rows=1000000&sort=id%20asc&wt=json"
    individual_items_released_to_tgt(results(query))
  end

  def collection_members(coll_druid)
    # coll_members_from_argo
    # Query is fq=is_member_of_collection_ssim:"info:fedora/druid:#{coll_druid}", fq=released_to_ssim:*
    # number of rows to output is 1000000
    # output fields are id, released_to_ssim, catkey_id_ssim, processing_status_text_ssi, rights_descriptions_ssim
    # output ascending sorted by id
    # output format is json
    query = "/select?&fq=is_member_of_collection_ssim%3A%22info%3Afedora/druid%3A#{coll_druid}%22&fq=released_to_ssim%3A*&fl=id,released_to_ssim,catkey_id_ssim,processing_status_text_ssi,rights_descriptions_ssim&rows=1000000&sort=id%20asc&wt=json"
    individual_items_released_to_tgt(results(query))
  end

  def individual_items_released_to_tgt(argo_ind_items)
    # Only care about druids released to specified tgt with processing status anything but Registered and
    # rights anything but dark
    druids = []
    argo_ind_items["response"]["docs"].each do | res |
      if res["processing_status_text_ssi"] != "Registered" && !res["rights_descriptions_ssim"].include?("dark")
        res["released_to_ssim"].map!(&:downcase)
        uniq_tgt = res["released_to_ssim"].uniq
        if uniq_tgt.include? tgt
          druids.push(res["id"].gsub! "druid:", "")
        end
      end
    end
    druids.uniq.sort
  end

  def coll_info(colls)
    coll_data = {}
    colls["response"]["docs"].each do | res |
      res["id"].gsub!("druid:", "")
      coll_data[res["id"]] = { "catkey" => res["catkey_id_ssim"],"title" => res["title_info_0_main_title_ssim"]}
    end
    coll_data
  end

end
