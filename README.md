curl-push
=========

Curl script to push app to Cloud Foundry


### Requirements

This script uses the [jq](http://stedolan.github.io/jq/) json parser,
which must be installed and available on $PATH prior to invoking this
script.

jq is available on all major OS's.


### Usage

* Create a zipfile containing the application directory
* Edit the curl-push.sh script and update the customization section to reflect your environment
* Invoke the script via **./curl-push.sh**
