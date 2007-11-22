# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


require 5.008;
use strict;


package FmtGerman_B9873B70_9FD4_11D9_BFF3_00A0C9EF1631;
use LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;
import_from_short_name_alias_instead;


# Simple string/numeric formatting support
# specifically tailored for the German language.


package Lib::FmtGerman;


use Exporter qw(import);
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 11 $';
our @EXPORT_OK= qw(fmt1e3);


# Reformat numeric string using '.' thousands separators.
sub fmt1e3($) {
   return join '.', split /(?= (?: .{3} )+ $ ) /x, shift;
}


1;
