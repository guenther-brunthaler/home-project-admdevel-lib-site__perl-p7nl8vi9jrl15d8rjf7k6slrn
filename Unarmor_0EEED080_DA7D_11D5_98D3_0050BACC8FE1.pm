# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;
use Carp;


# Decode an Guenther Brunthaler-style radix-64 encoded string.
sub Unarmor {
   our %decode;
   my($b, $r);
   unless (exists $decode{'0'}) {
      my @a= ('#', '*', '0' .. '9', 'A' .. 'Z', 'a' .. 'z');
      my $i= 0;
      foreach (@a) {$decode{$_}= chr $i++}
   }
   $b= join(
      '',
      map {
         croak "invalid Radix-64 digit" unless exists $decode{$_};
         substr unpack('B*', $decode{$_}), -6;
      } split(//, shift)
   );
   $b= substr $b, 0, length($b) - $r if $r= length($b) % 8;
   pack 'B*', $b;
}


1;
