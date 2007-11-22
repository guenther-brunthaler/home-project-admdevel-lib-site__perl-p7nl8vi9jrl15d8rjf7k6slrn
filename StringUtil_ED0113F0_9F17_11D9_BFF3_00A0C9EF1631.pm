# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


require 5.008;
use strict;


package StringUtil_ED0113F0_9F17_11D9_BFF3_00A0C9EF1631;
use LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;
import_from_short_name_alias_instead;


# Several simple string utility functions.


package Lib::StringUtil;


use Exporter qw(import);
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 11 $';
our @EXPORT_OK= qw(is_prefix);


# Determine whether the first string argument is a prefix of the second one.
# Returns false if either string is undef.
sub is_prefix($$) {
   my($may_prefix, $may_full)= @_;
   return
      defined($may_full) && defined($may_prefix)
      && length($may_full) >= length($may_prefix)
      && substr($may_full, 0, length($may_prefix)) eq $may_prefix
   ;
}


1;
