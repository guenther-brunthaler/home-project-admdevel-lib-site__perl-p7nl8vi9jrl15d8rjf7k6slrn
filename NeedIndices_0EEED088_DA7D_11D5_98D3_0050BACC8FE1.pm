# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib;


use Carp;


# Verfies that it is possible to get <n> octets from string <s> at index <i>.
# Arguments: <s>, <i>, <n>.
sub NeedIndices {
   if ($_[1] + $_[2] > length($_[0])) {
      croak "Premature end of input buffer encountered";
   }
}


1;
