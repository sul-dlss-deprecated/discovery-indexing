require 'spec_helper'
require 'argo_client'
require 'json'

describe ArgoClient do
  subject { described_class.new(ENV['ARGO_URL'], ENV['SW_TGT']) }

  before do
    ENV['ARGO_URL']   = "argo_url"
    ENV['SW_TGT']     = "Searchworks"
  end

  describe '.collections_info' do
    it 'receives results with object type of collection' do
      expect(subject).to receive(:results).with(/fq=objectType_ssim%3A%22collection%22/).and_return(nil)
      subject.collections_info
    end
  end

  describe '.collections_druids' do
    it 'receives results with object type of collection' do
      inp = JSON.parse(File.open('spec/fixtures/argo_coll_response.json').read)
      expect(subject).to receive(:results).with(/fq=objectType_ssim%3A%22collection%22/).and_return(inp)
      coll = subject.collections_druids
      expect(coll).to be_an Array
      expect(coll.length).to eq(28)
    end
    it 'receives results with a value in the released_to_ssim field' do
      inp = JSON.parse(File.open('spec/fixtures/argo_coll_response.json').read)
      expect(subject).to receive(:results).with(/fq=released_to_ssim%3A*/).and_return(inp)
      coll = subject.collections_druids
      expect(coll).to be_an Array
      expect(coll.length).to eq(28)
    end
  end

  describe '.items_druids' do
    it 'receives results with object type of item' do
      inp = JSON.parse(File.open('spec/fixtures/argo_item_response.json').read)
      expect(subject).to receive(:results).with(/fq=objectType_ssim%3A%22item%22/).and_return(inp)
      item = subject.items_druids
      expect(item).to be_an Array
      expect(item.length).to eq(1789)
    end
    it 'receives results that are not in collections' do
      inp = JSON.parse(File.open('spec/fixtures/argo_item_response.json').read)
      expect(subject).to receive(:results).with(/fq=-is_member_of_collection_ssim%3A*/).and_return(inp)
      item = subject.items_druids
      expect(item).to be_an Array
      expect(item.length).to eq(1789)
    end
    it 'receives results with a value in the released_to_ssim field' do
      inp = JSON.parse(File.open('spec/fixtures/argo_item_response.json').read)
      expect(subject).to receive(:results).with(/fq=released_to_ssim%3A*/).and_return(inp)
      item = subject.items_druids
      expect(item).to be_an Array
      expect(item.length).to eq(1789)
    end
  end

  describe '.all_druids' do
    it 'receives results with a value in the released_to_ssim field' do
      inp = JSON.parse(File.open('spec/fixtures/argo_all_items_response.json').read)
      expect(subject).to receive(:results).with(/fq=released_to_ssim%3A*/).and_return(inp)
      all = subject.all_druids
      expect(all).to be_an Array
      expect(all.length).to eq(50628)
    end
  end

  describe '.collection_members' do
    it 'receives results for items that are members of the specified collection' do
      inp = JSON.parse(File.open('spec/fixtures/argo_coll_members_response.json').read)
      expect(subject).to receive(:results).with(/fq=is_member_of_collection_ssim%3A%22info%3Afedora\/druid%3Acoll_druid%22/).and_return(inp)
      coll_mem = subject.collection_members("coll_druid")
      expect(coll_mem).to be_an Array
      expect(coll_mem.length).to eq(5)
      expect(coll_mem).to eq(['jf275fd6276','nz353cp1092','tc552kq0798','th998nk0722','ww689vs6534'])
    end
  end

  describe '.individual_items_released_to_tgt' do
    it 'produces expected alphabetically sorted druid list' do
      inp = JSON.parse(File.open('spec/fixtures/argo_coll_members_response.json').read)
      druids = subject.individual_items_released_to_tgt(inp)
      expect(druids).to eq(['jf275fd6276','nz353cp1092','tc552kq0798','th998nk0722','ww689vs6534'])
    end
    it 'does not add a druid to the druid list if the indicated solr target is not included in the released_to_ssim field' do
      inp = JSON.parse(File.open('spec/fixtures/argo_item_response.json').read)
      druids = subject.individual_items_released_to_tgt(inp)
      expect(druids).not_to include('ct164dj3407') # released_to_ssim = "Nothing"
    end
    it 'does not add a druid to the druid list if the indicated processing status is Registered' do
      inp = JSON.parse(File.open('spec/fixtures/argo_item_response.json').read)
      druids = subject.individual_items_released_to_tgt(inp)
      expect(druids).not_to include('cs903vw3849') # processing_status_text_ssi = "Registered"
    end
    it 'does not add a druid to the druid list if the indicated rights description includes dark' do
      inp = JSON.parse(File.open('spec/fixtures/argo_item_response.json').read)
      druids = subject.individual_items_released_to_tgt(inp)
      expect(druids).not_to include('cs238vc8125') # rights_descriptions_ssim = "dark"
    end
  end

  describe '.results' do
    it 'executes the required query at the appropriate url and returns json' do
      data = ['abc']
      http_resp = double(body: data.to_json)

      uri = URI.parse('argo_url_search')
      expect(Net::HTTP).to receive(:get_response).with(uri).and_return(http_resp)
      resulting_json = subject.results('_search')
      expect(resulting_json).to eq(data)
    end
  end

end
