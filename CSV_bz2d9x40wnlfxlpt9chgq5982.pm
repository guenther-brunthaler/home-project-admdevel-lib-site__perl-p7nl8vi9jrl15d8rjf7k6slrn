# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib;


use Lib::SimpleParser_8AEE1C20_CBA0_11D5_9920_C23CC971FBD2;


our $uqt_bz2d9x40wnlfxlpt9chgq5982= Lib::SimpleParser::create_trie(
   -delimiters => [',' => ',', '' => '']
);
our $uqtl_bz2d9x40wnlfxlpt9chgq5982= Lib::SimpleParser::create_trie(
   -delimiters => [',' => ',', '' => '', "\n" => "\n"]
);
our $uqtlp_bz2d9x40wnlfxlpt9chgq5982= Lib::SimpleParser::create_trie(
   -delimiters => [',' => ',', '' => '', "\n\n" => "\n"]
);
our $qt_bz2d9x40wnlfxlpt9chgq5982= Lib::SimpleParser::create_trie(
   -delimiters => ['"' => 0, '""' => 1]
);


# Convert a Microsoft CSV file line string into an array of strings.
# In a list context, returns the list (or an empty list at EOF).
# Otherwise, returns a reference to the list (or undef at EOF).
# The first argument is a
# Lib::SimpleParser_8AEE1C20_CBA0_11D5_9920_C23CC971FBD2::SimpleParser
# object which will be used to read the data.
# Options:
# -columns => <n>: Sets the number of items per logical line to <n>.
# This will allow "\n" within unquoted strings, which would be interpreted
# als EOL without the -columns option.
# -trailing_paragraph => 1: Enables trailing multiline paragraph processing
# mode. In this mode, unquoted last items in a logical line can also contain
# multiple lines, and must be terminated by an empty line following the
# final newline at the end of the last line.
sub csv2list($%) {
   my($p, %opt)= @_;
   my(@arr, $s, $t);
   $p->skip_ws;
   return wantarray ? () : undef if $p->try_parse_eof;
   for (;;) {
      if ($p->try_parse_string('"')) {
         $s= '';
         while (
            $p->parse_until(-trie => $qt_bz2d9x40wnlfxlpt9chgq5982, -result => \$t)
         ) {$s.= $t . '"'}
         push @arr, $s . $t;
         $p->skip_ws;
      }
      else {
         $t= $p->parse_until(
            -trie
            => $opt{-columns} && @arr + 1 < $opt{-columns}
            ? $uqt_bz2d9x40wnlfxlpt9chgq5982
            : $opt{-trailing_paragraph}
            ? $uqtlp_bz2d9x40wnlfxlpt9chgq5982
            : $uqtl_bz2d9x40wnlfxlpt9chgq5982
            , -result => \$s
         );
         $p->unget_char($t) unless $t eq '';
         $s =~ s/\s*$//;
         $s.= "\n" if $t eq "\n" && $opt{-trailing_paragraph};
         push @arr, $s;
         our $cc;
         ++$cc;
         print "CTR: $cc\n";
      }
      if (
         ($p->try_parse_eol || $p->try_parse_eof)
         && (!$opt{-columns} || @arr == $opt{-columns})
      ) {
         last;
      }
      $p->parse_string(',');
      $p->skip_ws;
   }
   wantarray ? @arr : \@arr;
}


# Convert an array of strings into a valid Microsoft CSV file line string.
# Options:
# -space => 1: includes a space after "," separators.
# -trailing_paragraph => 1: Enables trailing multiline paragraph processing
# -separator => $string: Defines something different than ',' as the separator.
# mode. In this mode, unquoted last items in a logical line can also contain
# multiple lines, and must be terminated by an empty line following the
# last newline.
sub list2csv(\@%) {
   my ($a, %opt)= @_;
   my $r= '';
   my $sep= $opt{-separator} || ',';
   my $cs= $opt{-space} ? $sep . ' ' : $sep;
   my $pat1= qr/ ["$sep] | ^\s | \s$ | \n\n /x;
   my $pat2= qr/ ["$sep\n] | ^\s | \s$ /x;
   for (my $i= 0; $i < @$a; ++$i) {
      $r.= $cs if $i > 0;
      if (
         $i == @$a && $opt{-trailing_paragraph} && $a->[$i] =~ /\n$/
         && $a->[$i] !~ /$pat1/
      ) {
         $r.= $a->[$i] . "\n";
      }
      elsif ($a->[$i] =~ /$pat2/) {
         my $s= $a->[$i];
         $s =~ s/"/""/g;
         $r.= qq!"$s"!;
      }
      else {
         $r.= $a->[$i];
      }
   }
   $r;
}


1;
