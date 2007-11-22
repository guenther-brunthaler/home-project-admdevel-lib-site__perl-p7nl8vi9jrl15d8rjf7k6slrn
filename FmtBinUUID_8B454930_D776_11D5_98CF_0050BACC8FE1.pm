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
use Lib::FmtHxUUID_6D696097_CBC0_11D5_9920_C23CC971FBD2;


# Convert a 32-character hex UUID into 'Registry' format.
# Any lower case hex characters will be converted to upper case.
sub FmtBinUUID {
   FmtHxUUID unpack 'H*', shift;
}


1;
