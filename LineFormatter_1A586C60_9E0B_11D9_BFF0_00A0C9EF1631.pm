# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


# This is a subclassed 'LineDataSource' class which reads its own
# input as a set of unformatted text chunk lines, interprets it as
# words and paragraphs, and outputs the resulting text line by line
# as an appropriately reformatted text.
#
# The class supports multiple reformatting modes, such as word wrap.
#
# Arbitrary customized reformatting modes are supported via callbacks.
#
# The basic idea is that the input text must be broken down into tokens,
# be it characters or syllables or words or whatever.
#
# Those tokens will then be added to an output accumulator, separated
# by appropriate separator tokens (such as a space character).
#
# This process continues until a special "paragraph separator" token
# is encountered or until the maximum line length is exceeded.
#
# Then the contents of the accumulator are output as the next line
# of formatted text, and the text which has been output will be
# removed from the accumulator.
#
# This process continues until no more input data is available.
#
# Each token can be associated with a tabulator symbol.
#
# Newly defined tabulator symbols are associated with absolute column
# positions as soon as the lines containing the new symbols are output.
#
# After that, each token associated with a tabulator symbol will be aligned
# to the previous absolute position of that symbol, filling with whitespace
# tokens as required.


package Lib::LineFormatter;
use base qw(Lib::LineDataSource);


use Carp;
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;
use LineDataSource_B87FE842_9D93_11D9_BFF0_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 2673 $';


# Instance data hash key prefix is 'igr3_'.
#
# $self->{igr3_acc}: Output accumulator for reformatted text.


# Construct a new instance of a FileLinesWindow object.
# Options:
# -input => $input_source
#  The same values as accepted by LineDataSource::new().
sub new {
   my($self, %opt)= @_;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->SUPER::new($opt{-input});
   Lib::LineDataSource->new($opt{-input});
   return $self;
}


# Returns the first or next "current" properly formatted output line.
# Each line will end with the current input record separator $/.
# Returns undef only when the input data source has been exhausted.
sub readline {
   my $self= shift;
   return $self->SUPER::readline;
}


1;
