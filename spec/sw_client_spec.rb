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

  describe '.parse_collection_druids' do
    it 'returns druids and ckeys from results' do
      inp = File.open('spec/fixtures/sw_small_coll_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_collection_druids(resp)
      expect(res).to eq([{:ckey=>"10627425", :druid=>"kg359sw2755"},
                         {:druid=>"yw836rh9143", :ckey=>""},
                         {:druid=>"sk373nx0013", :ckey=>""},
                         {:ckey=>"11235662", :druid=>"bq589tv8583"},
                         {:ckey=>"8378781", :druid=>"ht743nc5892"},
                         {:ckey=>"10157407", :druid=>"yk804rq1656"},
                         {:ckey=>"6369086", :druid=>"pn702xq6169"},
                         {:ckey=>"9948063", :druid=>"rk213cd8889"},
                         {:ckey=>"10154326", :druid=>"jm666mf5828"},
                         {:ckey=>"9702789", :druid=>"qm881mj2847"},
                         {:ckey=>"8484425", :druid=>"ts561xq4138"},
                         {:ckey=>"4086042", :druid=>"dw691pc6656"},
                         {:ckey=>"8506155", :druid=>"jv604mg1460"},
                         {:ckey=>"4085899", :druid=>"cq727dp8228"},
                         {:ckey=>"156613", :druid=>"hw369qx4338"},
                         {:ckey=>"4086058", :druid=>"rp446yr5148"},
                         {:ckey=>"9695522", :druid=>"mp370pd0212"},
                         {:ckey=>"6000889", :druid=>"rk187hn0556"},
                         {:ckey=>"5990462", :druid=>"sf766bw2868"},
                         {:ckey=>"9704519", :druid=>"hd720nf9829"},
                         {:ckey=>"8596746", :druid=>"vs289js9341"},
                         {:ckey=>"9685083", :druid=>"sk882gx0113"},
                         {:ckey=>"9163904", :druid=>"tw636vv0781"},
                         {:ckey=>"4085772", :druid=>"yd446sf7091"},
                         {:ckey=>"6302717", :druid=>"ks148hv4120"},
                         {:ckey=>"9153925", :druid=>"zf690qk3036"},
                         {:ckey=>"4085449", :druid=>"tx989ks1563"},
                         {:ckey=>"5175653", :druid=>"dz810wk7025"},
                         {:ckey=>"9197425", :druid=>"qp117dw5290"},
                         {:ckey=>"4085894", :druid=>"vp586fq6414"},
                         {:ckey=>"8828014", :druid=>"nj499gt7307"},
                         {:ckey=>"6757885", :druid=>"dn166mg9206"}])
    end
    it 'ignores druids from catkeys with multiple managed purls' do
      inp = File.open('spec/fixtures/sw_multi_managed_purls_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_collection_druids(resp)
      expect(res).to eq([{:ckey=>"9665836", :druid=>""},
                         {:ckey=>"6745997", :druid=>"vg037xw7470"},
                         {:ckey=>"9499725", :druid=>"sj775xm6965"},
                         {:ckey=>"6742418", :druid=>"vw731wp9266"},
                         {:druid=>"fn641cv9781", :ckey=>""},
                         {:druid=>"qx743vc2234", :ckey=>""}])
      expect(res).to_not include([{:ckey=>"9665836", :druid=>"nj770kg7809"},
                                  {:ckey=>"9665836", :druid=>"sv729sr9437"}])
    end
  end

  describe '.parse_item_druids_no_collection' do
    it 'returns collection druids from results' do
      inp = File.open('spec/fixtures/sw_small_ckey_items_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_item_druids_no_collection(resp)
      expect(res).to eq(["nm509pb1354", "xh181yf7437", "wb611cw7159", "db821pz5857", "xg404ym0968"])
    end
    it 'ignores druids from catkeys with multiple managed purls' do
      inp = File.open('spec/fixtures/sw_small_ckey_items_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      resp = subject.json_parsed_resp(url,query)
      res = subject.parse_item_druids_no_collection(resp)
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

  describe '.collections_ids' do
    it 'returns collections ids hash with druids and ckeys' do
      inp = File.open('spec/fixtures/sw_small_coll_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).and_return(inp)
      ids = subject.collections_ids
      expect(ids).to eq([{:ckey=>"10627425", :druid=>"kg359sw2755"},
                         {:druid=>"yw836rh9143", :ckey=>""},
                         {:druid=>"sk373nx0013", :ckey=>""},
                         {:ckey=>"11235662", :druid=>"bq589tv8583"},
                         {:ckey=>"8378781", :druid=>"ht743nc5892"},
                         {:ckey=>"10157407", :druid=>"yk804rq1656"},
                         {:ckey=>"6369086", :druid=>"pn702xq6169"},
                         {:ckey=>"9948063", :druid=>"rk213cd8889"},
                         {:ckey=>"10154326", :druid=>"jm666mf5828"},
                         {:ckey=>"9702789", :druid=>"qm881mj2847"},
                         {:ckey=>"8484425", :druid=>"ts561xq4138"},
                         {:ckey=>"4086042", :druid=>"dw691pc6656"},
                         {:ckey=>"8506155", :druid=>"jv604mg1460"},
                         {:ckey=>"4085899", :druid=>"cq727dp8228"},
                         {:ckey=>"156613", :druid=>"hw369qx4338"},
                         {:ckey=>"4086058", :druid=>"rp446yr5148"},
                         {:ckey=>"9695522", :druid=>"mp370pd0212"},
                         {:ckey=>"6000889", :druid=>"rk187hn0556"},
                         {:ckey=>"5990462", :druid=>"sf766bw2868"},
                         {:ckey=>"9704519", :druid=>"hd720nf9829"},
                         {:ckey=>"8596746", :druid=>"vs289js9341"},
                         {:ckey=>"9685083", :druid=>"sk882gx0113"},
                         {:ckey=>"9163904", :druid=>"tw636vv0781"},
                         {:ckey=>"4085772", :druid=>"yd446sf7091"},
                         {:ckey=>"6302717", :druid=>"ks148hv4120"},
                         {:ckey=>"9153925", :druid=>"zf690qk3036"},
                         {:ckey=>"4085449", :druid=>"tx989ks1563"},
                         {:ckey=>"5175653", :druid=>"dz810wk7025"},
                         {:ckey=>"9197425", :druid=>"qp117dw5290"},
                         {:ckey=>"4085894", :druid=>"vp586fq6414"},
                         {:ckey=>"8828014", :druid=>"nj499gt7307"},
                         {:ckey=>"6757885", :druid=>"dn166mg9206"}])
    end
  end

  describe '.items_druids_no_collection' do
    it 'returns items druids list sorted and unique' do
      inp = File.open('spec/fixtures/sw_items_response.json').read
      query = "/select?stuff&wt=json"
      url = "http://www.example.com"
      expect(subject).to receive(:results).exactly(2).times.and_return(inp)
      item_ids = subject.items_druids_no_collection
      expect(item_ids).to eq(["bx638ry0293","cr615zw9252","cy960by6578","gp350rv3034","kd948pq9705","kp672yb7178","ky399mf8286","nm509pb1354","pt261jk2268","qc157wd6464","rf436ph3918","ry437tc7883","sn179yg3680","sz154cs6300","vv853br8653","wg878pw9299","wn605tx2844","zs376sn5901","zx822vw3110"])
    end
  end

  describe '.collection_members' do
    describe 'returns items druids with associated collection from results' do
      it 'handles collection with druid as id' do
        inp = File.open('spec/fixtures/sw_coll_druid_response.json').read
        expect(subject).to receive(:json_parsed_resp).at_least(:once).times.and_return(JSON.parse(inp))
        res = subject.collection_members('xh235dd9059')
        expect(res).to eq([{:druid=>"qv012tw8453", :ckey=>""},
                           {:ckey=>"11403482", :druid=>"hv987gp1617"},
                           {:ckey=>"11403475", :druid=>"zd198qs9343"},
                           {:ckey=>"11523796", :druid=>"sq270nd5698"},
                           {:ckey=>"10452676", :druid=>"nn623wk9886"},
                           {:ckey=>"11403480", :druid=>"hd767tx4719"},
                           {:ckey=>"10448280", :druid=>"zk839tp9693"},
                           {:ckey=>"10450355", :druid=>"pm663mm6911"},
                           {:ckey=>"10452012", :druid=>"hj478tq6253"},
                           {:ckey=>"10452681", :druid=>"cf454mq2224"},
                           {:ckey=>"10452011", :druid=>"ny211ss2656"},
                           {:ckey=>"10453596", :druid=>"px661wq0585"},
                           {:ckey=>"10452654", :druid=>"wd288qt8013"},
                           {:ckey=>"10453509", :druid=>"ny528hk9346"},
                           {:ckey=>"10450224", :druid=>"qp882sn7738"},
                           {:druid=>"sk619xk3864", :ckey=>""},
                           {:ckey=>"10449006", :druid=>"hb289kr4561"},
                           {:druid=>"xm515kv6393", :ckey=>""},
                           {:ckey=>"10451210", :druid=>"wd704gq2996"},
                           {:ckey=>"10451356", :druid=>"gk001qy4753"}])
      end
      it 'handles collection with ckey as id' do
        inp = File.open('spec/fixtures/sw_coll_ckey_response.json').read
        expect(subject).to receive(:json_parsed_resp).at_least(:once).times.and_return(JSON.parse(inp))
        res = subject.collection_members('9615156')
        expect(res).to eq([{:druid=>"nz353cp1092", :ckey=>""},
                           {:druid=>"jf275fd6276", :ckey=>""},
                           {:druid=>"ww689vs6534", :ckey=>""},
                           {:druid=>"th998nk0722", :ckey=>""},
                           {:druid=>"tc552kq0798", :ckey=>""}])
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
