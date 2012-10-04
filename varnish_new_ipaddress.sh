#!/bin/bash
# This is the script which actually does the work. Gets the DNS names, grabs the IP addesses for those DNS names. Creates a new varnish config file, checks the config file compiles OK. Then passes an exit status back to the other script

#Name the Config File we are operating on
varnish_conf_file=/etc/varnish/default.vcl
varnish_conf_file_output=/etc/varnish/default.vcl_out

#Need to be able to see how many lines of each backend DNS name there are, so we can replace each backend with an IP address... Hopefully a different IP for each backend
COUNT=(`grep -E '#\.host\ = "[a-zA-Z.0-9\-]*";#' $varnish_conf_file | cut -d'"' -f2 | sort | uniq -c | awk '{ print $1 }'`)
echo count= ${COUNT[*]}
#Use this as a counter for the above array so as we loop through we can know which hostname we're working on and how many times that DNS backend name exists in the config file and thus how many times we need to run the sed command to change the hostnames
array=0

sed -r '/.host = \"[[:digit:]]{1,3}.[[:digit:]]{1,3}.[[:digit:]]{1,3}.[[:digit:]]{1,3}\";$/d' $varnish_conf_file > $varnish_conf_file_output
sed -ri 's/(#.host = "[a-zA-Z.0-9\-]*";)#/\1/' $varnish_conf_file_output

for host_name in $(grep -E '#\.host\ = "[a-zA-Z.0-9\-]*";' $varnish_conf_file_output | cut -d'"' -f2 | sort | uniq ); do
	unset IP_ADDRESSES
	counter=0
	echo $host_name
	while [ $counter -le 10 ]; do
		for IP_addy in $(dig +short $host_name | sed -e "1d");do
			IP_ADDRESSES[${#IP_ADDRESSES[*]}]=$IP_addy
		done
		((counter++))
	done

	i=0
	until [ $i -ge ${COUNT[$array]} ]; do
		check_ip=$(echo ${IP_ADDRESSES[$i]} | grep -Ec '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}')
		if [ $check_ip -eq 1 ]; then
			echo ${COUNT[$array]} ${IP_ADDRESSES[$i]}
			sed -i "0,/#.host = \"$host_name\";$/s//#.host = \"$host_name\";#\n.host = \"${IP_ADDRESSES[$i]}\";/g" $varnish_conf_file_output
		fi
		((i++))
                echo "i= ${i} count_array=${COUNT[$array]}"
	done
	((array++))
done

#Check that the new config compiles OK?
STATUS=$(varnishd -C -f${varnish_conf_file_output} 2>&1 | head -1)
STATUS_COUNT=$(echo "$STATUS" | grep -c 'Message from VCC-compiler')
if [ $STATUS_COUNT -eq 1 ]; then
	# Error Detected
	exit 1
else
	# No Error Detected
	#IF COUNT_CHECK returns the same numbers as COUNT then we know the format of the file is still valid and hasn't been broken due to DNS failure. Compare as string for string is going to be good enough
	COUNT_CHECK=(`grep -E '#\.host\ = "[a-zA-Z.0-9\-]*";#' $varnish_conf_file_output | cut -d'"' -f2 | sort | uniq -c | awk '{ print $1 }'`)
	if [ "${COUNT[*]}" == "${COUNT_CHECK[*]}" ]; then
		mv -f ${varnish_conf_file_output} ${varnish_conf_file}
		exit 0
	else
		echo "Failed for incorrect check of the counts"
		exit 1
	fi
fi
