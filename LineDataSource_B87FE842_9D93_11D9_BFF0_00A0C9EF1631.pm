# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


# A LineDataSource object virtualizes the semantics
# of a line-based input data source.
# The underlying data source may be backed up by a physical file,
# directly specified text, or client-defined callbacks.


package Lib::LineDataSource;


use Carp;
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 11 $';


# Instance data hash key prefix is 'kyns_'.
#
# $self->{kyns_filename}= $DATA_SOURCE_NAME.
# $self->{kyns_input}= [\&callback, @arguments].


# Construct a new instance of a line data source object.
# Argument:
# [$text]:
#  The input data is not a file but rather that single line of $text.
#  If $text contains "\n", it will be broken up into several lines
#  at the position of the "\n"s and the "\n"s will be removed.
#  When returning the lines later, "\n"s will be added to the end
#  of each line returned automatically.
# [$line1, $line2, ...]:
#  Specify all the lines to be returned directly as the reference
#  of a list of strings.
#  Any list entries containing "\n" will be broken up into several lines
#  at the position of the "\n"s and the "\n"s will be removed.
#  When returning the lines later, "\n"s will be added to the end
#  of each line returned automatically.
# \&line_input_function:
#  Function will be used as a parameterless callback. Each invocation
#  should return the next line or <undef> for EOF.
#  At most a single line must be returned, and it must end with a "\n".
# [\&line_input_function, arguments ...]
#  Function will be used as a callback with parameters.
#  The remainder of the list will be passed through as arguments
#  for each invocation.
#  Each invocation should return the next line or <undef> for EOF.
#  At most a single line must be returned, and it must end with a "\n".
# *FILEHANDLE{IO}:
#  FILEHANDLE must be the handle of an file that has been opened for
#  reading. All of its lines will be read. The file will not be closed.
# $input_filename:
#  The file will be opened for reading, alle lines will be read,
#  and then the file will be closed automatically.
sub new {
   my($self, $input)= @_;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   undef $self->{kyns_filename};
   $self->{kyns_input}=
      !defined $input ? [sub {return undef}]
      : ref $input eq 'ARRAY' ? do {
         if (@$input >= 1 && ref $input->[0] eq 'CODE') {$input}
         else {
            my(@lines)= @$input;
            my($i);
            for ($i= 0; $i < @lines; ++$i) {
               if (defined index $lines[$i], "\n") {
                  splice @lines, $i, 1, split "\n", $lines[$i];
               }
            }
            $i= 0;
            [
               sub {
                  my($lines, $i)= @_;
                  return
                     $$i < @$lines
                        && $lines->[$$i++] . "\n"
                     || undef
                  ;
               }
               , \@lines, \$i
            ];
         }
      }
      : ref $input eq 'CODE' ? [$input]
      : ref $input ? [
         sub {my $fh= shift; return scalar <$fh>}
         , $input
      ]
      : do {
         local *FH;
         open FH, '<', $input
            or croak "Cannot open '$input' for reading: $!"
         ;
         $self->{kyns_filename}= $input;
         [
            sub {my $fh= shift; return scalar <$fh>}
            , *FH{IO}
         ];
      }
   ;
   return $self;
}


# In scalar context, fetches the first or next line of the input
# or returns <undef> for end of input.
# In array context, returns a list of all the remaining lines in the
# input or an empty list if there is no more input.
sub readline {
   my $self= shift;
   if (wantarray) {
      my($next, @result);
      push @result, $next while defined($next= $self->readline);
      return @result;
   }
   else {
      my($callback, @args)= @{$self->{kyns_input}};
      return &$callback(@args);
   }
}


DESTROY {
   my $self= shift;
   if (defined $self->{kyns_filename}) {
      close $self->{kyns_input}->[1] or
         die "Cannot close '$self->{kyns_filename}': $!"
      ;
      undef $self->{kyns_filename};
   }
}


1;
