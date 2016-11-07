require 'rubygems'
require 'json'
require 'net/http'
require 'uri'

class PurlClient
  attr_reader :url, :tgt

  def initialize(url, tgt)
    @url = url
    @tgt = tgt.downcase
  end

  def results(url_with_params)
    res_url = URI.parse(url_with_params)
    Net::HTTP.get_response(res_url).body
  end

  def no_pages(data)
    data["pages"]["total_pages"]
  end

  def ids_from_purl_fetcher(data)
    data_ids = []
    data.each do | d |
      if !d["true_targets"].nil? && !d["true_targets"].empty?
        d["true_targets"].map!(&:downcase)
        if d["true_targets"].any? { |t| t == tgt }
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

  def individual_ids_from_purl_fetcher(data)
    data_ids = []
    data.each do | d |
      if !d["true_targets"].nil? && !d["true_targets"].empty?
        d["true_targets"].map!(&:downcase)
        if d["true_targets"].any? { |t| t == tgt }
          if d["collections"].nil? || d["collections"].empty?
            if d["catkey"].nil? || d["catkey"].empty?
              data_ids.push(d["druid"].gsub(/druid:/, ''))
            else
              data_ids.push([d["druid"].gsub(/druid:/, ''), d["catkey"]])
            end
          end
        end
      end
    end
    data_ids
  end

  def collections_druids
    # Purl_fetcher collection druids
    query = "/collections"
    coll = JSON.parse(results("#{url + query}"))

    coll_ids = []
    coll_ids += ids_from_purl_fetcher(coll["collections"])

    (2..no_pages(coll)).each do |i|
      coll = JSON.parse(results("#{url + query}?page=#{i}"))
      coll_ids += ids_from_purl_fetcher(coll["collections"])
    end

    druids_from_results(coll_ids)
  end

  def items_druids
    # Purl_fetcher item druids that are not in collections
    query = "/purls?membership=none&object_type=item&per_page=10000"
    purls = JSON.parse(results("#{url + query}"))

    item_ids = []
    item_ids += individual_ids_from_purl_fetcher(purls["purls"])

    (2..no_pages(purls)).each do |i|
      purls = JSON.parse(results("#{url + query}&page=#{i}"))
      item_ids += individual_ids_from_purl_fetcher(purls["purls"])
    end

    druids_from_results(item_ids)
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
    druids.sort
  end

  def collection_members(coll_druid)
    # coll_members_from_pf
    query = "/collections/druid:#{coll_druid}/purls"
    mem = JSON.parse(results("#{url + query}"))

    mem_ids = []
    mem_ids += ids_from_purl_fetcher(mem["purls"])

    (2..no_pages(mem)).each do |i|
      mem = JSON.parse(results("#{url + query}?page=#{i}"))
      mem_ids += ids_from_purl_fetcher(mem["purls"])
    end

    druids_from_results(mem_ids)
  end

  def all_druids
    # Purl_fetcher all druids
    # Query is for all druids with true or false target equal to Searchworks
    query = "/purls?target=#{tgt}"
    all = JSON.parse(results("#{url + query}"))

    all_ids = []
    all_ids += ids_from_purl_fetcher(all['purls'])

    (2..no_pages(all)).each do |i|
      puts i
      all = JSON.parse(results("#{url + query}&page=2"))
      all_ids += ids_from_purl_fetcher(all["purls"])
    end

    druids_from_results(all_ids)
  end

end
