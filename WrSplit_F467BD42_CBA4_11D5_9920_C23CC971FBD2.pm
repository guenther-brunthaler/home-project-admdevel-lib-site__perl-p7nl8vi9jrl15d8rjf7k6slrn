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


# Writes a string to a file, splitting into multiple lines based on the
# maximum allowed line length (character wrapping - not word wrapping).
# Options:
# -fh => File handle.
# -callback => Callback for output instead of file handle.
# -text => The text to output in as few lines as possible.
# -initial_prefix => Prefix of first line (after indent).
# -final_suffix => Suffix of last line (after indent).
# -newline_prefix => Prefix for new lines (after indent).
# -line_suffix => Suffix for all lines except the last one.
# -indent => Indentation for all lines (string or spaces count).
# -line_length => Maximum output line length.
# Attention: Do not include newline characters within any option string!
sub WrSplit {
   my(%opt)= @_;
   foreach (
      [-initial_prefix => ''], [-final_suffix => ''], [-newline_prefix => ''],
      [-line_suffix => ''], [-indent => ''], [-line_length => 79]
   ) {
      $opt{$_->[0]}= $_->[1] unless exists $opt{$_->[0]};
   }
   foreach (qw/-text/) {
      croak unless exists $opt{$_};
   }
   if (exists $opt{-fh}) {
      $opt{-callback}= [
         sub {
            my($text, $fh)= @_;
            print $fh $text, "\n";
         },
         $opt{-fh}
      ];
   }
   else {
      croak unless exists $opt{-callback};
      $opt{-callback}= [$opt{-callback}] if ref $opt{-callback} ne 'ARRAY';
   }
   my($out, $t, $cb, @cba, $a);
   @cba= @{$opt{-callback}};
   $cb= shift @cba;
   $t = ' ' x $t if ($t= $opt{-indent}) =~ /^\d+$/;
   foreach (qw/-initial_prefix -newline_prefix/) {$opt{$_}.= $t}
   $out= $opt{-fh};
   if (
      length($opt{-initial_prefix}) + length($t= $opt{-text})
      + length($opt{-final_suffix})
      < $opt{-line_length}
   ) {
      # Single line output.
      $a= $opt{-initial_prefix} . $t;
   }
   else {
      my($i, $j, $w);
      $w= $opt{-line_length} - length($opt{-initial_prefix})
      - length($opt{-line_suffix})
      ;
      $a= $opt{-initial_prefix};
      for ($i= 0; $i < length $t; $i+= $j) {
         if ($w == 0) {
            &$cb($a . $opt{-line_suffix}, @cba);
            $a= $opt{-newline_prefix};
            $w= $opt{-line_length} - length($opt{-line_suffix})
            - length($opt{-newline_prefix})
            ;
         }
         $j= length($t) - $i if $i + ($j= $opt{-line_length}) >= length $t;
         $j= $w if $j > $w;
         $a.= substr($t, $i, $j);
         $w-= $j;
      }
   }
   &$cb($a . $opt{-final_suffix}, @cba);
}


1;
