# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


# Gets a binary 64 bit date/time stamp.
sub GetUTC64Timestamp {
   my($sec, $min, $hour, $mday, $mon, $year)= gmtime;
   pack(
      'H*',
      sprintf(
         '%04u' . ('%02u' x 6), $year + 1900, $mon + 1, $mday, $hour, $min, $sec
      )
   );
}


1;
