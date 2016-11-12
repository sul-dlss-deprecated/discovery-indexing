require 'spec_helper'
require 'argo_client'

describe ArgoClient do
  subject { described_class.new(ENV['ARGO_URL'], ENV['SW_TGT']) }

  before do
    ENV['ARGO_URL']   = "argo_url"
    ENV['PF_URL']     = "purl_url"
    ENV['SW_URL']     = "sw_url"
    ENV['COLL_DRUID'] = "coll_druid"
    ENV['RPT_TYPE']   = "Collections Summary"
    ENV['SW_TGT']     = "Searchworks"
  end

  describe '.collections_druids' do
    it 'receives results with object type of collection' do
      expect(subject).to receive(:results).with(/fq=objectType_ssim%3A%22collection%22/)
      subject.collections_druids
    end
    it 'receives results with a value in the released_to_ssim field' do
      expect(subject).to receive(:results).with(/fq=released_to_ssim%3A*/)
      subject.collections_druids
    end
  end

  describe '.items_druids' do
    it 'receives results with object type of item' do
      expect(subject).to receive(:results).with(/fq=objectType_ssim%3A%22item%22/)
      subject.items_druids
    end
    it 'receives results that are not in collections' do
      expect(subject).to receive(:results).with(/fq=-is_member_of_collection_ssim%3A*/)
      subject.items_druids
    end
    it 'receives results with a value in the released_to_ssim field' do
      expect(subject).to receive(:results).with(/fq=released_to_ssim%3A*/)
      subject.items_druids
    end
  end

  describe '.all_druids' do
    it 'receives results with a value in the released_to_ssim field' do
      expect(subject).to receive(:results).with(/fq=released_to_ssim%3A*/)
      subject.all_druids
    end
  end

  describe '.collection_members' do
    it 'receives results for items that are members of the specified collection' do
      expect(subject).to receive(:results).with(/fq=is_member_of_collection_ssim%3A%22info%3Afedora\/druid%3Acoll_druid%22/)
      subject.collection_members("coll_druid")
    end
  end

  describe '.individual_items_released_to_tgt' do
    it 'expects to receive valid parsed json' do

    end
    it 'does not add a druid to the druid list if the indicated solr target is not included in the released_to_ssim field' do

    end
    it 'does not add a druid to the druid list if the indicated processing status is Registered' do

    end
    it 'does not add a druid to the druid list if the indicated rights description includes dark' do

    end
  end

  describe '.results' do
    it 'executes to required query at the appropriate url and returns json' do
      expect(subject).to receive(:individual_items_released_to_tgt).with({}).and_return("")
    end
    it 'parses results and produces valid json hash' do

    end
    it 'calls individual_items_released_to_tgt with valid json hash' do

    end
  end

end
