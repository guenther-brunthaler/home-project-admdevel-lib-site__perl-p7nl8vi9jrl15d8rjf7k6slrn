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
use Lib::Armor_F467BD40_CBA4_11D5_9920_C23CC971FBD2;
use Lib::PackStrings_0EEED083_DA7D_11D5_98D3_0050BACC8FE1;


# Primitive account information (list of strings) encoder.
# This is not really encryption; it's just for the eye.
sub AcctEncode {
   my($salt, $a4);
   ($a4= new Lib::ArcFourVariant)->randomize;
   $a4->set_key('SQL-ODBC', $salt= $a4->create_salt(16));
   Lib::Armor($a4->crypt(Lib::PackStrings(@_)) . $salt);
}


1;
