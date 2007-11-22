# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


# Makes $thing the correct singular or plural depending on $num.
# Options:
# -none => <text>: Display <text> instead of zero.
# -some => <text>: Prefix $num by <text> if not zero.
# -plural => <text>: Use <text> instead of $thing . "s" if $num != 1.
# -add => <singular>: Append " <singular>" at end only if $num == 1.
# -addpl => <plural>: Append " <plural>" at end only if $num != 1.
sub Add_s {
   my($num, $thing, %opt)= @_;
   if ($num != 1) {
      if (exists $opt{-plural}) {
         $thing= $opt{-plural};
      }
      else {
         $thing.= 's';
      }
   }
   if ($num == 0 && exists $opt{-none}) {
      return $opt{-none} . ' ' . $thing;
   }
   elsif ($num > 0 && exists $opt{-some}) {
      return $opt{-some} . ' ' . $num . ' ' . $thing;
   }
   $thing= $num . ' ' . $thing;
   if ($num == 1 && exists $opt{-add}) {
      $thing.= ' ' . $opt{-add};
   }
   elsif (exists $opt{-addpl}) {
      $thing.= ' ' . $opt{-addpl};
   }
   $thing;
}


1;
