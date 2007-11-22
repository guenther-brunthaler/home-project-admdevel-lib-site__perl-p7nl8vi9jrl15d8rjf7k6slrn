# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


# Read a file via a single memory buffer.
package Lib::Buffer::Reader;
our $VERSION= '1.0';


use Carp;
use Lib::Add_nd_6D696094_CBC0_11D5_9920_C23CC971FBD2;


# Instance variables (hash key prefix is 'rdd2_'):
#
# $self->{rdd2_buf}: input buffer reference.
# $self->{rdd2_line}: current line number.
# $self->{rdd2_pos}: current parsing position.
# $self->{rdd2_fname}: current file name.


# If the <buffer> reference is not provided, a local buffer will be used.
sub Reader {
   my($self, $fname, $bufref)= @_;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   unless (defined $bufref) {
      my $buffer;
      $bufref= \$buffer;
   }
   $self->{rdd2_line}= 1;
   $self->{rdd2_buf}= $bufref;
   $self->{rdd2_pos}= 0;
   $self->{rdd2_fname}= $fname;
   local(*IN);
   open IN, '<', $fname or croak "Cannot open file '$fname' for reading";
   $$bufref= join('',
      map {
         s!^\s*(.*?)(?:\s*(?:\#|//).*)?\s*$!$1\n! or croak;
         $_
      } <IN>
   );
   close IN or croak;
   $self;
}


# Returns a <position> object.
sub getpos {
   my $self= shift;
   {rdd2_pos => $self->{rdd2_pos}, rdd2_line => $self->{rdd2_line}};
}


# Returns next character or undef for EOF.
sub getchar {
   my $self= shift;
   return undef if $self->{rdd2_pos} >= length(${$self->{rdd2_buf}});
   my($c);
   if (($c= substr ${$self->{rdd2_buf}}, $self->{rdd2_pos}++, 1) eq "\n") {
      ++$self->{rdd2_line};
   }
   $c;
}


# Resets back to a previous position.
# Argument: Either a character count (defaults to 1) or position record
# as returned from <getpos>.
sub back {
   my($self, $pos)= @_;
   if (ref $pos) {
      foreach (keys %$pos) {
         $self->{$_}= $pos->{$_};
      }
   }
   else {
      $pos= 1 unless defined $pos;
      while (--$pos >= 0) {
         if (substr ${$self->{rdd2_buf}}, --$self->{rdd2_pos}, 1 eq "\n") {
            --$self->{rdd2_line};
         }
      }
   }
}


# Returns the number of characters parsed since <$pos>.
sub plength {
   my($self, $pos)= @_;
   $self->{rdd2_pos} - $pos->{rdd2_pos};
}


# Skips the specified number of characters.
sub advance {
   my($self, $chars)= @_;
   $self->{rdd2_pos}+= $chars;
}


# Parses a string of <n> characters off the current file position.
# Returns the string if successful.
# Returns 'undef' and resets to the original position if not successful.
sub getstring {
   my($self, $n)= @_;
   return undef if $self->{rdd2_pos} + $n > length(${$self->{rdd2_buf}});
   my $oldpos= $self->{rdd2_pos};
   $self->{rdd2_pos}+= $n;
   substr ${$self->{rdd2_buf}}, $oldpos, $n;
}


# Skips any whitespaces.
sub skipws {
   my $self= shift;
   my($c);
   while ($c= $self->getchar) {
      last if $c !~ /\s/;
   }
   --$self->{rdd2_pos} if defined $c;
}


# Print word-wrapped text to a file handle.
# Leading or multiple "\n" specify the end of a paragraph.
# Single "\n" specify the beginning of a new line within the same paragraph.
sub wrap_print {
   my($fh, @txt)= @_;
   my $llen= 75;
   my($left);
   @txt= split /\n{2,}/s, join('', "\n", @txt);
   foreach (@txt) {
      # Process paragraphs.
      foreach (split /\n/s) {
         # Process wrapped lines starting at the left margin.
         $left= $llen;
         foreach (split) {
            # Process words to emit.
            $_.= ' ';
            if (length > $left) {
               print $fh "\n$_";
               $left= $llen - length;
            }
            else {
               print $fh $_;
               $left-= length;
            }
         }
         # Back to left margin.
         print $fh "\n";
      }
      print $fh "\n";
   }
}


# Report failure. Read position must be at the error.
sub fail {
   my($self, $msg)= @_;
   my $maxctx= 100;
   $msg =~ s/\.?\n*$//s;
   wrap_print(
      *STDERR{IO},
      "\n", $msg, ' ',
      "after the text position indicated by ",
      "the '<***ERROR***>'-marker on line ",
      $self->{rdd2_line}, ' at the ', Lib::Add_nd($self->{rdd2_pos} + 1),
      " text character counting from the beginning of file '",
      $self->{rdd2_fname}, "'):\n"
   );
   my($i, $c);
   for ($i= $self->{rdd2_pos}; --$i >= 0; ) {
      last if substr(${$self->{rdd2_buf}}, $i, 1) eq "\n";
   }
   if ($self->{rdd2_pos} - $i > $maxctx) {
      $i= $self->{rdd2_pos} - $maxctx;
      print STDERR '<...>';
   }
   if (
      ++$i >= length(${$self->{rdd2_buf}})
      || ($c= substr(${$self->{rdd2_buf}}, $i, 1)) eq "\n"
   ) {
      print STDERR "<***ERROR_IN_EMPTY_LINE***>";
   }
   for (
      ;
      $i < length(${$self->{rdd2_buf}})
      && ($c= substr(${$self->{rdd2_buf}}, $i, 1)) ne "\n";
      ++$i
   ) {
      foreach ([qw/< LT/], [qw/> GT/], ["\t" => 'TAB']) {
         if ($c eq $_->[0]) {
            $c= '<' . $_->[1] . '>';
            last;
         }
      }
      if (ord($c) == 0x7f || (ord($c) & 0x7f) < 0x20) {
         $c= sprintf "<0x%02x>", ord $c;
      }
      print STDERR '<***ERROR***>' if $i == $self->{rdd2_pos};
      print STDERR $c;
      if ($i > $self->{rdd2_pos} + 2 * $maxctx) {
         print STDERR '<...>';
         last;
      }
   }
   print STDERR "\n";
   $@= '';
   croak;
}


# Skips all whitespaces. At least one must be present.
sub parsews {
   my $self= shift;
   croak "Missing whitespace" unless $self->getchar =~ /\s/;
   $self->skipws;
}


# Returns true if the specified string could be parsed.
# If not successful, unreads any partially read string before returning.
sub tryparsestring {
   my($self, $s)= @_;
   my($pos, $i);
   $pos= $self->getpos;
   for ($i= 0; $i < length($s); ++$i) {
      if (substr($s, $i, 1) ne $self->getchar) {
         $self->back($pos);
         return undef;
      }
   }
   1;
}


sub parsestring {
   my($self, $s)= @_;
   unless ($self->tryparsestring($s)) {
      croak "'$s' was expected";
   }
}


sub parse_uint {
   my $self= shift;
   my($s, $c);
   for ($s= ''; defined($c= $self->getchar); $s.= $c) {
      if ($c !~ /\d/) {
         $self->back;
         last;
      }
   }
   croak "An unsigned integer number was expected" if $s eq '';
   $s;
}


1;
