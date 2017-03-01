## Neeed.com clone script

I use [neeed.com](http://neeed.com) to bookmark products online.

I used to use the popular site Svpply for the same purpose, before they shut-down in 2014 following an acquisition by eBay. They permitted users to export their lists [of products], but the feature was lacking. Neeed was quick to permit users to import their Svpply exports, but the process was not perfect and not without data loss.

This script creates csv dumps of a user's lists and downloads the associated images for personal backup.

To Run:

```
ruby neeed_backup.rb $username $password
```