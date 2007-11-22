# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::RGetOctets_24E3ACB7_117D_11D6_98F4_0050BACC8FE1;


# Returns a binary UUID backwards from string <s> before index <i>.
# Advances <i> to the start of the UUID.
# Arguments: <s>, <i>.
sub RGetBinaryUUID {
   Lib::RGetOctets @_, 16;
}


1;
