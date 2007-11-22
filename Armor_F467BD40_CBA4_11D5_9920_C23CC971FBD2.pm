# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


# Armor a string in Guenther Brunthaler-style radix-64 encoding.
sub Armor {
   my $data= shift;
   my($i, @a);
   $data= unpack 'B*', $data;
   if ($i= length($data) % 6) {
      $data.= '0' x (6 - $i);
   }
   @a= ('#', '*', '0' .. '9', 'A' .. 'Z', 'a' .. 'z');
   join(
      '', map($a[ord pack 'B*', '00' . $_], split(/(?=(?:.{6})+$)/, $data))
   );
}


1;
