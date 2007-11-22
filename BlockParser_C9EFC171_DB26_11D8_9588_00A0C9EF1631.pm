# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib::BlockParser;
our $VERSION= '1.0';


use Carp;
use Lib::StringConv_8AEE1C21_CBA0_11D5_9920_C23CC971FBD2;


=head1 NAME

Lib::BlockParser - Class for low-level parsing using block buffers.

=head1 DESCRIPTION

C<BlockParser> parses text files, binary files, string variables
or any other sort of data source.

It tries to read data in fixed size chunks when possible, but also supports
line- and unbuffered modes via client-defined data-provider objects.

It also allows the client to install customized location tracking objects,
which allow efficient tracking and reporting of arbitrary client-defined
source location parameters, such as page number, line number
and current column.

The whole parser is designed in an object-oriented way which allows extending
it easily in order to customize it to the client's specific needs.

=head1 OVERVIEW

C<BlockParser> is a simple to use but extraordinary powerful parser.

It is not a table-driven parser-generator such as yacc, though.

Instead, it supports a mode of operation where your application drives the
parsing process, and use the parser's methods to provide the parsing text
and backtrack where necessary.

Parsers based on C<BlockParser> are typically recursively descendent parsers.

Such parsers generally implement a top-down-approach to parsing, while
tools based on yacc generally support a bottom-up approach.

Both approaches, top-down and bottom-up have their advantages, but are
completely equivalent from a theoretical standpoint.

Top-down parsers are more naturally to read, write and understand from
a programmer's point of view, and the parser is typically written as part
of the application.

Bottom-up parsers typically have a table-driven design, and typically are
written as a hybrid of external syntax definition files and
application-specific codelets.

The advantage of top-down parsers is that you can conclude what it does
immediately from looking into your appliation's source files. Also, as
there are no external syntax definition files to be updated, there
are no pre-compilation steps required. It is all in the source code of
your parsing application.

The advantage of YACC and consorts, on the other hand, is the stricter
enforced separation from the syntax definition from the actual implementation
code. This makes it somewhat easier to document or modify the supported
syntax. Also, implementing operator precedence is a rather trivial task in
bottom-up parsers, but requires carefully constructing the syntax in top-down
parsers.

So both approaches have their advantages.

In my experience, top-down parsers are superior when rather simple tasks are
to be accomplished, such as parsing configuration files or importing
structured data from a text file.

In most situation, I prefer using C<BlockParser> instead of LEX for such
puposes.

C<BlockParser> is also more efficient then LEX, especially when parsing binary
data rather than text.

But even C<BlockParser> is even more efficient than LEX when parsing text
from memory buffers, because C<BlockParser> works non-destructively. No more
need to create copies of the parsing text because LEX wants to write markers
in there temporarily.

It is also more efficient regarding line numbers and error message reporting.

But perhaps the biggest advantage of C<BlockParser> is its unrestricted
capability to parse binary files as well as text files.

For instance, it would not be a problem to implement an ASN.1 or XML
parser based on C<BlockParser>.

C<BlockParser> processes data bytes, and it does not "assume" specific
chacteristics of the data it reads. More specifically, there will be no
problem processing ASCII NUL characters, or characters with bit 7 set,
or UTF-8/UTF-16 characters. It also makes no assumptions regarding the
interpretation of "white space" and linefeed or EOF characters - your
application retains full control over all these aspects.

C<BlockParser> works strictly binary: It processes bytes, not necessarily
characters. What a specific byte means to your application, is left to
decide by your application, not by C<BlockParser>.

=head1 CONCEPTS

C<BlockParser> supports parsing a stream of bytes from an arbitrary data
source in a top-down fashion.

Directly supported data sources include string variables and operating system
files, but by providing your own customized data provider class actually
any data source imaginable can be used.

A very important concept of C<BlockParser>, which greatly increases its
efficiency in comparison to other parsers, are its I<location tracker> objects.

Location tracker objects solve the problem of inefficiently tracking line-
and column numbers for reasons of error reporting.

The basic idea is that line numbers and similar context information are not
constantly required when parsing a typical text file. They are typically
only required when error messages or logging entries are about to be produced.

For that reason, C<BlockParser> splits the actual parsing and the tracking
of line numbers into two different tasks.

This works by maintaining some sort of I<co-parser>, which parses the
parsing text in parallel with the main parser, and looks for line feed
characters (or other separator characters of interest) in the text only.

This approach not only relieves the main parser of looking for line feed
characters and updating line numbers accordingly, but also allows this
task typically to be performed more efficiently.

In C<BlockParser>'s terminology, such a co-parser is referred to as a
"location tracker object".

The job of a such a location tracker is to scan the source data for
location boundaries, such as line feed characters, and update its
internal state accordingly.

For instance, the typical location tracker object used for parsing text files
will maintain a line and column number.

When C<BlockParser> requires to report the position for a specific
input character (typically for an error message), first calls the scan()
method of the location tracker object in order to parse the source text
before the error location.

The location tracker object will scan the source text and count any
line feed characters it encounters, thus determining the line number
of the error location.

Then, C<BlockParser> will call the report() method of the location
tracker object, which will then return a string representation of its
internal state, such as "line 58 column 2". This string will then be
incorporated within the actual error message.

The location tracker object is of course free to expose parts or all
of its internal information to your application by providing
appropriate attribute-access methods, such as C<get_line_number()>.

The location tracker approach is extremely powerful because it restricts
in no way what the location tracker object can do.

For instance, maybe your application would like to provide page numbers
and line numbers relative to the start of the current page instead of just
global line numbers.

Or it may require column and line numbers instead of just line numbers.

Or it may require reporting of absolute file offset byte positions instead
of any line number.

Or perhaps it needs no location information at all, because the text to
be parsed is so short.

With a customized location tracker object, you can do all of this.

Of course, C<BlockParser> already provides pre-canned location tracker objects
for all common applications, such as the typical line/column tracking in text
files. But you can as well easily create customized location trackers if you
ever should need them.

The other important concept in C<BlockParser> is that of a data provider
object.

The job of this object is to provide the parser's input data, and keep track
of the input data's current state.

For instance, in error messages it is often not enough to see in which line
or column an error occurred, but also in which file it did.

For that purpose, a data provider object may implement the (optional)
report() method.

When the parser has to generate an error message, this report() method
of the data provider - if available - will be called in order to obtain
a description of the current data source, such as the string
I<file 'test.txt'> which will then be included within the error message.

But basically, the job of a data provider object is to place at least 1
and at most a specified number of input data bytes into a given buffer
- or to report the end of the data stream.

This leaves the decision for a specific buffering strategy mostly up
to the data provider - it can easily implement a fully buffered mode
as well as a line-buffered or unbuffered mode.

But more importantly, a data provider can get its data from wherever
it wants. There is no need to restrict the parser's data sources to
operating system files.

A data provider could as well deliver data from internal buffers,
BSD sockets or from the output of other running processes. It even can
generate the required data algorithmically on demand. It's all possible.

Of course, there are also pre-canned data provider objects for all common
applications, such as reading text files or parsing the contents of a provided
string variable.

=head1 METHODS

=cut


our $DEFAULT_BUFFER_SIZE= 0x2000;


# Instance variables (hash key prefix is 'c9ef_'):
#
# $self->{c9ef_bp}: Index for next character of the current buffer.
# $self->{c9ef_bi}: Current buffer index (0 for the first buffer).
# $self->{c9ef_buf}: Array of buffers. 1 or 2 entries as required.
# $self->{c9ef_buf}->[$i]->{data}: Buffer contents.
# $self->{c9ef_buf}->[$i]->{end}: 1 higher than index of last valid character.
# $self->{c9ef_provider}: Data provider object.
# $self->{c9ef_tracker}:  Location tracker object of undef.


=head2 CONSTRUCTOR new

            use Lib::BlockParser_C9EFC171_DB26_11D8_9588_00A0C9EF1631;
            $parser= new Lib::BlockParser;

Constructs and returns a new C<BlockParser> object.

Also calls C<init>(), passing any supplied arguments to it.

If the parser needs additional custom parsing methods, it may be preferable
to derive a customized class from it before creating any objects.

See L<NOTES - OBJECT MODEL>.

=cut
sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->init(@_);
   $self;
}


=head2 METHOD init

            $parser->init(
               -data => new Lib::BlockParser::TextFile('source.txt')
               , -locator => new Lib::BlockParser::LineNumbers
            );

Initializes or resets the parser object and prepares it for parsing some
input text (or binary input data). See L<NOTES - Method init> for details.

=cut
sub init {
   my($self, %opt)= @_;
}


=head2 METHOD pos

            $old_pos= $parser->pos;

This returns an object that represents the current parsing position.
Use C<reset> to reset the current parsing position to that value later.

=cut
sub pos {
   my($self)= @_;
   $c;
}


=head2 METHOD reset

            sub try_parse_something {
               my $parser= shift;
               my $old_pos= $parser->pos;
               ...
               if ($succeeded) {return 1}
               else {
                  $parser->reset($old_pos);
                  return undef;
               }
            }

C<pos> and C<reset> are the basic functions for controlling the
parser's state.

When implementing a function that consumes some construct only if it can
parse the whole construct, call C<pos> first and save the returned value.

Then try to parse the construct.

When any part of the construct cannot be parsed, use C<reset> to reset
the current parsing position to where it was at the beginning of the
failed construct parsing attempt.

=cut
sub pos {
   my($self)= @_;
   $c;
}


=head2 METHOD try_get_char

            if (defined($c= $parser->try_get_char)) { ... }

Tries to parse the next character C<$c> off the text to be parsed.

Returns the C<undef> value at I<EOF (end of file)>.

=cut
sub try_get_char {
   my($self)= @_;
   $c;
}


=head2 METHOD unget

            my $c= $parser->try_get_char;
            $parser->unget;

Moves the current parsing position backwards by the specified number of
characters (1 by default).

This function must not be used to unget more characters then are available
from the current position back towards the beginning of the parsing text.

It is safer to use C<pos>/C<reset> when the exact number of characters to
unget is not known or depends on complex conditions.

C<unget> is typically used after C<try_get_char> returned a character
that terminates the current parsing construct but shall not be consumed,
because it is part of the following construct.

=cut
sub unget {
   my($self)= @_;
   $c;
}


{
   package LineNumbers;


   sub new {
      my $self= shift;
      $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
      @self{qw/current_line current_column/}= (1, 1);
      $self;
   }


   sub clone{
      ({%{shift()}});
   }


   sub scan {
      my($self, , $length, $offset)= @_;
      my($var, $end, $next, $current);
      $var= \$_[1]; # Use reference instead of local value copy.
      use constant LTERM => "\n";
      use constant LTERMLEN => length LTERM;
      $end= ($current= $offset) + $length;
      while (
         ($next= index($$var, LTERM, $current)) >= $current
         && $current < $e
      ) {
         ++$self->{current_line};
         $current= $next + LTERMLEN;
      }
      if ($current == $offset) {
         $self->{current_column}+= $length; # Still within same line.
      }
      else {
         # 1-based offset from start of last line.
         $self->{current_column}= 1 + ($end - $current);
      }
   }


   sub report {
      sprintf "line %u colum %u", @{shift()}{qw/current_line current_column/};
   }


   sub section {
      shift->{current_line};
   }
}


{
   package TextFile;
}


{
   package BinaryFile;
}


{
   package Stream;
}


1;


__END__


=head1 NOTES

=head2 NOTES - OBJECT MODEL

The parser basically uses two driver objects for obtaining its input data,
and provides several methods for parsing data off the current input position.
See L<EXAMPLE - Deriving a customized parser>.

In order to add additional parsing methods, derive a new customized
class from the C<Lib::BlockParser> class.

In order to specify the data to be parsed, pass an instance of a data provider
object to the parser's C<init> method (or to its C<CONSTRUCTOR>).

If you want more specific source location information than just plain character
offsets to be present in error messages, pass an instance of an appropriate
location tracking object to the parser's C<init> method (or to its
C<CONSTRUCTOR>).

Regarding instantiation, the parser class is pure and reentrant. All its
internal state is stored per instance. Thus it is not a problem to instantiate
many parallel parsers at the same time and use them independently.

=head2 NOTES - Method init

The following key/value options are supported:

=over 4

=item -data => $data_provider

Specify a data provider object. This may be either a user-defined object, or an
instance of a pre-defined class such as C<Lib::BlockParser::TextFile>.

In both cases, the object will be used to feed the data to be parsed to the
parser. See also L<NOTES - Data Provider Object Methods>.

If no data provider object is provided for the parser, then it cannot
actually parse anything.

=item -data => [\$variable, $length, $offset]

When providing a list reference instead of a data provider object, a special
processing mode is selected.

In this mode, the parser does not use any internal buffers for parsing,
but directly uses the contents of the specified variable as the data source.

Note that the parts of that variable that contain the parsing data are
assumed not to change during the parse, or strange things may happen.

Specifying C<$length> and offset C<$offset> is optional. When none of both
is specified, the whole contents of the variable are parsed.

When C<$length> is specified, parsing starts at position C<$offset> and
only C<$length> characters are parsed before a logical EOF is assumed.
A negative length is counted backwards from the end of the string.

A negative C<$offset> is counted backwards from the end of the string.

If C<$offset> is not specified, 0 is assumed if C<$length> has not been
specified or is positive.

For negative C<$lenght>, the same value is used as the default for <$offset>.

=item -data => $text_variable

This is a shortcut for specifying C<-data => [$text_variable]>.
C<$text_variable> must be a plain string variable (or string expression); it
will not work if C<$text_variable> happens to be a blessed ('object') variable.

Use this shortcut format to parse the complete contents of a variable or
string expression.

=item -locator => $location_tracker

Specify a location tracking object. This may be either a user-defined object,
or an instance of a pre-defined class such as C<Lib::BlockParser::LineNumbers>.

In both cases, the object will be used to track locations within the source
text in terms of whatever the object implementor wants.
See also L<NOTES - Location Tracker Object Methods>.

For instance, it may track which line numbers are associated with which parts
of the source file.

If no location tracking object is provided for the parser, then no location
specifications will be displayed when displaying error messages.

=item -buffer_size => $character_count

Specifies the maximum buffer size for each of the dual block buffers maintained
by the BlockParser object internally.

The buffer size is specified as a character count and also represents the
minumum guaranteed amount of backtracking that is available for parsing.

The maximum amount of backtracking may be up to twice the minimum amount.

When not specified, a reasonable default value will be used that allows
backtracking up to several kilobytes of source text and will most likely
outperform the amount of backtracking provided by yacc and similar tools.

So there is only a point in using this option when more specific control
over buffer space consumption is required, such as when using a very large
number of parser instances simulataneously in parallel.

=back

=head2 NOTES - Data Provider Object Methods

The following methods of the data provider object are used by the parser:

=over 4

=item read (mandatory method)

            sub read {
               my($self, , $length, $offset)= @_;
               my $var= \$_[1]; # Use reference instead of local value copy.
               ...
               substr($$var, $offset, $length)= $data;
            }

When called, this function must place up to C<$length> characters into
String C<$var> starting at offset C<$offset>.

Note that the arguments are actually identical to Perl's built-in C<read>
function.

The function can return any number of characters up to that length, but
a minimum of 1 character is required unless the current position is the
end of the input stream. In the latter case, 0 must be returned.

=item report (optional method)

            sub report {
               my $self= shift;
               qq'file "$self->{filename}"';
            }

Return the name or description of the current data source as a text string
suitable for inclusion into an error message.

For instance, a data provider object reading from a file with the name
'test.txt' may return implement a C<report> method that returns the string
'file "name.txt"'.

Without this method, the parser will not include any data source specification
into its error messages.

=back

=head2 NOTES - Location Tracker Object Methods

The following methods of the data provider object are used by the parser:

=over 4

=item clone (mandatory method)

            sub new {
               my $self= shift;
               $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
               $self->{current_line}= 1;
               $self->{current_column}= 1;
               $self;
            }

            sub clone {
               ({%{shift()}});
            }

This method must construct and return a functionally identical but independent
copy of the current object instance.

It will be used by methods that need to create a snapshot of the current
parsing location.

=item scan (mandatory method)


            sub scan {
               my($self, , $length, $offset)= @_;
               my($var, $end, $next, $current);
               $var= \$_[1]; # Use reference instead of local value copy.
               use constant LTERM => "\n";
               use constant LTERMLEN => length LTERM;
               $end= ($current= $offset) + $length;
               while (
                  ($next= index($$var, LTERM, $current)) >= $current
                  && $current < $e
               ) {
                  ++$self->{current_line};
                  $current= $next + LTERMLEN;
               }
               if ($current == $offset) {
                  $self->{current_column}+= $length; # Still within same line.
               }
               else {
                  # 1-based offset from start of last line.
                  $self->{current_column}= 1 + ($end - $current);
               }
            }

This method receives a text segment to scan over. That is, it should update its
internal state, assuming the old state referred to the first character before
the text segment, and the new position has to be the next character after the
text segment.

=item report (optional method)

            sub report {
               my $self= shift;
               sprintf "line %u colum %u"
               , $self->{current_line}, $self->{current_column}
               ;
            }

This method should return the current position in a string suitable for
inclusion into an error message, such as "line 24 colum 79".

=item section (optional method)

            sub section {
               my $self= shift;
               $self->{current_line};
            }

This method must return any numeric value, but it must change as soon as a
"natural section" boundary for error context reporting has been crossed.

For instance, section() could return the current line number. When context
information will be displayed in an error message, the context will start and
end at a line boundary if possible.

If not provided, context reporting will not be aligned to anything - the
context dump may start somewhere within a line.

=back

=head2 NOTES - Buffering modes

=over 4

The parser will call the data provider as soon as it reaches the end of the
data read so far. The data provider should read as much as he can for
efficiency purposes (up to the number of characters specified by the parser),
but it is not required to do so.

The C<read> method of the data provider object is free to return any
number of characters, but at least one character and at most the
specified number of characters.

This can be used to implement at least the following types of data providers:

=item Fully buffered mode

In this mode, the read() function tries to actually read the requested number
of characters. This is the most efficient mode and should be used whenever
possible.

For instance, when reading a file, Perl's built-in C<read>() function could
be used for this purpose.

Note, however, that Perl's C<read> may return 0 bytes at any time, not only
at EOF. The data provider's read function must return 0 only at EOF.

Also, Perl's C<read> function will return C<undef> in case of an error.

The data provider's C<read> function must throw any error in this case,
i. e. it must die() or croak().

=item Line buffer mode

In this mode, the data provider only returns data until the next linefeed
character is encountered. This is typically the case when text files are
read using the C<<filehandle>> operator.

Use this mode if you are reading files using Perl's built-in I/O-operators,
but be prepared that the requested number of characters may be shorter
than the actual line contents. In this case, the remainder of the line
must be stored within the object until C<read> is called the next time.

This mode is typically used when parsing data from interactive sources such
as the keyboard, or from shared files that are updated on a per-line basis.

=item Unbuffered mode

In this mode, the data provider always returns the next character, but not
more.

This mode is most useful when parsing data directly from the keyboard, without
a line edit mode in effect (which would return the whole completed line only).

It may also be useful for data sources that require instant reaction by the
parser whenever a new character arrives.

This mode has the largest overhead and is thus the most inefficient.

=item Variable blocking mode

This typically means that the actual number of characters returned depends
on the blocking behavior of the data source itself.

For instance, when reading data that arrives in datagram blocks, the next
datagram (or its C<$length> first characters) may be returned. This allows
immediate handling of each datagram as it arrives.

=back

=head2 EXAMPLE - Deriving a customized parser

            The following example will derive a custom parser from C<Lib::BlockParser>
            which provides additional parsing functions.

            Then this derived parser will be used to parse some text.

            use strict;
            use Lib::BlockParser_C9EFC171_DB26_11D8_9588_00A0C9EF1631;

            {
               package FloatParser;
               use base qw(Lib::BlockParser);

               sub new {
                  my $self= shift;
                  # Create instance unless passed from constructor of a derived class.
                  $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
                  # Initialize base class.
                  $self->Lib::BlockParser::new(@_);
                  $self;
               }

               sub parse_sign {
                  my $self= shift;
                  my $c= $self->try_parse_char;
                  return $c if defined($c) && $c =~ /[-+]/;
                  $self->unget;
                  '+';
               }

               sub try_parse_float {
                  my $self= shift;
                  my $old= $self->pos;
                  my($sign, $int, $fract, $esign, $exp);
                  $sign= $self->parse_sign;
                  if (defined $int= $self->parse_unsigned) {
                     if ($self->try_parse_string('.')) {
                        $fract= try_parse_unsigned;
                     }
                  }
                  elsif ($self->try_parse_string('.')) {
                     $int= 0;
                     $fract= try_parse_unsigned;
                  }
                  $fract= 0 unless defined $fract;
                  if (defined $int) {
                  }
                  $self->reset($old);
                  undef;
               }
            }

            my $p= new FloatParser(-data => '-14.07e+23');
            my $f= $p->try_parse_float;
            if (defined $f) {
               print "floating point number parsed: %f", $f;
            }
            else {
               print "error: not a valid floating point number!"
            }

=head1 AUTHOR

Guenther Brunthaler
