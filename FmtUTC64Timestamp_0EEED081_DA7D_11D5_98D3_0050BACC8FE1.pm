# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::Unarmor_0EEED080_DA7D_11D5_98D3_0050BACC8FE1;


# In scalar context, returns a formatted string representation of the
# decoded Radix-64 ASCII armored UTC date/time stamp.
# In list context, returns an UTC date/time array
#  0      1       2     3      4        5
# ($year, $month, $day, $hour, $minute, $second)
# where $year is a full 4-digit year and $month is 1 to 12.
sub FmtUTC64Timestamp {
   unless (wantarray) {
      return sprintf "%04u-%02u-%02u %02u:%02u:%02u UTC", FmtUTC64Timestamp(@_);
   }
   my @r= split /(?=(?:.{2})+$)/, unpack 'H*', Unarmor @_;
   unshift @r, join '', splice @r, 0, 2;
   @r;
}


1;
