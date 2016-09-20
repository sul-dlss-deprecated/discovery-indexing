# get a list of collection druids and catkeys from argo index
# get a list of collection druids and catleys from purl-fetcher API
# get a list of collection druids and catkeys from searchworks index

# compare those lists
#   - make a list of agree'd upon collection druids

# for each collection get druid ids with releases & catkeys from:
#   - argo index
#   - purl-fetcher
#   - searchworks index

# Need to compare catkeys and druids from argo and from sw-prod index
# Argo list is sorted by druid so need to pull catkeys (third column separated by commas) and add those to list with druids without catkeys
curl "https://sul-solr.stanford.edu/solr/argo3_prod/select?&fq=objectType_ssim:%22collection%22&fl=id,released_to_ssim,catkey_id_ssim&rows=10000&sort=id%20asc&wt=csv&csv.header=false" |grep Searchworks | sed 's/druid://g' | awk -F ',' '{ if (length($3) > 0)
	print $3;
else
	print $1; }' | sort > argo_coll_ids

curl "http://sw-solr-m.stanford.edu:8983/solr/current/select?&fq=collection_type:%22Digital%20Collection%22&fl=id&rows=10000&sort=id%20asc&wt=csv&csv.header=false" > sw_coll_ids

ruby parse_purl_JSON.rb > purl_coll_ids

# All lists are sorted so just need to do a diff
# Look for < and > to determine where the differences come from
# if <, that means it is in the first list but not in the second one
# if >, that means it is in the second list and not in the first one
diff argo_coll_ids sw_coll_ids | grep "<" | sed "s/< /Released in Argo but not in Searchworks - /g" > differences_file
diff argo_coll_ids sw_coll_ids | grep ">" | sed "s/> /Released in Searchworks but not in Argo - /g" >> differences_file
diff argo_coll_ids purl_coll_ids | grep "<" | sed "s/< /Released in Argo but not in Purl - /g" >> differences_file
diff argo_coll_ids purl_coll_ids | grep ">" | sed "s/> /Released in Purl but not in Argo - /g" >> differences_file
diff sw_coll_ids purl_coll_ids | grep "<" | sed "s/< /Released in Searchworks but not in Purl - /g" >> differences_file
diff sw_coll_ids purl_coll_ids | grep ">" | sed "s/> /Released in Purl but not in Searchworks - /g" >> differences_file



# Get all Searchworks records that have ids that are druids:
# id:/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/
uri = URI.parse("http://searchworks-solr-lb:8983/solr/current/select?q=*%3A*&fq=id%3A%2F%5Ba-z%5D%7B2%7D%5B0-9%5D%7B3%7D%5Ba-z%5D%7B2%7D%5B0-9%5D%7B4%7D%2F&fl=id&wt=csv&rows=10000000&csv.header=false")
response = Net::HTTP.get_response(uri)
body = response.body.split("\n")


# For each collection, get druid ids, released_to_ssim and catkeys
#curl "https://sul-solr.stanford.edu/solr/argo3_prod/select?&fq=is_member_of_collection_ssim:%22info:fedora/druid:zb871zd0767%22&fl=id,released_to_ssim,catkey_id_ssim&rows=1000&sort=id%20asc&wt=csv&csv.header=false"
#curl "http://sw-solr-m.stanford.edu:8983/solr/current/select?&fq=collection:wk210cf6868&fl=id,druid&rows=1000&sort=id%20asc&wt=csv&csv.header=false"

curl "https://purl-fetcher-prod.stanford.edu/purls"

# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls">zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=2">>zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=3">>zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=4">>zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=5">>zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=6">>zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=7">>zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=8">>zb_purls.druids
# curl "https://purl-fetcher-prod.stanford.edu/collections/druid:zb871zd0767/purls?page=9">>zb_purls.druids
