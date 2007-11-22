# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


require 5.008;
use strict;


# Library helper function for modules using the 'Exporter'-Package.
#
# Allows to use the full UUID-based package name in a use(),
# but actually importing from a stripped version of the package
# name without the UUID.
#
# Example: The following lines
#
#    require 5.008;
#    use strict;
#
#
#    package MyModule_6AB03300_9F52_11D9_BFF3_00A0C9EF1631;
#    use LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;
#    import_from_short_name_alias_instead;
#
#
#    # <Package description>.
#
#
#    package Lib::MyModule;
#
#
#    use Exporter qw(import);
#    use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;
#
#
#    # Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
#    our $VERSION= extract_VERSION_from '$Revision: 2673 $';
#    our @EXPORT_OK= qw(func1 func2 etc);
#
# will actually import from package 'Lib::MyModule' in the same source
# file instead of from the package with the long UUID-based name.
#
# Note: The "Lib::"-prefix has been added only to allow automated
# tools updating the short alias within scripts whenever the
# short-alias in the library module name changes (the UUID part of
# the library module name will always remain the same).


package LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;


use Carp;
use Exporter qw(import);


# Cannot use &Lib::PkgVersion::extract_VERSION_from()
# due to chicken-egg-problem! Must be manually updated.
our $VERSION= '1.000';
our @EXPORT= qw(import_from_short_name_alias_instead);


# Call this function from the top-level (outside of any function)
# within an UUID-based package name matching the file name.
sub import_from_short_name_alias_instead {
   my $short= my $long= caller;
   croak "must be called from within package" unless defined $short;
   $short =~ s/ _ [[:xdigit:]_]{36} $ //x;
   substr($short, 0, 0)= 'Lib::';
   eval
        "package $long;\n"
      . "sub VERSION {\n"
      . "   shift; return ${short}->VERSION(\@_);\n"
      . "}\n"
      . "sub import {\n"
      . "   shift; \@_= ('$short', \@_);\n"
      . "   goto &Exporter::import;\n"
      . "}\n"
   ;
   croak "short package name aliasing failed: $@" if $@;
}


1;
