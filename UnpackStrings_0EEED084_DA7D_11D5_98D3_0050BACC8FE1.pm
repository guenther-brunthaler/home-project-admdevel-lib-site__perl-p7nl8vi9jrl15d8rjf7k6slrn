# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::GetPUI_0EEED08B_DA7D_11D5_98D3_0050BACC8FE1;
use Lib::GetOctets_0EEED089_DA7D_11D5_98D3_0050BACC8FE1;


# Unpacks string/undef list from a packed string
# as obtained from Lib::PackStrings().
# Returns an empty list if undef is passed instead of the packed string.
sub UnpackStrings {
   my $s= shift;
   return () unless defined $s;
   my($i, $n, @r);
   for ($i= 0; $i < length $s; ) {
      $n= Lib::GetPUI $s, $i;
      push @r, $n ? Lib::GetOctets $s, $i, $n - 1 : undef;
   }
   @r;
}


1;
