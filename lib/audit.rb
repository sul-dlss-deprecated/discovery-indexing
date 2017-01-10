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

class Audit
  attr_reader :argo_client, :purl_client, :sw_client, :argo_url, :pf_url, :sw_url, :tgt, :report_type, :collection_druid

  def initialize(argo_url, pf_url, sw_url, tgt, report_type=nil, collection_druid=nil)
    @argo_url = argo_url
    @pf_url = pf_url
    @sw_url   = sw_url
    @tgt = tgt.downcase
    @report_type = report_type
    @collection_druid = collection_druid
    @argo_client = ArgoClient.new(argo_url, tgt)
    @purl_client = PurlClient.new(pf_url, tgt)
    @sw_client   = SwClient.new(sw_url)
  end

  def differences(ar, pf, sw)
    diff = {}
    diff["argo_pf"] = ar - pf
    diff["argo_sw"] = ar - sw
    diff["pf_argo"] = pf - ar
    diff["pf_sw"]   = pf - sw
    diff["sw_argo"] = sw - ar
    diff["sw_pf"]   = sw - pf
    diff
  end

  def system(s)
    case s
    when "argo"
      "Argo"
    when "pf"
      "PURL"
    when "sw"
      "Searchworks"
    end
  end

  def rpt_output(com)
    com.keys.each do |c|
      sys = c.split("_")
      first = system(sys[0])
      second = system(sys[1])
      if (com[c].length > 0)
        puts("These #{com[c].length} druids are in #{first} as released to #{tgt} but not in #{second}")
        puts com[c]
      else
        puts("Same druids in #{first} and #{second} are released to #{tgt}")
      end
    end
    puts ''
    puts '====================================================================='
    puts ''
  end

  def collections_summary()
    argo_coll = argo_client.collections_druids
    pf_coll = purl_client.collections_druids
    sw_coll = sw_client.collections_druids

    puts("Collections Statistics")
    puts("Argo has #{argo_coll.length} released to #{tgt}")
    puts("PURL has #{pf_coll.length} released to #{tgt}")
    puts("SW has #{sw_coll.length} released to #{tgt}")

    rpt_output(differences(argo_coll, pf_coll, sw_coll))

  end

  def individual_items_summary()

    argo_items = argo_client.items_druids
    pf_items = purl_client.items_druids
    sw_items = sw_client.items_druids

    puts("Individual Items Statistics")
    puts("Argo has #{argo_items.length} released to #{tgt}")
    puts("PURL has #{pf_items.length} released to #{tgt}")
    puts("SW has #{sw_items.length} released to #{tgt}")

    rpt_output(differences(argo_items, pf_items, sw_items))

  end

  def individual_collection_summary()

    fail "Must provide Environment variable COLL_DRUID with this script" if collection_druid.nil?
    argo_mem = argo_client.collection_members(collection_druid)
    pf_mem = purl_client.collection_members(collection_druid)
    sw_mem = sw_client.collection_members(collection_druid)

    puts("Individual Collection Statistics")
    puts("Argo has #{argo_mem.length} members in collection #{collection_druid} released to #{tgt}")
    puts("PURL has #{pf_mem.length} members in collection #{collection_druid} released to #{tgt}")
    puts("SW has #{sw_mem.length} members in collection #{collection_druid} released to #{tgt}")

    rpt_output(differences(argo_mem, pf_mem, sw_mem))

  end

  def everything_released_summary()
    argo_all = argo_client.all_druids
    pf_all = purl_client.all_druids
    sw_all = sw_client.all_druids

    puts("Everything Statistics")
    puts("Argo has #{argo_all.length} released to #{tgt}")
    puts("PURL has #{pf_all.length} released to #{tgt}")
    puts("SW has #{sw_all.length} released to #{tgt}")

    rpt_output(differences(argo_all, pf_all, sw_all))

  end

  def rpt_select
    case report_type
    when "Collections Summary"
      collections_summary()
    when "Individual Items Summary"
      individual_items_summary()
    when "Collection-specific Summary"
      individual_collection_summary()
    when "Everything Released Summary"
      everything_released_summary()
    else
      collections_summary()
    end
  end

end
