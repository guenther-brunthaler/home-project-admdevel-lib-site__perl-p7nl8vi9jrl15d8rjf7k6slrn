# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


require 5.008;
use strict;


package SlurpSingle_C6B08260_9FD3_11D9_BFF3_00A0C9EF1631;
use LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;
import_from_short_name_alias_instead;


# Simple file I/O for files storing single lines of string content only.


package Lib::SlurpSingle;


use Exporter qw(import);
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 11 $';
our @EXPORT_OK= qw(slurp spit);


sub slurp($) {
   my $filename= shift;
   local *IN;
   return undef unless -e $filename;
   open IN, '<', $filename or die "Cannot read '$filename': $!";
   my $result= <IN>;
   close IN or die $!;
   chomp $result;
   die unless $result =~ /\S/;
   return $result;
}


sub spit($$) {
   my($outfile, $value)= @_;
   local *OUT;
   open OUT, '>', $outfile or die "Cannot create '$outfile': $!";
   print OUT "$value\n";
   close OUT or die "Could not finish writing '$outfile': $!";
}


1;
