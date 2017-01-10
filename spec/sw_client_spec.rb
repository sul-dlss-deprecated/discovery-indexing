require 'spec_helper'
require 'sw_client'
require 'json'

describe SwClient do
  subject { described_class.new(ENV['SW_URL']) }

  before do
    ENV['SW_URL']   = "sw_url"
  end

  describe '.results' do
    it 'executes the required query at the appropriate url and returns body' do
      data = ['abc']
      http_resp = double(body: data.to_json)

      uri = URI.parse('sw_url_search')
      expect(Net::HTTP).to receive(:get_response).with(uri).and_return(http_resp)
      resulting_json = subject.results('sw_url_search')
      expect(resulting_json).to eq(data.to_json)
    end
  end

  describe '.coll_search' do
    it 'return query with the collection druid' do
      qu = subject.coll_search('aa111bb2222')
      expect(qu).to eq("/select?&fq=collection:aa111bb2222&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls%2Ccollection&wt=json")
    end
  end

  describe '.json_parsed_resp' do
    it 'returns JSON parsed results' do
      inp = File.open('spec/fixtures/sw_coll_response.json').read
      query = "/select?&fq=collection_type%3A%22Digital+Collection%22&q=*%3A*&rows=10000000&fl=id%2Cmanaged_purl_urls%2Ccollection&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      res = subject.json_parsed_resp(url,query)
      expect(res).to eq(JSON.parse(inp))
    end
  end

  describe '.parse_collection_json_results' do
    it 'returns collection druids from results' do
      inp = File.open('spec/fixtures/sw_small_coll_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_collection_json_results(resp)
      expect(res).to eq(["kg359sw2755","yw836rh9143","sk373nx0013","bq589tv8583","ht743nc5892","yk804rq1656","pn702xq6169","rk213cd8889","jm666mf5828","qm881mj2847","ts561xq4138","dw691pc6656","jv604mg1460","cq727dp8228","hw369qx4338","rp446yr5148","mp370pd0212","rk187hn0556","sf766bw2868","hd720nf9829","vs289js9341","sk882gx0113","tw636vv0781","yd446sf7091","ks148hv4120","zf690qk3036","tx989ks1563","dz810wk7025","qp117dw5290","vp586fq6414","nj499gt7307","dn166mg9206"])
    end
    it 'ignores druids from catkeys with multiple managed purls' do
      inp = File.open('spec/fixtures/sw_multi_managed_purls_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_collection_json_results(resp)
      expect(res).to eq(["vg037xw7470", "sj775xm6965", "vw731wp9266", "fn641cv9781", "qx743vc2234"])
      expect(res).to_not include(["nj770kg7809","sv729sr9437"])
    end
  end

  describe '.parse_item_json_results' do
    it 'returns collection druids from results' do
      inp = File.open('spec/fixtures/sw_small_ckey_items_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_item_json_results(resp)
      expect(res).to eq(["nm509pb1354", "xh181yf7437", "wb611cw7159", "db821pz5857", "xg404ym0968"])
    end
    it 'ignores druids from catkeys with multiple managed purls' do
      inp = File.open('spec/fixtures/sw_small_ckey_items_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_item_json_results(resp)
      expect(res).to eq(["nm509pb1354", "xh181yf7437", "wb611cw7159", "db821pz5857", "xg404ym0968"])
      expect(res).to_not include(["ck660gy9032","sy092jw9534"])
    end
  end

  describe '.druid_from_managed_purl' do
    it 'returns druids from managed purls' do
      man_purl = "http://purl.stanford.edu/nj770kg7809"
      druid = subject.druid_from_managed_purl(man_purl)
      expect(druid).to eq('nj770kg7809')
    end
  end

  describe '.collections_druids' do
    it 'returns collections druids list sorted and unique' do
      inp = File.open('spec/fixtures/sw_small_coll_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      druids = subject.collections_druids
      expect(druids).to eq(["bq589tv8583","cq727dp8228","dn166mg9206","dw691pc6656","dz810wk7025","hd720nf9829","ht743nc5892","hw369qx4338","jm666mf5828","jv604mg1460","kg359sw2755","ks148hv4120","mp370pd0212","nj499gt7307","pn702xq6169","qm881mj2847","qp117dw5290","rk187hn0556","rk213cd8889","rp446yr5148","sf766bw2868","sk373nx0013","sk882gx0113","ts561xq4138","tw636vv0781","tx989ks1563","vp586fq6414","vs289js9341","yd446sf7091","yk804rq1656","yw836rh9143","zf690qk3036"])
    end
  end

  describe '.items_druids' do
    it 'returns items druids list sorted and unique' do
      inp = File.open('spec/fixtures/sw_items_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).exactly(2).times.and_return(inp)
      item_ids = subject.items_druids
      expect(item_ids).to eq(["bx638ry0293","cr615zw9252","cy960by6578","gp350rv3034","kd948pq9705","kp672yb7178","ky399mf8286","nm509pb1354","pt261jk2268","qc157wd6464","rf436ph3918","ry437tc7883","sn179yg3680","sz154cs6300","vv853br8653","wg878pw9299","wn605tx2844","zs376sn5901","zx822vw3110"])
    end
  end

  describe '.collection_members' do
    describe 'returns items druids with associated collection from results' do
      it 'handles collection with druid as id' do
        inp = File.open('spec/fixtures/sw_coll_druid_response.json').read
        expect(subject).to receive(:json_parsed_resp).and_return(JSON.parse(inp))
        res = subject.collection_members('xh235dd9059')
        expect(res).to eq(["cf454mq2224","gk001qy4753","hb289kr4561","hd767tx4719","hj478tq6253","hv987gp1617","nn623wk9886","ny211ss2656","ny528hk9346","pm663mm6911","px661wq0585","qp882sn7738","qv012tw8453","sk619xk3864","sq270nd5698","wd288qt8013","wd704gq2996","xm515kv6393","zd198qs9343","zk839tp9693"])
      end
      it 'handles collection with ckey as id' do
        inp = File.open('spec/fixtures/sw_coll_ckey_response.json').read
        expect(subject).to receive(:json_parsed_resp).and_return(JSON.parse(inp))
        res = subject.collection_members('9615156')
        expect(res).to eq(["jf275fd6276", "nz353cp1092", "tc552kq0798", "th998nk0722", "ww689vs6534"])
      end
    end
  end

  describe '.ckey_from_druid' do
    it 'returns catkey from a druid from results' do
      expect(subject).to receive(:results).with(/managed_purl_urls/).and_return("123456\n")
      ckey = subject.ckey_from_druid('aa111bb2222')
      expect(ckey).to eq('123456')
    end
  end

  describe '.druid_from_ckey' do
    it 'returns druid from a catkey from results' do
      expect(subject).to receive(:results).with(/managed_purl_urls/).and_return("http://purl.stanford.edu/nj770kg7809\n")
      druid = subject.druid_from_ckey('123456')
      expect(druid).to eq('nj770kg7809')
    end
  end

  after do
    File.delete('multiple_managed_purls.txt') if File.file?('multiple_managed_purls.txt')
  end

end
