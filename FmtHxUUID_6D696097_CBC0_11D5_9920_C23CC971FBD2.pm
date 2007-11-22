# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Carp;


# Convert a 32-character hex UUID into 'Registry' format.
# Any lower case hex characters will be converted to upper case.
sub FmtHxUUID {
   my $uuid= shift;
   $uuid =~ s/(.{8})(.{4})(.{4})(.{4})(.{12})/\{\U$1-$2-$3-$4-$5}/
   or croak "Invalid UUID format: '$uuid'"
   ;
   $uuid;
}


1;
