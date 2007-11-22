# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::NeedIndices_0EEED088_DA7D_11D5_98D3_0050BACC8FE1;


# Returns <n> octets from string <s> starting at index <i>.
# Advances <i> to after the end of the octet sequence.
# Arguments: <s>, <i>, <n>.
sub GetOctets {
   Lib::NeedIndices @_;
   my $i= $_[1];
   $_[1]+= $_[2];
   substr $_[0], $i, $_[2];
}


1;
