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

    end
    it 'downcases the values in the true_targets data' do

    end
    it 'returns only druid without prefix when no catkey exists' do

    end
    it 'returns druid without prefix and catkey if catkey exists' do

    end
  end

  describe '.individual_ids_from_purl_fetcher' do
    it 'returns druids and catkeys of items without associated collections from results' do

    end
    it 'downcases the values in the true_targets data' do

    end
    it 'returns only druid without prefix when no catkey exists for items without associated collections' do

    end
    it 'returns druid without prefix and catkey if catkey exists for items without associated collections' do

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
      expect(subject).to receive(:results).exactly(4).times.with(/collections/).and_return(inp)
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
