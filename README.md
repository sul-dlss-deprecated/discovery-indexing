# Discovery Indexing Audit Script

## How to run the script:

### Minimum required inputs:

1. ARGO_URL - URL to Argo Solr index, eg. http://solr.stanford.edu/solr/prod
2. SW_URL - URL to Searchworks Solr index, eg. http://solr.stanford.edu/solr/sw_prod
3. PF_URL - URL to purl-fetcher deployment, eg. http://purl-fetcher.stanford.edu
4. SW_TGT - Searchworks target, eg. searchworks-stage

**Note: All URLs should not include a terminating slash**

### Optional inputs:

1. RPT_TYPE - Which report to run - if none provided, Collections Summary is run as the default
   * _Everything Released Summary_ - Summary of all collections and items released to the specified Searchworks target
   * _Collections Summary_ - Summary of all collections released to the specified Searchworks target
   * _Collection-specific Summary_ - Summary of a specific collection released to the specified Searchworks target
   * _Individual Items Summary_ - Not implemented yet, but will be a summary of all items released to Searchworks target not as part of a collection
2. COLL_DRUID - Collection druid without the druid prefix - required for running reports on a specific collection, e.g. aa111bb2222

### Examples to run from the command line:

1. A specific collection summary report:
`ARGO_URL="http://solr.stanford.edu/solr/prod" SW_URL="http://solr.stanford.edu/solr/sw_prod" PF_URL="http://purl-fetcher.stanford.edu" SW_TGT="searchworks-stage" RPT_TYPE="Collection-specific Summary" COLL_DRUID="aa111bb2222" ruby audit.rb`

2. The collections summary report:
`ARGO_URL="http://solr.stanford.edu/solr/prod" SW_URL="http://solr.stanford.edu/solr/sw_prod" PF_URL="http://purl-fetcher.stanford.edu" SW_TGT="searchworks-stage" ruby audit.rb`

3. The everything released summary report:
`ARGO_URL="http://solr.stanford.edu/solr/prod" SW_URL="http://solr.stanford.edu/solr/sw_prod" PF_URL="http://purl-fetcher.stanford.edu" SW_TGT="searchworks-stage" RPT_TYPE="Everything Released Summary" ruby audit.rb`
