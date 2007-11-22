# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::ArcFourVariant_A519F072_D9E1_11D5_98D2_0050BACC8FE1;
use Lib::Unarmor_0EEED080_DA7D_11D5_98D3_0050BACC8FE1;
use Lib::UnpackStrings_0EEED084_DA7D_11D5_98D3_0050BACC8FE1;


# Primitive account information (list of strings) decoder.
# This is not really encryption; it's just for the eye.
sub AcctDecode {
   my($s, $a4);
   $s= Lib::Unarmor(shift);
   ($a4= new Lib::ArcFourVariant)->set_key('SQL-ODBC', substr $s, -2);
   Lib::UnpackStrings($a4->crypt(substr $s, 0, length($s) - 2));
}


1;
