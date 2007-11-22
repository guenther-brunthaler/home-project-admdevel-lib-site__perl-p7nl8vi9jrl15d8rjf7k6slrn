# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib;


use Carp;


# Convert UUID text format into platform-independent binary format.
sub UUID2Bin {
   my($ruuid)= @_;
   my $w= '[\dA-F]{4}';
   $ruuid =~ s/^{($w$w)([-_]?)($w)\2($w)\2($w)\2($w$w$w)}$/$1$3$4$5$6/o
   or $ruuid =~ s/^($w$w)([-_]?)($w)\2($w)\2($w)\2($w$w$w)$/$1$3$4$5$6/o
   or croak "Invalid UUID format '$ruuid'";
   ;
   pack 'H*', $ruuid;
}


1;
