# Discovery Indexing Audit Script

## How to run the script:

### Minimum required inputs:

1. ARGO_URL_DEFAULT - URL to Argo Solr index, eg. http://solr.stanford.edu/solr/prod
2. SW_URL_DEFAULT - URL to Searchworks Solr index, eg. http://solr.stanford.edu/solr/sw_prod
3. PF_URL_DEFAULT - URL to purl-fetcher deployment, eg. http://purl-fetcher.stanford.edu
4. SW_TGT_DEFAULT - Searchworks target, eg. searchworks-stage

**Note: All URLs should not include a terminating slash**

### Optional inputs:

1. RPT_TYPE_DEFAULT - Which report to run - if none provided, Collections Summary is run as the default
   * _Everything Released Summary_ - Summary of all collections and items released to the specified Searchworks target
   * _Collections Summary_ - Summary of all collections released to the specified Searchworks target
   * _Collection-specific Summary_ - Summary of a specific collection released to the specified Searchworks target
   * _Individual Items Summary_ - Not implemented yet, but will be a summary of all items released to Searchworks target not as part of a collection
2. COLL_DRUID_DEFAULT - Collection druid without the druid prefix - required for running reports on a specific collection, e.g. aa111bb2222

In order to run the audit manually, go onto the server to the top-level directory for discovery-indexing and run `./bin/perform_audit`.  If you get a permissions denied message, just `chmod a+x bin/perform_audit`

So, for a collection-specific summary report, at the prompts, you need to use the following for the inputs:
Report Type:        "Collection-specific Summary"
Collection Druid:   Value of the specific collection druid
