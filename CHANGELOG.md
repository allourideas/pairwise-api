 * Alter response for all_object_info_totals_by_date to be valid XML.

## Pairwise 3.2.0 (Mar 31, 2014) ##
 * Save CSV exports to a database table instead of redis.

## Pairwise 3.1.0 (Mar 20, 2014) ##
 * handle votes or skips that happen after an expired session
 * don't allow votes / skips on appearances if their session ids don't match

## Pairwise 3.0.3 (Feb 07, 2014) ##
 * use ActiveRecord quoting for table, column names
 * add appearance id to votes and nonvote csv
 * update cache hit/miss counters to use utc
 * optimize objects_by_session_id
 * disable catchup on surveys with more than 999 active choices

## Pairwise 3.0.2 (Jun 11, 2013) ##
 * Optimize voting API call
 * Upgrade to Rails 2.3.16
 * Add site_stats call to API
 * Fix bug in response user_generated_ideas totals over time, where the min and max dates were getting added as strings instead of date objects
 * Update choices to act_as_versioned

## Pairwise 3.0.1 (Apr 16, 2012) ###

 * Added votes_per_uploaded_choice call to API
 * Added median_responses_per_session call to API
 * Added upload_to_participation_rate call to API
 * Added vote_rate call to API

## Pairwise 3.0.0 (Feb 10, 2012) ###

 * Upgrade to Rails 2.3.14
 * Switch to using bundler for gem management
