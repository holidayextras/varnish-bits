#!/bin/bash
# Script to reload varnish proxy so that it will pick-up new IP address changes

/root/varnish_new_ipaddress.sh
if [ $? -ne 0 ]; then
   date > /tmp/varnish_reload_failed
   exit 1
else
   echo 'Everything OK'
fi

/etc/init.d/varnish reload
if [ $? -ne 0 ]; then
   date > /tmp/varnish_reload_failed
else
   echo 'Everything OK'
fi

vcl_count=$(varnishadm -S /etc/varnish/secret -T 127.0.0.1:6082 vcl.list | grep 'available' | wc -l)
if [ $vcl_count -ge 10 ]; then
   vcl_first=$(varnishadm -S /etc/varnish/secret -T 127.0.0.1:6082 vcl.list | grep 'available' | head -2 | tail -1 | awk '{ print $3 }')
   varnishadm -S /etc/varnish/secret -T 127.0.0.1:6082 vcl.discard $vcl_first
   if [ $? -ne 0 ]; then
      date > /tmp/varnish_vcldiscard_failed
   fi
fi
exit
