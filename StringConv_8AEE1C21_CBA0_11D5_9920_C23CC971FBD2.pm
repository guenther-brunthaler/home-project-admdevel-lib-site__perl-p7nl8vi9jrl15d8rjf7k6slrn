# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib::StringConv;
our $VERSION= '1.0';


use Carp;


=head1 NAME

Lib::StringConv - Class for string formatting and conversion.

=head1 DESCRIPTION

This class provides several helper functions to aid in formatting,
re-formatting and conversion of characters strings from and into different
display formats.

=head1 METHODS

=cut


=head2 CLASS METHOD Str2GUID

Converts the string representation of a GUID into a normalized internal
representation that is more space efficient and more appropriate
for use as a hash key.

=cut
sub Str2GUID($) {
   my($s)= @_;
   return undef unless defined $s;
   croak "malformed GUID string representation '$s'!" unless (
      $s =~ s<
         ^{
            (?i:
               ([0-9A-F]{8})-([0-9A-F]{4})-([0-9A-F]{4})-([0-9A-F]{4})-([0-9A-F]{12})
            )
         }$
      ><\U$1$2$3$4$5>ox
   );
   $s;
}


=head2 CLASS METHOD GUID2Str

Converts the internal representation of a GUID into a string representation
suitable for display or output.

=cut
sub GUID2Str($) {
   my($s)= @_;
   return undef unless defined $s;
   croak "Invalid GUID hex encoding '$s'!" unless (
      $s =~ s<
         ^
         ([0-9A-F]{8})([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{12})
         $
      ><{$1-$2-$3-$4-$5}>ox
   );
   $s;
}


=head2 CLASS METHOD DumpString

Convert an arbitrary string into an escaped string suitable for display.
The escaping is only done for characters such as NEWLINE, TAB etc. that
may mess up the display.

See L<NOTES - CLASS METHOD DumpString> section for additional information.

=cut
sub DumpString($@) {
   my($str)= shift;
   my($i, $dmp, $c, %su);
   %su= (
      @_,
      '>' => 'GT',
      '<' => 'LT',
      "\t" => 'TAB',
      "\n" => 'NEWLINE'
   );
   for ($i= 0; $i < length($str); ++$i) {
      $c= substr($str, $i, 1);
      if (exists $su{$c}) {
         $c= '<' . $su{$c} . '>';
      }
      elsif ($c =~ /[[:cntrl:]]/) {
         $c= '<CHR ' . ord($c) . '>';
      }
      $dmp.= $c;
   }
   $dmp;
}


1;


__END__


=head1 NOTES

=head2 NOTES - CLASS METHOD Str2GUID

This function converts a GUID string representation such as
C<{52CD20D0-F768-11d4-97C4-0050BACC8FE1}>
into a normalized internal representation that
is suitable to serve as the key in a hash.

The internal representation also requires slightly less memory.

=head2 NOTES - CLASS METHOD DumpString

Among the printable characters, only '<' and '>' are escaped
and replaced by '<LT>' and '<GT>', respectively.

Unprintable control characters are replaced by '<CHAR I<xxx>>', where
I<xxx> is the decimal code of the character in the character set
as returned by the C<ord> function.

If other characters should also be escaped, an optional list of value
pairs may be specified, where the first value in each pair specifies
the character to quote, and the second value specifies the display
string for quoting.

For instance, the following example displays a string securely in
single or double quotes:

            $string= join('', map(chr, 0..255));
            $string= Lib::StringConv::DumpString(
               $string, "'" => 'QUOTE', '"' => 'DBLQUOTE'
            );
            print "The string is: '$string'.\n";
            print qq'Or, in other quotes: "$string".\n';
