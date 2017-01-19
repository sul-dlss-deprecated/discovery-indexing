require 'spec_helper'
require 'audit'

describe Audit do
  subject { described_class.new(ENV['ARGO_URL'], ENV['PF_URL'], ENV['SW_URL'], ENV['SW_TGT'], report_type=nil, collection_druid=nil) }

  let(:ar) { ['aa111bb2222','aa111cc3333','bb111dd2222','cc111dd2222'] }
  let(:pf) { ['aa111bb2222','aa111cc3333','dd111aa2222','ee123ff1212'] }
  let(:sw) { ['aa111bb2222','aa111cc3333','bb111dd2222','cc111dd2222','dd111aa2222','ee111ff2222'] }
  let(:differences) { subject.differences(ar, pf, sw) }
  before do
    ENV['ARGO_URL']   = "argo_url"
    ENV['PF_URL']   = "purl_url"
    ENV['SW_URL']   = "sw_url"
    ENV['SW_TGT']   = "Searchworks"
  end

  describe '.differences' do
    it 'returns druids for items from argo that are not in the results from purl fetcher' do
      expect(differences["argo_pf"]).to eq(["bb111dd2222", "cc111dd2222"])
    end
    it 'returns druids for items from argo that are not in the results from searchworks' do
      expect(differences["argo_sw"]).to eq([])
    end
    it 'returns druids for items from purl fetcher that are not in the results from argo' do
      expect(differences["pf_argo"]).to eq(["dd111aa2222", "ee123ff1212"])
    end
    it 'returns druids for items from purl fetcher that are not in the results from searchworks' do
      expect(differences["pf_sw"]).to eq(["ee123ff1212"])
    end
    it 'returns druids for items from searchworks that are not in the results from argo' do
      expect(differences["sw_argo"]).to eq(["dd111aa2222", "ee111ff2222"])
    end
    it 'returns druids for items from searchworks that are not in the results from purl fetcher' do
      expect(differences["sw_pf"]).to eq(["bb111dd2222", "cc111dd2222", "ee111ff2222"])
    end
  end

  describe '.system' do
    it 'returns the appropriate string based upon input' do
      expect(subject.system('argo')).to eq('Argo')
      expect(subject.system('pf')).to eq('PURL')
      expect(subject.system('sw')).to eq('Searchworks')
    end
  end

  describe '.rpt_hash' do
    it 'outputs summary information and druids from the differences' do
      expect(subject.rpt_hash(differences)).to include("Argo" => {"PURL"=>{"text"=>"2 druids are in Argo as released to searchworks but not in PURL", "druids"=>["bb111dd2222", "cc111dd2222"], "length"=>2}, "Searchworks"=>{"text"=>"Same druids in Argo and Searchworks are released to searchworks"}})
      expect(subject.rpt_hash(differences)).to include("PURL" => {"Argo"=>{"text"=>"2 druids are in PURL as released to searchworks but not in Argo", "druids"=>["dd111aa2222", "ee123ff1212"], "length"=>2}, "Searchworks"=>{"text"=>"1 druids are in PURL as released to searchworks but not in Searchworks", "druids"=>["ee123ff1212"], "length"=>1}})
      expect(subject.rpt_hash(differences)).to include("Searchworks" => {"Argo"=>{"text"=>"2 druids are in Searchworks as released to searchworks but not in Argo", "druids"=>["dd111aa2222", "ee111ff2222"], "length"=>2}, "PURL"=>{"text"=>"3 druids are in Searchworks as released to searchworks but not in PURL", "druids"=>["bb111dd2222", "cc111dd2222", "ee111ff2222"], "length"=>3}})
    end
    it 'outputs same statement when the difference is nil' do
      expect(subject.rpt_hash(differences)).to include("Argo" => {"PURL"=>{"text"=>"2 druids are in Argo as released to searchworks but not in PURL", "druids"=>["bb111dd2222", "cc111dd2222"], "length"=>2}, "Searchworks"=>{"text"=>"Same druids in Argo and Searchworks are released to searchworks"}})
    end
  end

  describe '.collections_summary' do
    it 'outputs collections summary' do
      expect(subject.argo_client).to receive(:collections_druids).at_least(:once).times.and_return(ar)
      expect(subject.purl_client).to receive(:collections_druids).at_least(:once).times.and_return(pf)
      expect(subject.sw_client).to receive(:collections_druids).at_least(:once).times.and_return(sw)
      expect(subject.collections_summary()).to include('Collections Statistics')
      expect(subject.collections_summary()).to include('Argo has 4 released to searchworks')
      expect(subject.collections_summary()).to include('PURL has 4 released to searchworks')
      expect(subject.collections_summary()).to include('Searchworks has 6 released to searchworks')
    end
  end

  describe '.individual_items_summary' do
    it 'outputs individual items summary' do
      expect(subject.argo_client).to receive(:items_druids).at_least(:once).times.and_return(ar)
      expect(subject.purl_client).to receive(:items_druids).at_least(:once).times.and_return(pf)
      expect(subject.sw_client).to receive(:items_druids).at_least(:once).times.and_return(sw)
      expect(subject.individual_items_summary()).to include('Individual Items Statistics')
      expect(subject.individual_items_summary()).to include('Argo has 4 released to searchworks')
      expect(subject.individual_items_summary()).to include('PURL has 4 released to searchworks')
      expect(subject.individual_items_summary()).to include('Searchworks has 6 released to searchworks')
    end
  end

  describe '.individual_collection_summary' do
    it 'outputs error message when collection druid not included for the collection-specific report' do
      expect{subject.individual_collection_summary()}.to raise_error(RuntimeError, "Must provide Environment variable COLL_DRUID with this script")
    end
    it 'outputs individual collection summary' do
      collection_druid = 'aa123bb1212'
      a = Audit.new('argo_url','pf_url', 'sw_url', 'Searchworks', 'Collection-specific Summary', collection_druid)
      expect(a.argo_client).to receive(:collection_members).with(collection_druid).at_least(:once).times.and_return(ar)
      expect(a.purl_client).to receive(:collection_members).with(collection_druid).at_least(:once).times.and_return(pf)
      expect(a.sw_client).to receive(:collection_members).with(collection_druid).at_least(:once).times.and_return(sw)
      expect(a.individual_collection_summary()).to include('Individual Collection Statistics')
      expect(a.individual_collection_summary()).to include('Argo has 4 members in collection aa123bb1212 released to searchworks')
      expect(a.individual_collection_summary()).to include('PURL has 4 members in collection aa123bb1212 released to searchworks')
      expect(a.individual_collection_summary()).to include('Searchworks has 6 members in collection aa123bb1212 released to searchworks')
    end
  end

  describe '.everything_released_summary' do
    it 'outputs everything released summary' do
      expect(subject.argo_client).to receive(:all_druids).at_least(:once).times.and_return(ar)
      expect(subject.purl_client).to receive(:all_druids).at_least(:once).times.and_return(pf)
      expect(subject.sw_client).to receive(:all_druids).at_least(:once).times.and_return(sw)
      expect(subject.everything_released_summary()).to include('Everything Statistics')
      expect(subject.everything_released_summary()).to include('Argo has 4 released to searchworks')
      expect(subject.everything_released_summary()).to include('PURL has 4 released to searchworks')
      expect(subject.everything_released_summary()).to include('Searchworks has 6 released to searchworks')
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
