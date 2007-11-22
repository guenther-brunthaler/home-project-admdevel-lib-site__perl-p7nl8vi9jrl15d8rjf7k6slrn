# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::PackPUI_0EEED08C_DA7D_11D5_98D3_0050BACC8FE1;


# Packs a list of arbitrarily-sized binary strings (or undef's)
# into a single string.
sub PackStrings {
   join '', map {
      defined() ? Lib::PackPUI(1 + length $_) . $_ : Lib::PackPUI 0;
   } @_;
}


1;
