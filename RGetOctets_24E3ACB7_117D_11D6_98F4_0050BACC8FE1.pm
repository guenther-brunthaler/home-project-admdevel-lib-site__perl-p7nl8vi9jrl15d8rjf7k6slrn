# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::RNeedIndices_24E3ACB0_117D_11D6_98F4_0050BACC8FE1;


# Returns <n> octets backwards from string <s> starting before index <i>.
# Advances <i> to the start of the octet sequence to be returned.
# Arguments: <s>, <i>, <n>.
sub RGetOctets {
   Lib::RNeedIndices @_[1, 2];
   substr $_[0], $_[1]-= $_[2], $_[2];
}


1;
