# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Win32::API;
use Carp;


# Create one or more new UUIDs.
# Argument: The number of UUIDs to create. Defaults to 1.
# Returns the UUID list in version-independent hex-format.
sub CreateHxUUID {
   my $num= !wantarray && shift || 1;
   my($api, @u, $buf);
   $api= new Win32::API('ole32', 'CoInitialize', ['N'], 'N');
   &croak unless $api;
   &croak if $api->Call(0);
   $api= new Win32::API('ole32', 'CoCreateGuid', ['P'], 'N');
   &croak unless $api;
   $buf= pack 'x16';
   while (--$num >= 0) {
      die if $api->Call($buf);
      push @u, uc unpack 'H*', pack 'NnnC8', unpack 'LSSC8', $buf;
   }
   $api= new Win32::API('ole32', 'CoUninitialize', [], 'V');
   &croak unless $api;
   &croak if $api->Call();
   return @u if wantarray;
   $u[0];
}


1;
