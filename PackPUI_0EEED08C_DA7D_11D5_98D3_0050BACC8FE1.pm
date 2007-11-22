# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


# Packs the provided unsigned integer into a Portable Unsigned Integer,
# which is a variable-sized and platform-independent encoding.
# If a second argument is provided, the PUI will be generated in such a
# way that it has the same length as if the second integer argument would
# have been written instead (assuming the second number is larger).
# This allows to write a PUI that can be replaced by a larger number later.
sub PackPUI {
   my($ui, $max)= @_;
   my($min, @oc);
   if (defined $max) {
      # Determine minimum number of octets to emit.
      for ($min= 1; $max > 0x7f; ++$min) {
         $max>>= 7;
      }
   }
   else {$min= 1}
   unshift @oc, $ui & 0x7f; # least significant octet
   # more significant octets
   unshift @oc, $ui & 0x7f ^ 0xff while ($ui>>= 7) != 0 | --$min > 0;
   pack 'C*', @oc;
}


1;
