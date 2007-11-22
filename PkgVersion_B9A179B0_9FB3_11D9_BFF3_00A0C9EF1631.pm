# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


require 5.008;
use strict;


package PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;
use LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;
import_from_short_name_alias_instead;


# Extract a string suitable for assignment to 'our $VERSION' from the
# typical version information string provided by popular version control
# systems.
#
# Typical usage pattern:
#
#    package Lib::MyModule;
#
#
#    use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;
#    # Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
#    our $VERSION= extract_VERSION_from '$Revision: 2673 $';
#
# The above lines illustrate how the functionality from this module
# should be used for assigning the $VERSION variable of a package.


package Lib::PkgVersion;


use Exporter qw(import);
sub extract_VERSION_from($);


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 2673 $';
our @EXPORT= qw(extract_VERSION_from);


# Requires some version string as input, such as provided by CVS, RCS or SVN.
# Extract the first substring matching / ( \d+ (?: \. \d{1,3} )* ) /x
# and convert it into a string representing a floating point number
# suitable for version comparison as performed by 'use'/'require'.
# The extracted version string part of the input string will consist of
# one or more decimal digit groups separated from each other by a dot (".").
# The leading digit group will be taken as the integral part of the floating
# point number, any remaining digit groups will be padded to 3 digits
# and added as 3 additional fractional digits at the end of the floating
# point number.
# E. g. "4" => "4", "5.6" => "5.006", "7.8.9" => "7.008009".
sub extract_VERSION_from($) {
   my $v= shift;
   unless ($v =~ / ( \d+ (?: \. \d{1,3} )* ) /x) {
      die "cannot convert '$v' into \$VERSION-number";
   }
   my @v= split /\./, $1;
   $v= shift @v;
   return $v . (@v ? '.' : '') . join '', map sprintf('%03u', $_), @v;
}


1;
