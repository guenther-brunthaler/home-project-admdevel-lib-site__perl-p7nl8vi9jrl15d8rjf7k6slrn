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
use Lib::RNeedIndices_24E3ACB0_117D_11D6_98F4_0050BACC8FE1;


# Returns a decoded binary reversed PUI starting at string <s> index <i> - 1.
# Advances <i> to the beginning (first byte in ascending order) of the PUI.
# Arguments: <s>, <i>.
sub RGetPUI {
   my $v;
   Lib::RNeedIndices $_[1], 1;
   $v= unpack 'C', substr $_[0], --$_[1], 1;
   return $v if $v < 0x80;
   $v^= 0xff;
   my $c;
   {
      Lib::RNeedIndices $_[1], 1;
      croak "RPUI: overflow" if $v > 0xffffffff >> 7;
      $c= unpack 'C', substr $_[0], --$_[1], 1;
      last if $c < 0x80;
      $v= $v << 7 | ($c ^ 0xff);
      redo;
   }
   $v << 7 | $c;
}


1;
