# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


# A FileLinesWindow object allows to read a line data source like
# a normal file, but also provides a window of preceding and succeeding lines
# as each "current" line is being processed.
# The underlying data source may be backed up by a physical file,
# directly specified text, or client-defined callbacks.


package Lib::FileLinesWindow;


use Carp;
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 2673 $';


# Instance data hash key prefix is 'jh06_'.
#
# $self->{jh06_input}: Object with readline-method providing input lines.
# $self->{jh06_buf}->[$i]: Circular buffer for lines window.
# $self->{jh06_buf}->[$i]->[0]: Line contents.
# $self->{jh06_buf}->[$i]->[1]: Indicates whether this is a virtual line.
# $self->{jh06_n}: # of total random accessible lines in the lines window.
# $self->{jh06_i}: Index of line considered 'current' within lines window.
# $self->{jh06_j}: Index of latest line within lines window.
# $self->{jh06_eof}: Whether EOF has been reached.
# $self->{jh06_lnum}: Current line number for 'current' line.


{
   # This is a subclassed 'LineDataSource' class which prepends and appends
   # a specified number of constant value lines before and after the actual
   # data returned by the actual LineDataSource.
   package Lib::BorderedLineDataSource;
   use LineDataSource_B87FE842_9D93_11D9_BFF0_00A0C9EF1631;
   use base qw(Lib::LineDataSource);
   
   
   # Instance data hash key prefix is 'e0j8_'.
   #
   # $self->{e0j8_virtual}= $SYNTHESIZED_LINES_VALUE.
   # $self->{e0j8_after}= $NUM_VIRTUAL_LINES_AFTER_CONTENTS.
   # $self->{e0j8_state} == -1: Within prepended border segment.
   # $self->{e0j8_state} == 0: Delivering data of underlying line data source.
   # $self->{e0j8_state} == +1: Within appended border segment.
   # $self->{e0j8_state} == +2: At EOF.
   # $self->{e0j8_n}= $LINES_LEFT_TO_PROCESS_IN_CURRENT_STATE.


   # This method takes the following argument key/value pairs:
   # -input => $LineDataSoure_CTOR_ARGUMENT
   #  Mandatory. This argument will be passed through to the
   #  base class' LineDataSource->new() constructor.
   # -virtual => $VALUE
   #  This is the value to be returned for the virtual border lines. A
   #  newline character will be added automatically upon output.
   #  Cannot be the undef value. Defaults to an empty string.
   #  A value of 'undef' will also be silently promoted to an empty string.
   # -before => $COUNT
   #  The # of virtual border lines to be returned before the actual
   #  contents of the input data source. Defaults to 0.
   # -after => $COUNT
   #  The # of virtual border lines to be returned after the actual
   #  contents of the input data source. Defaults to 0.
   sub new {
      my($self, %opt)= @_;
      $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
      $self->SUPER::new($opt{-input});
      $self->{e0j8_virtual}=
         defined($opt{-virtual}) ? $opt{-virtual} . "\n" : "\n"
      ;
      $self->{e0j8_n}= $opt{-before} || 0;
      $self->{e0j8_after}= $opt{-after} || 0;
      $self->{e0j8_state}= -1;
      return $self;
   }


   # Accepts an optional argument: A reference to a variable.
   # If specified, that variable will be set to a boolean indicating
   # whether the returned value is a synthesized virtual one.
   sub readline {
      my($self, $virtual)= @_;
      if (wantarray) {
         my($next, @result);
         push @result, $next while defined($next= $self->readline($virtual));
         return @result;
      }
      else {
         {
            # Start or redo state examination.
            if ($self->{e0j8_state} == 0) {
               my $line;
               if (defined($line= $self->SUPER::readline)) {
                  $$virtual= undef if defined $virtual;
                  return $line;
               }
               ++$self->{e0j8_state};
               redo;
            }
            elsif ($self->{e0j8_state} == 2) {
               $$virtual= undef if defined $virtual;
               return undef;
            }
            else {
               if ($self->{e0j8_n}--) {
                  $$virtual= 1 if defined $virtual;
                  return $self->{e0j8_virtual};
               }
               else {
                  ++$self->{e0j8_state};
                  $self->{e0j8_n}= $self->{e0j8_after};
                  redo;
               }
            }
         }
      }
   }
}


# Construct a new instance of a FileLinesWindow object.
# Options:
# -input => $input_source
#  The same values as accepted by LineDataSource::new().
# -before => $accessible_lines_before_current_line
#  The number of lines (default: 0) that must be available before
#  the "current" line in the window.
# -after => $accessible_lines_after_current_line
#  The number of lines (default: 0) that must be available after
#  the "current" line in the window.
# -virtual => $line_contents_to_be_returned_for_nonexistant_lines
#  If this value is specified, even if it is <undef>, all lines of
#  the input file will be returned as the "current" line, even though
#  this may extend the window before the first and beyond the last
#  existing lines. For such lines, the value specified
#  with this '-virtual'-option will be returned.
#  A value of 'undef' will silently be promoted to an empty string,
#  because 'undef' has the reserved meaning 'end of input data' and
#  cannot actually be used as for synthesizing virtual lines.
#  If this option is not used, the first and last lines of the file will
#  never be returned as the "current" line; those lines will then only
#  be available as "lines in the window before/after the current line".
#  Important: In absence of '-virtual', no lines at all will be returned
#  as the "current" line if there are fewer lines in the input than
#  the window size is.
sub new {
   my($self, %opt)= @_;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->{jh06_input}=
      exists $opt{-virtual}
      ? new Lib::BorderedLineDataSource(
           -input => $opt{-input}
         , -virtual => $opt{-virtual}
         , -before => $opt{-before}
         , -after => $opt{-after}
      )
      : new Lib::LineDataSource($opt{-input})
   ;
   $self->{jh06_buf}= [];
   $#{$self->{jh06_buf}}= 
      (
         $self->{jh06_n}= ($opt{-before} || 0) + 1 + ($opt{-after} || 0)
      ) - 1
   ;
   $self->{jh06_eof}= undef;
   # Index of last window line.
   $self->{jh06_j}= $self->{jh06_n} - 1;
   # Fill lines window except for last line.
   for (my $i= 0; $i < $self->{jh06_n}; ++$i) {
      $self->{jh06_buf}->[$i]= [];
      if ($i != $self->{jh06_j}) {
         unless (
            defined(
               $self->{jh06_buf}->[$i]->[0]
               = $self->{jh06_input}->readline(
                  \$self->{jh06_buf}->[$i]->[1]
               )
            )
         ) {
            $self->{jh06_eof}= 1;
            last;
         }
      }
   }
   $self->{jh06_lnum}= 0;
   # Circular move 'last index' left by one position.
   $self->{jh06_j}= $self->{jh06_j} > 0 ? $self->{jh06_j} - 1 : 0;
   # Set index to line before initial current line.
   $self->{jh06_i}= ($opt{-before} ? $opt{-before} : $self->{jh06_n}) - 1;
   return $self;
}


# Fetch the first or next "current" line of the input file.
# Internally, a sliding window of lines is contained, where the
# -before and -after options of new() determine how many lines are
# available before and after the current line at any moment.
# Note that if the file has fewer lines than the window size,
# and the -virtual option has not been used, readline() will return
# <undef> immediately (thus indicating the end of the file).
sub readline {
   my $self= shift;
   my($i, $j, $n);
   return undef if $self->{jh06_eof};
   # Cycle right 'current' index.
   $i= $self->{jh06_i} + 1;
   $i= 0 if $i >= ($n= $self->{jh06_n});
   $self->{jh06_i}= $i;
   ++$self->{jh06_lnum};
   # Cycle right 'last' index (yields 'oldest' index).
   $j= $self->{jh06_j} + 1;
   $j= 0 if $j >= $n;
   $self->{jh06_j}= $j;
   # Read next line into 'oldest' index.
   unless (
      defined(
         $self->{jh06_buf}->[$j]->[0]
         = $self->{jh06_input}->readline(\$self->{jh06_buf}->[$j]->[1])
      )
   ) {
      $self->{jh06_eof}= 1;
      return undef;
   }
   # Return 'current' line.
   return $self->{jh06_buf}->[$i]->[0];
}


# Internally used.
sub buf_info {
   my($self, $index, $slot)= @_;
   my $n= $self->{jh06_n};
   $index= ($index || 0) + $self->{jh06_i};
   $index+= $n if $index < 0;
   if ($index < 0) {
      die "Index refers to a line before the first line in the line window";
   }
   $index-= $n if $index >= $n;
   if ($index >= $n) {
      die "Index refers to a line after the last line in the line window";
   }
   return $self->{jh06_buf}->[$index]->[$slot];
}


# Returns a line from the current window relative to the
# line which is considered to be the current line.
# Arguments: The index, where 0 (default) refers to the current line.
# Index -1 means the line before the current line,
# index +1 means the line after it, etc.
# The index must always be within the bounds specified by the
# -before and -after options of new().
sub line {
   my($self, $index)= @_;
   return $self->buf_info($index, 0);
}


# Given a line index as for line(), returns a boolean whether that
# line is a virtual line that has been synthesized as a result
# of the '-virtual'-option of new(), rather than actually being part
# of the input file.
sub is_virtual {
   my($self, $index)= @_;
   return $self->buf_info($index, 1);
}


# Given an optional line index as for line(), returns the line number
# associated with that line.
# Defaults to the index of the current line.
sub line_number {
   my($self, $index)= @_;
   return $self->{jh06_lnum} + ($index || 0);
}


# Skip the specified number (default 1) of lines.
# The lines will be read (and must be non-virtual and available),
# but their contents will be thrown away.
sub skip {
   my($self, $n)= @_;
   $n= 1 unless defined $n;
   while ($n-- > 0) {
      if (!defined($self->readline) || $self->is_virtual) {
         croak "tried to move the file position beyond end of file";
      }
   }
}


1;
