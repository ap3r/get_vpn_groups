#!/bin/bash

#set the query.
query="Cisco AWARE 2.0"
query_nospace=$(echo $query | sed 's/ /_/g')

#query shodan for $query to set our limit, otherwise we top out at 1k results
limit=$(shodan count $query)
echo [*] limit is $limit for $query

#download the results into a .gz
echo [*] downloading $limit results for $query
shodan download --limit $limit $query_nospace $query

#dump IP:PORT, sed in https:// and the /+CSCOE+/logon.html path
echo [*] parsing results....
shodan parse --fields ip_str,port --separator , $query_nospace.json.gz  | sed 's/^/https:\/\//' | sed 's/,/:/' | sed 's/,/\/+CSCOE+\/logon.html/' > $query_nospace.txt

#curl (with a little help from xargs) and save the html into one flat file
echo [*] full throttle curl-ing across 8 threads
cat $query_nospace.txt | xargs -P 8 -I {} curl -ks '{}' >> out.html

#carve out the groupnames 
#might be hiding in different locations depending on config / version, need to do more spot-checking
cat out.html | grep -i "option value" | cut -d '"' -f 2 | sort -u > groupnames_shodan.txt

echo [*] done!
