require "./audit.rb"
argo_url="https://sul-solr.stanford.edu/solr/argo3_prod"
pf_url="https://purl-fetcher-prod.stanford.edu"
sw_url="http://searchworks-solr-lb:8983/solr/current"
sw_tgt="searchworks"
rpt_type="Collection Summary"

a=Audit.new(argo_url, pf_url, sw_url, sw_tgt, rpt_type)
a.rpt_select()
