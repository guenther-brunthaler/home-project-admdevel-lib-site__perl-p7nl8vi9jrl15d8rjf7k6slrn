# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib::SimpleParser;
our $VERSION= '1.0';


use Carp;
use Lib::StringConv_8AEE1C21_CBA0_11D5_9920_C23CC971FBD2;


=head1 NAME

Lib::SimpleParser - Class for simple and fast parsing.

=head1 DESCRIPTION

C<SimpleParser> parses text or binary files, depending on how a
file has been opened.

It reads data only in fixed size chunks (except for the last one)
rather than in a line buffered mode in order to optimize troughput.

=head1 METHODS

=cut


# Instance variables (hash key prefix is 'sp_'):
#
# $self->{sp_fh} == (*SOURCE{IO} || undef);
# $self->{sp_needs_closing}: True if file has been opened by init();
# $self->{sp_filename} == ($SOURCE_FILE_NAME || undef);
# $self->{sp_line} == ($SOURCE_FILE_LINE_NUMBER || undef);
# $self->{sp_ungot}= []: Buffer of characters pushed back to input stream.
# $self->{sp_buf}: Next chunk of data to be parsed, or string to be parsed.
# $self->{sp_buffer_size} == (undef || $BUFFER_SIZE)
# $self->{sp_bp}: Buffer pointer.


=head2 CONSTRUCTOR new

            use Lib::SimpleParser_8AEE1C20_CBA0_11D5_9920_C23CC971FBD2;
            $parser= new Lib::SimpleParser;

Constructs and returns a new C<SimpeParser> object.

=cut
sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self;
}


=head2 DESTRUCTOR

When an Lib::SimpleParser object is being destroyed at the end of its
lifetime, the C<close> method is called automatically.

=cut
sub DESTROY {
   my($self)= @_;
   $self->close;
}


=head2 METHOD init

            $parser->init(-filename => $name);
            $parser->init(-fh => *FH{IO}, -filename => $name);
            $parser->init(-string => $buffer);

Initializes or resets the parser object and associates it with a buffer
containing the text to be parsed, with the handle of an already open file,
or with the name of a file to be opened and parsed.

For a complete list of options and features see L<NOTES - METHOD init>.

=cut
sub init {
   my($self, %opt)= @_;
   $self->close;
   if (exists $opt{-filename}) {
      croak "undefined file name" unless defined $opt{-filename};
      $self->{sp_filename}= $opt{-filename};
   }
   if (exists $opt{-string}) {
      croak "cannot parse undefined string" unless defined $opt{-string};
      $self->{sp_buf}= $opt{-string};
      undef $self->{sp_line};
   }
   else {
      if (exists $opt{-line}) {
         unless ($self->{sp_line}= $opt{-line}) {
            croak "invalid line number specified for parsing";
         }
      }
      else {
         $self->{sp_line}= 1;
      }
      if (exists $opt{-multiline_string}) {
         unless (defined $opt{-multiline_string}) {
            croak "cannot parse undefined multi-line string";
         }
         $self->{sp_buf}= $opt{-multiline_string};
      }
      elsif (exists $opt{-fh}) {
         $self->{sp_fh}= $opt{-fh};
         $self->{sp_buf}= '';
      }
      elsif (defined $self->{sp_filename}) {
         local(*IN);
         unless (open IN, '<', $self->{sp_filename}) {
            croak "Unable to open file '$self->{sp_filename}' for reading!";
         }
         $self->{sp_fh}= *IN{IO};
         $self->{sp_needs_closing}= 1;
         $self->{sp_buf}= '';
      }
      else {
         croak "unsupported parsing mode";
      }
   }
   if (exists $opt{-buffer}) {
      if ($opt{-buffer} eq 'character') {
         $self->{sp_buffer_size}= 1;
      }
      elsif ($opt{-buffer} eq 'line') {
         undef $self->{sp_buffer_size};
      }
      elsif ($opt{-buffer} =~ /^\d+$/ && $opt{-buffer} > 1) {
         $self->{sp_buffer_size}= $opt{-buffer};
      }
      else {
         croak "invalid buffer size specified";
      }
   }
   else {
      $self->{sp_buffer_size}= 4096;
   }
   $self->{sp_ungot}= [];
   $self->{sp_bp}= 0;
}


=head2 METHOD close

Resets the parser object and closes the input file if the parser
did opened it.

This method is automatically called at the beginning of C<init> in order
to be able to reuse the parser object. It is also called when the
parser object is destroyed.

It may be useful to call this method manually in order to force the
parser object to close its input file even though the parser object itself
is not yet destroyed or re-initialized.

=cut
sub close {
   my($self)= @_;
   close $self->{sp_fh} if $self->{sp_needs_closing};
   foreach (keys %$self) {
      delete $self->{$_};
   }
}


=head2 METHOD get_line_number

Returns the current line number of the B<next> character to be returned.
The terminating C<\n> is considered to be the last character of each line.

In other words, when a C<\n> has just been read, then the line number
is already set to the following line.

=cut
sub get_line_number {
   my($self)= @_;
   $self->{sp_line};
}


=head2 METHOD try_get_char

            if (defined($c= $parser->try_get_char)) { ... }

Tries to parse the next character C<$c> off the text to be parsed.

Returns the C<undef> value at I<EOF (end of file)>.

=cut
sub try_get_char {
   my($self)= @_;
   my($c);
   if ($self->{sp_bp} < 0) {
      # Get back ungot character.
      ++$self->{sp_bp};
      $c= pop @{$self->{sp_ungot}};
      if ($c == ord("\n") && defined($self->{sp_line})) {
         ++$self->{sp_line};
      }
      return chr $c;
   }
   if ($self->{sp_bp} >= length $self->{sp_buf}) {
      # read next buffer
      die unless defined($self->{sp_buf});
      if (defined $self->{sp_fh}) {
         # File mode.
         if (defined $self->{sp_buffer_size}) {
            # Character/Block buffer mode.
            unless (
               defined(read($self->{sp_fh}, $self->{sp_buf}, $self->{sp_buffer_size}))
            ) {
               my $msg;
               $msg= "read error after line " . $self->{sp_line} . " of input file";
               if (defined $self->{sp_filename}) {
                  $msg.= " '$self->{sp_filename}'";
               }
               croak $msg;
            }
         }
         else {
            # Line buffer mode.
            unless (defined($self->{sp_buf}= readline $self->{sp_fh})) {
               $self->{sp_buf}= '';
            }
         }
         $self->{sp_bp}= 0;
         return if length($self->{sp_buf}) == 0;
      }
      else {
         # Buffer mode.
         return;
      }
   }
   # now read from the buffer
   $c= substr $self->{sp_buf}, $self->{sp_bp}++, 1;
   if ($c eq "\n" && defined($self->{sp_line})) {
      ++$self->{sp_line};
   }
   $c;
}


=head2 METHOD get_char

            $c= $parser->get_char;

Parses the next character C<$c> off the text to be parsed.

Raises an error if I<EOF> is encountered.

=cut
sub get_char {
   my($self)= @_;
   my($c);
   unless (defined ($c= $self->try_get_char)) {
      $self->raise_error("unexpected end of file");
   }
   $c;
}


=head2 METHOD unget_char

            $parser->unget_char($c);

Undoes a previous C<get_char> or C<try_get_char> that returned C<$c>.

Also works if C<$c> has been the C<undef> value.

=cut
sub unget_char {
   my($self, $c)= @_;
   return unless defined $c;
   if ($c eq "\n" && defined($self->{sp_line})) {
      --$self->{sp_line};
   }
   push @{$self->{sp_ungot}}, ord $c if --$self->{sp_bp} < 0;
}


=head2 METHOD unget_string

            $parser->unget_string($s);

Puts an previously parsed string C<$s> back to the text to be parsed.

Also works if C<$c> has been just the C<undef> value.

=cut
sub unget_string {
   my($self, $str)= @_;
   return unless defined $str;
   my $i;
   for ($i= length($str); $i--; ) {
      $self->unget_char(substr $str, $i, 1);
   }
}


=head2 METHOD try_parse_token

            if (defined($token= $parser->try_parse_token)) { ... }

Tries to parse a token and returns the token string.

A token is defined as a sequence of non-whitespace characters
followed by a whitespace character or by I<EOF>.

Returns C<undef> if no token could be found.

=cut
sub try_parse_token {
   my($self)= @_;
   my($string, $c);
   for (;;) {
      last unless defined($c= $self->try_get_char);
      if ($c=~ /\s/) {
         $self->unget_char($c);
         last;
      }
      $string.= $c;
   }
   $string;
}


=head2 METHOD parse_token

Tries to parse a token and returns the parsed token string.

A token is defined as a sequence of non-whitespace characters
followed by a whitespace character or by I<EOF>.

Raises an error if no token could be found.

=cut
sub parse_token {
   my($self)= @_;
   my($string);
   unless (defined($string= $self->try_parse_token)) {
      $self->raise_error("missing any token string");
   }
   $string;
}


=head2 METHOD skip_ws

Skip any whitespace characters except I<EOL (end of line; newline)>.

=cut
sub skip_ws {
   my($self)= @_;
   my($c);
   while (defined($c= $self->try_get_char)) {
      last unless $c=~ /\s/ && $c ne "\n";
   }
   $self->unget_char($c);
}


=head2 METHOD skip_ws_eol

Skip any whitespace characters including I<EOL (newline)>.

=cut
sub skip_ws_eol {
   my($self)= @_;
   my($c);
   while (defined($c= $self->try_get_char)) {
      last unless $c=~ /\s/;
   }
   $self->unget_char($c);
}


=head2 METHOD try_parse_digit10

Tries to parse a decimal digit and returns its numeric value.

Returns C<undef> if not successful.

=cut
sub try_parse_digit10 {
   my($self)= @_;
   my($c);
   if (defined($c= $self->try_get_char) && $c =~ /\d/) {
      return +$c;
   }
   $self->unget_char($c);
   undef;
}


=head2 METHOD try_parse_unsigned

Tries to parse a decimal unsigned integer and returns its value.

Returns C<undef> if not successful.

=cut
sub try_parse_unsigned {
   my($self)= @_;
   my($v, $d);
   return undef unless defined($v= $self->try_parse_digit10);
   while (defined($d= $self->try_parse_digit10)) {
      $v= $v * 10 + $d;
   }
   return $v;
}


=head2 METHOD try_parse_integer

Tries to parse a decimal integer with optional sign and returns its value.

Returns C<undef> if not successful.

=cut
sub try_parse_integer {
   my($self)= @_;
   my($s, $v, $neg);
   if (defined($s= $self->try_get_char)) {
      if ($s =~ /[+-]/) {
         $neg= $s eq '-';
         for (my $c; defined($c= $self->try_get_char); $s.= $c) {
            unless ($c =~ /[ \t]/) {
               $self->unget_char($c); # Non-whitespace.
               last;
            }
         }
      }
      else {
         $self->unget_char($s); # Non-sign.
         $s= '';
      }
   }
   unless (defined($v= $self->try_parse_unsigned)) {
      $self->unget_string($s);
      return;
   }
   $neg ? -$v : $v;
}


=head2 METHOD parse_unsigned

Parses a decimal unsigned integer and returns its value.

Raises an error if not successful.

=cut
sub parse_unsigned {
   my($self)= @_;
   my($v);
   unless (defined($v= $self->try_parse_unsigned)) {
      $self->raise_error("Missing decimal number");
   }
   $v;
}


=head2 METHOD parse_integer

Parses a decimal integer with optional sign and returns its value.

Raises an error if not successful.

=cut
sub parse_integer {
   my($self)= @_;
   my($v);
   unless (defined($v= $self->try_parse_integer)) {
      $self->raise_error("Missing decimal integer");
   }
   $v;
}


=head2 METHOD try_parse_eol_eof

Tries to parse the I<EOL (newline)> character or I<EOF> as a zero-width
character.

Returns C<1> if successful, C<undef> otherwise.

=cut
sub try_parse_eol_eof {
   my($self)= @_;
   my($c);
   if (defined($c= $self->try_get_char) && $c ne "\n") {
      $self->unget_char($c);
      return undef;
   }
   1;
}


=head2 METHOD parse_eol_eof

Parses the I<EOL (newline)> character or I<EOF> as a zero-width
character.

Raises an error if not successful.

=cut
sub parse_eol_eof {
   my($self)= @_;
   unless ($self->try_parse_eol_eof) {
      $self->raise_error("end of line or file expected");
   }
}


=head2 METHOD parse_ws_eol_eof

Skip any whitespace and then
parses the I<EOL (newline)> character or I<EOF> as a zero-width
character.

Raises an error if not successful.

=cut
sub parse_ws_eol_eof {
   my($self)= @_;
   $self->skip_ws;
   $self->parse_eol_eof;
}


=head2 METHOD skip_line

Skips all text until the end of the current line, including the
terminating I<newline> character, if any.

A line can also be terminated by I<EOF> instead of a I<newline> character.

=cut
sub skip_line {
   my($self)= @_;
   while (!$self->try_parse_eol_eof) {
      $self->get_char
   }
}


=head2 METHOD try_parse_eof

Tries to parse I<EOF> as a zero-width character.

Returns C<1> if successful, C<undef> otherwise.

=cut
sub try_parse_eof {
   my($self)= @_;
   my($c);
   if (defined($c= $self->try_get_char)) {
      $self->unget_char($c);
      return undef;
   }
   1;
}


=head2 METHOD parse_eof

Parses I<EOF> as a zero-width character.

Raises an error if not successful.

=cut
sub parse_eof {
   my($self)= @_;
   unless ($self->try_parse_eof) {
      $self->raise_error("data present after expected end of file");
   }
}


=head2 METHOD try_parse_eol

Tries to parse I<EOL> (I<NEWLINE>).

Returns C<1> if successful, C<undef> otherwise.

=cut
sub try_parse_eol {
   my($self)= @_;
   my($c);
   if (defined($c= $self->try_get_char)) {
      return 1 if $c eq "\n";
      $self->unget_char($c);
   }
   undef;
}


=head2 METHOD parse_eol

Parses I<EOL> (I<NEWLINE>).

Raises an error if not successful.

=cut
sub parse_eol {
   my($self)= @_;
   unless ($self->try_parse_eol) {
      $self->raise_error("missing '<NEWLINE>'");
   }
}


=head2 METHOD try_parse_string

            if ($parser->try_parse_string('{')) {
               # Opening curly brace has been parsed.
               ...
            }

Tries to parse a specified string off the text to be parsed.

Returns C<1> if successful, C<undef> otherwise.

=cut
sub try_parse_string {
   my($self, $string)= @_;
   my($i, $c);
   for ($i= 0; $i < length($string); ++$i) {
      if (!defined($c= $self->try_get_char) || $c ne substr($string, $i, 1)) {
         $self->unget_char($c);
         while ($i > 0) {
            $self->unget_char(substr($string, --$i, 1));
         }
         return undef;
      }
   }
   1;
}


=head2 METHOD parse_string

            # Opening curly brace must follow.
            $parser->parse_string('{');

Parses a specified string off the text to be parsed.

Raises an error if the specified string could not be parsed.

=cut
sub parse_string {
   my($self, $string)= @_;
   unless ($self->try_parse_string($string)) {
      $string= Lib::StringConv::DumpString($string, "'" => 'QUOTE');
      $self->raise_error("missing string '$string'");
   }
}


=head2 METHOD try_parse_numeric

Tries to parse an integer or floating point number off the text to be parsed.
Includes supports for the exponential format.

Returns the parsed number if successful, C<undef> otherwise.

=cut
sub try_parse_numeric {
   my($self)= @_;
   my($num, $c, $try);
   for (;;) {
      last unless defined($c= $self->try_get_char);
      $try= $num . $c;
      unless ($try=~ /^[-+]?\d*(?:\.\d*)?(?:[eE][-+]?\d*)?$/) {
         $self->unget_char($c);
         last;
      }
      $num= $try;
   }
   return undef unless defined $num;
   unless ($num=~ /^[-+]?(?:\d+|\d*\.\d*)(?:[eE][-+]?\d+)?$/) {
      $self->unget_string($num);
      return undef;
   }
   $num+= 0.;
}


=head2 METHOD parse_numeric

Parses an integer or floating point number off the text to be parsed.
Includes supports for the exponential format.

Raises an error if not successful.

=cut
sub parse_numeric {
   my($self)= @_;
   my($num);
   unless (defined($num= $self->try_parse_numeric)) {
      $self->raise_error("missing numeric constant");
   }
   $num;
}


=head2 METHOD raise_error

Dies with an error message that is augmented by the information
in which line of the input file the error has occurred.

See also L<NOTES - METHOD raise_error>.

=cut
sub raise_error {
   my $self= shift;
   die "Missing error message" unless defined($_[0]) && $_[0] gt '';
   croak $self->show(@_);
}


=head2 METHOD show

This is a debugging helper function. It returns the same basic information
that the C<raise_error> method would display as the error message,
but does not raise an exception.

Is also accepts the same options as C<raise_error>, except that no message
string needs to be specified.

Displaying this information will reveal the current parsing position.

See also L<NOTES - METHOD raise_error>.

=cut
sub show {
   my($self, $msg, %opt)= @_;
   $opt{-max_context}= 20 unless defined $opt{-max_context};
   my($c, $ctx);
   $msg= 'Currently located' unless defined $msg;
   $msg =~ s/^\s*(.*?)\s*$/$1/;
   die unless $msg =~ s/^(.?)(.*?)[!:.?]?[\n\s]*$/\u$1$2/s;
   for ($ctx= ''; defined($c= $self->try_get_char); ) {
      $ctx.= $c;
      last if $c eq "\n" || length($ctx) > $opt{-max_context};
   }
   $self->unget_string($ctx);
   $ctx= Lib::StringConv::DumpString($ctx, "'" => 'QUOTE');
   $ctx.= '<EOF>' unless defined $c;
   if ($opt{-after_error}) {
      $msg.= ' immediately before the string';
   }
   else {
      $msg.= ' at position';
   }
   $msg.= " '$ctx' in";
   if (defined $self->{sp_line}) {
      $msg.= " line $self->{sp_line}"
   }
   if (defined $self->{sp_fh}) {
      if (defined $self->{sp_filename}) {
         $msg.= " of input file '$self->{sp_filename}'";
      }
      else {
         $msg.= " of the input file";
      }
   }
   else {
      $msg.= ' the input buffer'
   }
   $msg;
}


=head2 CLASS METHOD create_trie

            $trie= Lib::SimpleParser::create_trie(
               -delimiters => ['"' => 0, "\n" => undef]
            );
            ...
            $retval= $p->parse_until(
               -result => \$parsed_string, -trie => $trie, qw/-min_size 1 -maxsize 1024/
            );

This class method supports the same C<-separators> and C<-delimiters> options
as the C<parse_until> method and creates and returns a data structure
that is required internally by L<METHOD parse_until>.

It is not actually necessary to use this method, but it can speed up
the application if C<parse_until> is called several times with the
same set of C<-delimiters> and C<-separators> options.

In such cases it is faster to call C<create_trie> once and then use
the C<-trie>-option of C<parse_until> to indirectly specify the
C<-delimiters> and C<-separators> options rather than specifying them directly.

=cut
sub create_trie {
   my(%opt)= @_;
   my($trie, $node, $c, $i, $j, $str, $delim_list, $dl2, $unget);
   # Create a trie for scanning
   # Trie structure:
   # $trie->{character} == \%SUBTRIE
   # $trie->{character} == \@LEAF
   # $trie->{character}->[0] == $TERMINAL_CHARACTER
   # $trie->{character}->[1] == (is_separator($TERMINAL_CHARACTER) ? 1 : 0)
   $trie= {'' => []}; # Preset to EOF as not allowed.
   foreach $dl2 ([$opt{-delimiters}, 0], [$opt{-separators}, 1]) {
      next unless defined($delim_list= $dl2->[0]);
      $unget= $dl2->[1];
      for ($i= 0; $i < @$delim_list; ++$i) {
         $node= $trie;
         $str= $delim_list->[$i];
            if ($str eq '') {
            $c= $str;
         }
         else {
            for ($j= 0;; ++$j) {
               $c= substr $str, $j, 1;
               last if $j + 1 == length($str);
               $node->{$c}= {} unless ref $node->{$c} eq 'HASH';
               $node= $node->{$c};
            }
         }
         $node->{$c}= [$delim_list->[++$i], $unget];
      }
   }
   $trie;
}


# Adds delimiters to array <$@delims>
# where <%$subtrie> refers to delimiter prefix <$prefix>.
sub add_delim_list {
   my($delims, $subtrie, $prefix)= @_;
   my $st;
   foreach (keys %$subtrie) {
      if (ref($st= $subtrie->{$_}) eq 'HASH') {
         # Node.
         add_delim_list($delims, $st, $prefix . $_);
      }
      else {
         # Leaf.
         die unless ref$st eq 'ARRAY';
         push @$delims, $prefix . $_ if defined $st->[0];
      }
   }
}


=head2 METHOD parse_until

            # Get string terminated by double quote and disallow "\n" in string.
            # The string must have a minimum of 1 and a maximum of 1024 characters.
            $retval= $p->parse_until(
               -result => \$parsed_string, -delimiters => ['"' => 0, "\n" => undef],
               qw/-min_size 1 -maxsize 1024/
            );

Parses all characters until one of the delimiter strings is matched.

See also L<NOTES - METHOD parse_until>.

=cut
sub parse_until {
   my($self, %opt)= @_;
   my($strref, $minsize, $maxsize)= (
      $opt{-result}, $opt{-min_size}, $opt{-max_size}
   );
   my($trie, $node, $c, $i, $j, $start, $str, @str, $unget);
   $minsize= 0 unless defined $minsize;
   unless (defined ($trie= $opt{-trie})) {
      $trie= create_trie(
         -delimiters => $opt{-delimiters}, -separators => $opt{-separators}
      );
   }
   # Parse.
   $start= $j= 0;
   OUTER: for (;;) {
      $node= $trie;
      #die unless $j == @str;
      for (;;) {
         push @str, $c= $self->try_get_char;
         $c= '' unless defined $c;
         unless (exists $node->{$c}) {
            # Parsed string did not match any pattern.
            if (defined($maxsize) && $j + 1 > $maxsize) {
               while (@str > $j) {
                  $self->unget_char(pop @str);
               }
               $self->raise_error(
                  "no delimiter found within $maxsize characters"
                  . " of the string ending"
               );
            }
            # Unget all characters except for first one.
            $start= ++$j;
            while (@str > $j) {
               $self->unget_char(pop @str);
            }
            next OUTER;
         }
         # Pattern still matches.
         if (ref ($node= $node->{$c}) ne 'HASH') {
            #die unless ref $node eq 'ARRAY';
            # At leaf - string matches.
            ($node, $unget)= @$node;
            if (defined($node) && $j >= $minsize) {
               if ($unget) {
                  # Separator found.
                  while (@str > $start) {
                     $self->unget_char(pop @str);
                  }
               }
            }
            else {
               # Disallowed delimiter.
               if (defined $node) {
                  $str
                  = 'string too short by ' . ($minsize - $j)
                  . " characters (only $j present) before end of string on"
                  ;
                  $j= 0;
               }
               else {
                  $str= 'missing required';
               }
               # Unget all characters.
               while (@str > $j) {
                  $self->unget_char(pop @str);
               }
               # Report error.
               {
                  my @delim_list;
                  # Create effective allowed delimiters list from trie.
                  add_delim_list(\@delim_list, $trie, '');
                  for ($i= $j= 0; $i < @delim_list; ++$i) {
                     if ($j) {$str.= ' or'} else {$j= 1}
                     $str.= " '";
                     if (($c= $delim_list[$i]) eq '') {
                        $str.= '<EOF>';
                     }
                     else {
                        $str.= Lib::StringConv::DumpString($c, "'" => 'QUOTE');
                     }
                     $str.= "'";
                  }
               }
               $self->raise_error($str);
            }
            # Exclude delimiter from returned string.
            $#str= $j - 1;
            # Normal return value.
            $$strref= join('', @str) if ref $strref;
            return $node;
         }
         # Intermediate node.
      }
   }
}


1;


__END__


=head1 NOTES


=head2 NOTES - METHOD init

C<init> has a lot of options, but there are only tree basic modes
of operation:

=over 4

=item Parse the contents of a string variable without using line numbers.

This is the easiest case.

A string is specified as the value of the C<-string>-option, and the parser
starts at the beginning of that string.

I<NEWLINE> characters - if any - have no effect on the current line number,
which will always remain C<undef>.

The end of the string counts as I<EOF> (end of file).

=item Parse the contents of a variable containing multiple lines of text.

A string is specified as the value of the C<-multiline_string>-option,
and the parser starts at the beginning of that string.

This mode works nearly identically to the C<-string> option,
but it does maintain a current line number.

Unless the C<-line> option is used to change this, the first line in
the string has line number 1.

Lines within the string are separated by I<NEWLINE> characters.

As with C<-string>, the end of the string counts as I<EOF> (end of file).

=item Parse the contents of a given file.

This is the most common case.

A file name is specified with the C<-filename>-option, and no file handle
is specified.

In this case, the file will be opened and read internally as needed,
and the file will be closed when the parser is re-initialized or when
the parser object is destroyed.

=item Continue parsing a file that is already open.

This mode of operation allows using an already open file for parsing,
which allows to start parsing at any position in the file.

Also, the responsibility for open and closing the file is due to the client.
The parser just uses the filehandle as specified using the C<-fh>-option,
and that's all.

Note, however, that by default the parser reads the file in fixed-size
data blocks in order to enhance performance, and so there may be
unprocessed data left in the internal buffer once the client decides
to stop using the parser and continue reading the file himself.

That is never a problem if the client continues to parse the file to
its end, but otherwise the client should select a different buffering
strategy for the parser, such as line-buffering or even character buffering,
depending on where the client wants to resume reading the file after
some parts of it have been processed by the parser.

=back

The following options are available:

=over 4

=item C<-line>

This specifies the line number for the line where the parser starts on.

Defaults to C<1> if not specified, except in <-string>-mode where
it will always be C<undef> because that mode does not support line numbers.

=item C<-filename>

This specifies the file name of the file to be opened.

If one of the options C<-fh>, C<-string> or <-multiline_string> is also
specified, then this option does B<not> specify the file to be opened,
but just the file name to report in case of an error.

If this option is not used, no file name will displayed in case of an
error message produced by the parser (see also L<METHOD raise_error>).

=item C<-fh>

The value of this option is the symbolic reference to a file handle.
For instance, imagine skipping the first 100 lines of a file before
to start parsing:

            $file= 'myfile';
            open IN, '<', $file or die;
            for (1..100) {
               <IN>; # skip line
            }
            $parser->init(-fh => *IN{IO}, -filename => $file, -line => $.);
            my_use_parser($parser);
            close IN or die;

While it is not necessary to set the file name also in this case, it
is wise to do that, because otherwise it cannot be reported in the
error message of the parser in case of an error.

=item C<-multiline_string>

This selects the string-parsing mode with line number support.

=item C<-string>

This selects the string-parsing mode without line number support.

=item C<-buffer>

Sets the read buffering strategy of the parser.

When the value specified is an integer >= 2, then this will be used as the
fixed buffer size for reading.

The parser then uses PERL C<read>-function internally to read only blocks
of that size, and continues to do so as more characters are required.

This is the default buffering strategy, and the default buffer size is
4096 bytes.

Larger sizes may speed up parsing, but this also requires more memory.

Instead of specifying an integer, the following string constants can
also be specified as the option value: C<character> and C<line>.

C<character> means 'character buffering' and is essentially the same as
specifying a buffer size of '1' (which is not allowed directly).
Actually this means 'no buffering', because each character is immediately
processed after having been read. Be warned that this mode is highly
inefficient, but it may be necessary when the client wants to resume
reading the file when the parser ended in the middle of a line.

C<line> means 'line buffering'. In line buffering mode, the parser does not
use the C<read> function in order to read the file, but rather the
usual PERL line-read operator ('<FH>'). This mode is also less efficient
than the default mode, but quite more efficient than the character buffering
mode. This mode should be used if the client wants to resume parsing
after the parser has parsed some number of complete lines.

=back

=head2 NOTES - METHOD raise_error

C<raise_error> has only one mandatory argument which is the actual
error message to be displayed.

The error message may or may not start with an uppercase character;
the first character will be uppercased as necessary automatically.

Also the error message may or may not end with a punctuation character
such as a period or an exclamation mark - such trailing characters
will be removed automatically.

The method will augment the error message with context information
if possible, and will display a maximum of 20 characters by default,
although the first encountered NEWLINE or EOF will prematurely
terminate the context.

In addition to the error message string, C<raise_error> accepts an
option list consisting of 'option => value' pairs.

The following I<option> keywords are available:

=over 4

=item C<-max_context>

The value specifies the maximum context window in number of characters.

This is the maximum number of characters reported in order to
give the user an idea about the position where the error occurred.

Defaults to C<20>.

=item C<-after_error>

The value of this option is a boolean value.

If C<after_error> is I<true>, then C<raise_error> assumes that the
parser is B<after> the origin of error, and not B<at it> as assumed by default.

Defaults to not I<true>.

=back

=head2 NOTES - METHOD parse_until

C<parse_until> has been designed to efficiently search for a very large
number of terminators at the same time.

All terminators can be single characters as well as strings of arbitrary
size.

However, C<parse_until> also has a relatively high initialization overhead
proportional to the net number of characters in all terminators.

This initialization overhead can be eliminated by calling the class method
C<Lib::SimpleParser::create_trie> once which performs most of the
initialization, and then pass the result of this function to all subsequent
invocations of C<parse_until> that use the same set of terminators.

The arguments of C<parse_until> are a list of I<(option, option_value)> pairs.

Supported options are:

=over 4

=item -result

The option value is a reference to variable that will be set to
the parsed string before the delimiter.

If this option is not specified then the parsed string will be thrown away.

=item -delimiters

The option value is a reference to a list of
I<(delimiter, return_value)>-pairs. This works the following way:

When one of the I<delimiter>s has been parsed, the associated I<return_value>
is returned, except if I<return_value> equals C<undef>: In this case, that
delimiter is I<not allowed> in the string and will trigger an error message.

If I<EOF> is encountered before one of the delimiters, an error is raised,
unless an empty string is used as one of the I<delimiter>s which will
match I<EOF>. This allows I<EOF> also to be used as a delimiter.

=item -separators

The option value is a reference to a list of
I<(separator, return_value)>-pairs.

It works identically to C<-delimiters>, except for a single difference:

Separators are I<not> consumed by the parser, while delimiters are.

That is, when the return value of C<parse_until> indicates that a
separator rather than a delimiter has been parsed, then that separator
will be the next thing to be read by the parser.

This is useful for cases where a symbol has two uses: Firstly, it serves
as a delimiter for some token. Secondly, it is only one of different
delimiters, with different syntactic meaning that is to be parsed later.

Note, however, that C<-delimiter> is the more efficient option, because
C<-separators> actually does the same thing but ungets the delimiter
back to the parsing stream before returning.

So prefer C<-delimiters> over C<-separators> as long as the extra
functionality of C<-separators> is not needed, such as for symbols that
should raise an error when encountered (that are those symbols that have
an associated return value of C<undef>).

=item -trie

This option, if specified, replaces the C<-separators> and/or C<-delimiters>
options.

The option value must be the result of a preceding call of the
C<Lib::SimpleParser::create_trie> class method.

Specifying C<-trie> is always faster than directly specifying the
C<-separators> and/or C<-delimiters> options, provided that the same set of
delimiters is used in more than once invocation of C<parse_until>.

=item -min_size

The option value is the allowed minimum length for the string to be parsed
before a delimiter is encountered.

Defaults to zero.

=item -max_size

The option value is the allowed maximum length for the string to be parsed
before a delimiter is encountered.

Defaults to no such limit.

=back

The return value of the method will be the I<return_value> that has been
associated with the delimiter that has been encountered.

If a method return value is not required, set the I<return_value>s of the
allowed C<-delimiters> to any value other than C<undef>, such as C<0>.

The return value is not restricted to be a number, however.
It can be any type of scalar, including references.


=head1 AUTHOR

Guenther Brunthaler
