package Cpanel::CustomEventHandler;

# cpanel12 - CustomEventHandler.pm Copyright(c) 2008 cPanel, Inc.
# All rights Reserved.
# copyright@cpanel.net http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

# THIS IS NOT MY CODE, I WILL NOT SUPPORT IT. IT COULD BREAK AT ANYTIME.
# Original code: http://forums.cpanel.net/f43/block-forwarding-111609.html#post509561
# This was modified by myself and a member of cPanel's support team who was feeling generous at the time. 

# Instructions:
# 1) Add this file to an existing or new file, /usr/local/cpanel/Cpanel/CustomEventHandler.pm
# 2) Customize error message ("Forwarders to $domain are not permitted")
# 2) Create a new file /etc/forwarder_blocked_domains.txt and add blocked domains, one per line (gmail.com,yahoo.com, etc..)
# Enjoy

use strict;
use Cpanel::Logger ();

# apiv = apiversion
# type = pre,post
# module = Cpanel::<modname>
# event = the event ie addpop
# cfg ref is a hash of the conf variables passed to the event. If its a legacy event, the hash keys are numbered, newer events have names.
# dataref = the data returned from the event (post events only)
sub event {
my ( $apiv, $type, $module, $event, $cfgref, $dataref ) = @_; 
my $return = 1;
if ( ($module eq 'email') && ($event eq 'addforward') ) { 
my($localpart, $domain) = split(/@/, $cfgref->{'fwdemail'});
if (-f "/etc/forwarder_blocked_domains.txt") {
open(BLOCK, "</etc/forwarder_blocked_domains.txt");
while (<BLOCK>) { 
chomp($_); 
if ($_ eq $domain) {
$Cpanel::CPERROR{$Cpanel::context} = "Forwarders to $domain are not permitted"; $return = 0;
} 
} 
close(BLOCK);
} 
} 
return $return;
} 

1;
