require 'spec_helper'
require 'audit'

describe 'Audit' do
  subject { described_class.new(ENV['ARGO_URL'], ENV['PF_URL'], ENV['SW_URL'], ENV['SW_TGT'], report_type=nil, collection_druid=nil) }

  before do
    ENV['ARGO_URL']   = "argo_url"
    ENV['PF_URL']   = "purl_url"
    ENV['SW_URL']   = "sw_url"
    ENV['SW_TGT']   = "Searchworks"
  end

  describe '.initialize' do
    it 'will set the appropriate local variables' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      expect(a.argo_url).to eq('argo_url')
      expect(a.pf_url).to eq('pf_url')
      expect(a.sw_url).to eq('sw_url')
      expect(a.tgt).to eq('searchworks')
      expect(a.report_type).to eq(nil)
      expect(a.collection_druid).to eq(nil)
    end
    it 'will instantiate an argo client' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      expect(a.argo_client).to be_an ArgoClient
      expect(a.argo_client.url).to eq('argo_url')
      expect(a.argo_client.tgt).to eq('searchworks')
    end
    it 'will instantiate an purl fetcher client' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      expect(a.purl_client).to be_an PurlClient
      expect(a.purl_client.url).to eq('pf_url')
      expect(a.purl_client.tgt).to eq('searchworks')
    end
    it 'will instantiate an searchworks client' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      expect(a.sw_client).to be_an SwClient
      expect(a.sw_client.url).to eq('sw_url')
    end
  end

  describe '.differences' do
    it 'returns druids for items from argo that are not in the results from purl fetcher' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','bb111dd2222','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(d["argo_pf"]).to eq(["bb111dd2222"])
      expect(d["argo_sw"]).to eq([])
    end
    it 'returns druids for items from argo that are not in the results from searchworks' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(d["argo_sw"]).to eq(["bb111dd2222"])
    end
    it 'returns druids for items from purl fetcher that are not in the results from argo' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(d["pf_argo"]).to eq(["dd111aa2222"])
    end
    it 'returns druids for items from purl fetcher that are not in the results from searchworks' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(d["pf_sw"]).to eq(["dd111aa2222"])
    end
    it 'returns druids for items from searchworks that are not in the results from argo' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(d["sw_argo"]).to eq(["ee111ff2222"])
    end
    it 'returns druids for items from searchworks that are not in the results from purl fetcher' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(d["sw_pf"]).to eq(["ee111ff2222"])
    end
  end

  describe '.system' do
    it 'returns the appropriate string based upon input' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      expect(a.system('argo')).to eq('Argo')
      expect(a.system('pf')).to eq('PURL')
      expect(a.system('sw')).to eq('Searchworks')
    end
  end

  describe '.rpt_output' do
    it 'outputs summary information and druids from the differences' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','bb111dd2222','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(a.rpt_output(d)).to include("These 1 druids are in Argo as released to searchworks but not in PURL", ["bb111dd2222"])
      expect(a.rpt_output(d)).to include("These 1 druids are in PURL as released to searchworks but not in Argo",["dd111aa2222"])
      expect(a.rpt_output(d)).to include("These 1 druids are in PURL as released to searchworks but not in Searchworks",["dd111aa2222"])
      expect(a.rpt_output(d)).to include("These 1 druids are in Searchworks as released to searchworks but not in Argo",["ee111ff2222"])
      expect(a.rpt_output(d)).to include("These 2 druids are in Searchworks as released to searchworks but not in PURL",["bb111dd2222","ee111ff2222"])
    end
    it 'outputs same statement when the difference is nil' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','bb111dd2222','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      d = a.differences(ar, pf, sw)
      expect(a.rpt_output(d)).to include("Same druids in Argo and Searchworks are released to searchworks")
    end
  end

  describe '.collections_summary' do
    it 'outputs collections summary' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','bb111dd2222','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks','Collections Summary')
      expect(a.argo_client).to receive(:collections_druids).at_least(:once).times.and_return(ar)
      expect(a.purl_client).to receive(:collections_druids).at_least(:once).times.and_return(pf)
      expect(a.sw_client).to receive(:collections_druids).at_least(:once).times.and_return(sw)
      expect(a.collections_summary()).to include('Collections Statistics')
      expect(a.collections_summary()).to include('Argo has 3 released to searchworks')
      expect(a.collections_summary()).to include('PURL has 3 released to searchworks')
      expect(a.collections_summary()).to include('SW has 4 released to searchworks')
    end
  end

  describe '.individual_items_summary' do
    it 'outputs individual items summary' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','bb111dd2222','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks','Individual Items Summary')
      expect(a.argo_client).to receive(:items_druids).at_least(:once).times.and_return(ar)
      expect(a.purl_client).to receive(:items_druids).at_least(:once).times.and_return(pf)
      expect(a.sw_client).to receive(:items_druids).at_least(:once).times.and_return(sw)
      expect(a.individual_items_summary()).to include('Individual Items Statistics')
      expect(a.individual_items_summary()).to include('Argo has 3 released to searchworks')
      expect(a.individual_items_summary()).to include('PURL has 3 released to searchworks')
      expect(a.individual_items_summary()).to include('SW has 4 released to searchworks')
    end
  end

  describe '.individual_collection_summary' do
    it 'outputs individual collection summary' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','bb111dd2222','ee111ff2222']
      collection_druid = 'aa123bb1212'
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks', 'Collection-specific Summary', collection_druid)
      expect(a.argo_client).to receive(:collection_members).with(collection_druid).at_least(:once).times.and_return(ar)
      expect(a.purl_client).to receive(:collection_members).with(collection_druid).at_least(:once).times.and_return(pf)
      expect(a.sw_client).to receive(:collection_members).with(collection_druid).at_least(:once).times.and_return(sw)
      expect(a.individual_collection_summary()).to include('Individual Collection Statistics')
      expect(a.individual_collection_summary()).to include('Argo has 3 members in collection aa123bb1212 released to searchworks')
      expect(a.individual_collection_summary()).to include('PURL has 3 members in collection aa123bb1212 released to searchworks')
      expect(a.individual_collection_summary()).to include('SW has 4 members in collection aa123bb1212 released to searchworks')
    end
  end

  describe '.everything_released_summary' do
    it 'outputs everything released summary' do
      ar = ['aa111bb2222','aa111cc3333','bb111dd2222']
      pf = ['aa111bb2222','aa111cc3333','dd111aa2222']
      sw = ['aa111bb2222','aa111cc3333','bb111dd2222','ee111ff2222']
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks', 'Everything Released Summary')
      expect(a.argo_client).to receive(:all_druids).at_least(:once).times.and_return(ar)
      expect(a.purl_client).to receive(:all_druids).at_least(:once).times.and_return(pf)
      expect(a.sw_client).to receive(:all_druids).at_least(:once).times.and_return(sw)
      expect(a.everything_released_summary()).to include('Everything Statistics')
      expect(a.everything_released_summary()).to include('Argo has 3 released to searchworks')
      expect(a.everything_released_summary()).to include('PURL has 3 released to searchworks')
      expect(a.everything_released_summary()).to include('SW has 4 released to searchworks')
    end
  end

  describe '.rpt_select' do
    it 'calls the collections_summary when report_type is Collections Summary' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks', 'Collections Summary')
      expect(a).to receive(:collections_summary).once
      a.rpt_select
    end
    it 'calls the individual_items_summary when report_type is Individual Items Summary' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks', 'Individual Items Summary')
      expect(a).to receive(:individual_items_summary).once
      a.rpt_select
    end
    it 'calls the individual_collection_summary when report_type is Collection-specific Summary' do
      collection_druid = 'aa123bb1212'
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks', 'Collection-specific Summary', collection_druid)
      expect(a).to receive(:individual_collection_summary).once
      a.rpt_select
    end
    it 'calls the everything_released_summary when report_type is Everything Released Summary' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks', 'Everything Released Summary')
      expect(a).to receive(:everything_released_summary).once
      a.rpt_select
    end
    it 'calls the collections_summary when report_type is nil or not one of the other valid report_types' do
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks')
      expect(a).to receive(:collections_summary).once
      a.rpt_select
    end
  end
end
