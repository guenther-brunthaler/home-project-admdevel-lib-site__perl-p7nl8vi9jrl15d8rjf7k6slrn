# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Carp;
use Lib::NeedIndices_0EEED088_DA7D_11D5_98D3_0050BACC8FE1;


# Returns a decoded binary PUI starting at string <s> index <i>.
# Advances <i> after the end of the PUI.
# Arguments: <s>, <i>.
sub GetPUI {
   my $v;
   Lib::NeedIndices @_, 1;
   $v= unpack 'C', substr $_[0], $_[1]++, 1;
   return $v if $v < 0x80;
   $v^= 0xff;
   my $c;
   {
      Lib::NeedIndices @_, 1;
      croak "PUI: overflow" if $v > 0xffffffff >> 7;
      $c= unpack 'C', substr $_[0], $_[1]++, 1;
      last if $c < 0x80;
      $v= $v << 7 | ($c ^ 0xff);
      redo;
   }
   $v << 7 | $c;
}


1;
