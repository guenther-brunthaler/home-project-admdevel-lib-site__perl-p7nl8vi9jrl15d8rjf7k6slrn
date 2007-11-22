# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


require 5.008;
use strict;


package NumUtil_7CBEAE20_9F18_11D9_BFF3_00A0C9EF1631;
use LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;
import_from_short_name_alias_instead;


# Several simple numeric utility functions.


package Lib::NumUtil;


use Exporter qw(import);
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 11 $';
our @EXPORT_OK= qw(diff);


# Return the difference between both numeric argument values.
# That difference is the absolute value of value 1 minus value 2.
sub diff($$) {
   return $_[0] <= $_[1] ? $_[1] - $_[0] : $_[0] - $_[1];
}


1;
