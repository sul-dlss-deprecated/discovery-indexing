require 'spec_helper'
require 'purl_client'
require 'json'

describe PurlClient do
  subject { described_class.new(ENV['PF_URL'], ENV['SW_TGT']) }

  before do
    ENV['PF_URL']   = "purl_url"
    ENV['SW_TGT']   = "Searchworks"
  end

  describe '.results' do
    it 'executes the required query at the appropriate url and returns body' do
      data = ['abc']
      http_resp = double(body: data.to_json)

      uri = URI.parse('purl_url_search')
      expect(Net::HTTP).to receive(:get_response).with(uri).and_return(http_resp)
      resulting_json = subject.results('purl_url_search')
      expect(resulting_json).to eq(data.to_json)
    end
  end

  describe '.no_pages' do
    it 'returns total number of pages from the results' do
      inp = JSON.parse(File.open('spec/fixtures/purl_items_response1.json').read)
      pg = subject.no_pages(inp)
      expect(pg).to eq(6)
    end
  end

  describe '.ids_from_purl_fetcher' do
    it 'returns druids and catkeys from results' do
      inp = File.open('spec/fixtures/purl_coll_response1.json').read
      coll = JSON.parse(inp)
      ids = subject.ids_from_purl_fetcher(coll["collections"])
      expect(ids).to eq([["jh346sh2097", "9145819"], "xw274dm7079", ["rw431mw4432", "3195852"], "fs078sw0006", "nx585yw5390", "ys200gq1840", "gg286wk0365", "yw872fq2295", "tv224nt5377", "yp335tw7818"])
    end
    it 'returns only druid without prefix when no catkey exists' do
      inp = File.open('spec/fixtures/purl_coll_response1.json').read
      coll = JSON.parse(inp)
      expect(coll["collections"].any? { |hash| hash['druid'].include?('xw274dm7079') })
      ids = subject.ids_from_purl_fetcher(coll["collections"])
      expect(ids).to include("xw274dm7079", "fs078sw0006", "nx585yw5390", "ys200gq1840", "gg286wk0365", "yw872fq2295", "tv224nt5377", "yp335tw7818")
    end
    it 'returns druid without prefix and catkey if catkey exists' do
      inp = File.open('spec/fixtures/purl_coll_response1.json').read
      coll = JSON.parse(inp)
      expect(coll["collections"].any? { |hash| hash['catkey'].include?('9145819') })
      ids = subject.ids_from_purl_fetcher(coll["collections"])
      expect(ids).to include(["jh346sh2097", "9145819"],["rw431mw4432", "3195852"])
    end
  end

  describe '.individual_ids_from_purl_fetcher' do
    it 'returns druids and catkeys of items without associated collections from results' do
      inp = File.open('spec/fixtures/purl_items_response1.json').read
      purls = JSON.parse(inp)
      ids = subject.ids_from_purl_fetcher(purls["purls"])
      expect(ids).to eq([["cv301vb5243", "8537165"],["tp454dp0638","8537116"],["hk621tj0645","8537156"],["fh176zf4079","8537133"],"px491tp4561","gw196by8202",["pb603fs3989","8537126"],["vv695gh8211","8537152"],"cx054br0225",["fk368by4307","8537147"]])
    end
    it 'returns only druid without prefix when no catkey exists for items without associated collections' do
      inp = File.open('spec/fixtures/purl_items_response1.json').read
      purls = JSON.parse(inp)
      expect(purls["purls"].any? { |hash| hash['druid'].include?("px491tp4561") })
      ids = subject.ids_from_purl_fetcher(purls["purls"])
      expect(ids).to include("px491tp4561","gw196by8202","cx054br0225")
    end
    it 'returns druid without prefix and catkey if catkey exists for items without associated collections' do
      inp = File.open('spec/fixtures/purl_items_response1.json').read
      purls = JSON.parse(inp)
      expect(purls["purls"].any? { |hash| hash['catkey'].include?("8537116") })
      ids = subject.ids_from_purl_fetcher(purls["purls"])
      expect(ids).to include(["cv301vb5243", "8537165"],["tp454dp0638","8537116"],["hk621tj0645","8537156"],["fh176zf4079","8537133"],["pb603fs3989","8537126"],["vv695gh8211","8537152"],["fk368by4307","8537147"])
    end
  end

  describe '.collections_druids' do
    it 'returns collections druids from results' do
      inp = File.open('spec/fixtures/purl_coll_response.json').read
      expect(subject).to receive(:results).with(/collections/).and_return(inp)
      coll = subject.collections_druids
      expect(coll).to be_an Array
      expect(coll.length).to eq(10)
    end
    it 'loops over all result pages' do
      inp = File.open('spec/fixtures/purl_coll_response1.json').read
      expect(subject).to receive(:results).at_least(:once).times.with(/collections/).and_return(inp)
      coll = subject.collections_druids
    end
  end

  describe '.items_druids' do
    it 'returns items druids without associated collection from results' do
      inp = File.open('spec/fixtures/purl_items_response.json').read
      expect(subject).to receive(:results).with(/item/).and_return(inp)
      coll = subject.items_druids
      expect(coll).to be_an Array
      expect(coll.length).to eq(10)
    end
    it 'loops over all result pages' do
      inp = File.open('spec/fixtures/purl_items_response1.json').read
      expect(subject).to receive(:results).exactly(6).times.with(/item/).and_return(inp)
      coll = subject.items_druids
    end
  end

  describe '.druids_from_results' do
    it 'returns druids as a single array' do
      id_array = ["ab123cd4567",["aa111bb2222","cc333dd4444"],"xy232yz4545"]
      expect(subject).to receive(:druids_from_results).with(id_array).and_return(["ab123cd4567","aa111bb2222","cc333dd4444","xy232yz4545"])
      subject.druids_from_results(id_array)
    end
  end

  describe '.collection_members' do
    it 'returns items druids with associated collection from results' do
      inp = File.open('spec/fixtures/purls_sk373nx0013.json').read
      expect(subject).to receive(:results).with(/purls/).and_return(inp)
      coll = subject.collection_members("sk373nx0013")
      expect(coll).to be_an Array
      expect(coll.length).to eq(100)
    end
    it 'loops over all result pages' do
      inp = File.open('spec/fixtures/purls_sk373nx00131.json').read
      expect(subject).to receive(:results).exactly(10).times.with(/purls/).and_return(inp)
      coll = subject.collection_members("sk373nx0013")
    end
  end

  describe '.all_druids' do
    it 'returns druids from results' do
      inp = File.open('spec/fixtures/purl_items_response.json').read
      expect(subject).to receive(:results).with(/target=searchworks/).and_return(inp)
      all = subject.all_druids
      expect(all).to be_an Array
      expect(all.length).to eq(10)
    end
    it 'loops over all result pages' do
      inp = File.open('spec/fixtures/purl_items_response1.json').read
      expect(subject).to receive(:results).exactly(6).times.with(/target=searchworks/).and_return(inp)
      all = subject.all_druids
    end

  end

end
