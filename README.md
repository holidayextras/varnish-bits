varnish-bits
============

Couple of scripts etc we use for varnish


- In order for the scripts to work, your DNS provider needs to send back all available IP addresses and not just round-robin between each IP address one at a time
	E.G "dig +short domain.co.uk" returns..
	# dig +short domain.co.uk
	yourDomain.name.com
	x.x.x.x
	x.x.x.x
	x.x.x.x

- Make sure within your Varnish Config file when configuring backends that you specify the backends in the following way/format

.....
backend backend_name {
    #.host = "domain.co.uk";#
.host = "123.123.123.123";
    .port = "80";        # (and maybe this)
    .probe = {
.....

The important part being these two lines:-
    #.host = "domain.co.uk";#
.host = "123.123.123.123";

the (#.host = "domain.co.uk";#)
line in the varnish config file, must exist directly above the point in the config where your setting the backend IP address (.host = "123.123.123.123";)
Formatting of the line containing the DNS record is also important and needs to look exactly as shown in the example.
