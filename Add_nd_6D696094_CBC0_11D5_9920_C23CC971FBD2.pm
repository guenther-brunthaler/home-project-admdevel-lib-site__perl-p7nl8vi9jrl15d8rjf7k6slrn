# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


# Add appropriate suffixes to the specified numeric string in order to
# make it '1st', '2nd', '3rd', '4th' and so on.
sub Add_nd {
   my $num= shift;
   my($nd);
   if (defined($nd= ${{qw/1 st 2 nd 3 rd/}}{$num % 10})) {
      undef $nd if int($num % 100 / 10) == 1;
   }
   $nd= 'th' unless defined $nd;
   $num . $nd;
}


1;
