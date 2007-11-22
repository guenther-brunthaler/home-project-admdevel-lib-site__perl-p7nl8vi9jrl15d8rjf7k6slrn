# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib::XSA;
our $VERSION= '1.0';


use Carp;
use Lib::StringConv_8AEE1C21_CBA0_11D5_9920_C23CC971FBD2;


=head1 NAME

Lib::XSA - Class for XSA processing.

=head1 DESCRIPTION

XSA is an acronym for 'E[x]ternal [S]ource File [A]ccess'.

It defines a common way how to include marks and sections of text
in source files to be processed and/or updated by external tool programs.

=head1 METHODS

=cut


# Class data structure:
#
# $self: An instance of the XSA class.
# $self->{IN} == $INPUT_FILE_HANDLE_REFERENCE;
# $self->{OUT} == $OUTPUT_FILE_HANDLE_REFERENCE
# $self->{line} == $NEXT_LINE_NUMBER
# $self->{col} == $NEXT_COLUMN_INDEX
# $self->{buf} == (undef || $LINE_BUFFER);
# $self->{read_luids}->{$SHORTCUT} == $GUID: Maps INPUT shortcuts to GUIDs
# $self->{write_luids}->{$SHORTCUT} undef: This OUTPUT shortcut is in use
# $self->{write_luids}->{$SHORTCUT} == $GUID: Preferred shortcut awaiting usage
# $self->{guids}->{$GUID} == ($OUTPUT_SHORTCUT || undef): All encountered GUIDs
# $self->{filters}->{$GUID} exist: GUID is supported
# $self->{filters}->{$GUID}->{preferred_luid}: preferred shortcut, if any
# $self->{filters}->{$GUID}->{cmds}->{$COMMAND} == $ARGMODE
# $self->{guid}: GUID if specified in mark
# $self->{luid}: Shortcut if specified in mark
# $self->{params}: Raw XSA-argument string
# $self->{command}: Command keyword from $self->{params}.
# $self->{argument}: Command argument from $self->{params}.
# $self->{new_guid} defined: GUID has been used for the first time.
# $self->{new_luid} defined: Shortcut has been defined in current mark.


=head2 CONSTRUCTOR new

            use Lib::XSA_8AEE1C25_CBA0_11D5_9920_C23CC971FBD2;
            $xsa= new Lib::XSA;

Constructs and returns a new XSA object.

=cut
sub new {
   my($class)= shift;
   my $self= {};
   bless $self, ref $class || $class;
   $self->{line}= 1;
   $self;
}


=head2 METHOD set

Sets properties of the XSA object, specified as a list of key/value pairs.

=cut
sub set {
   my $self= shift;
   my($key, $value);
   while ($key= shift) {
      $value= shift;
      if ($key eq '-in') {
         $self->{IN}= $value;
         $self->{buf}= undef;
      }
      elsif ($key eq '-out') {
         $self->{OUT}= $value;
      }
      elsif ($key eq '-line') {
         $self->{line}= $value;
      }
      elsif ($key eq '-filter') {
         my($g, $filter, $fs, $pt);
         $filter= $value;
         $self->{filters}= {};
         $self->{read_luids}= {};
         $self->{write_luids}= {};
         foreach $fs (@$filter) {
            if (substr($fs, -1) eq '}') {
               unless ($fs =~ /^\s*(?:(\d+)\s*=\s*)?({.+})\s*$/) {
                  croak "Invalid filter GUID specification";
               }
               $g= Lib::StringConv::Str2GUID($2);
               unless (exists $self->{filters}->{$g}) {
                  $self->{filters}->{$g}= {
                     cmds => {}
                  }
               }
               if (defined $1) {
                  # Preferred shortcut has been specified.
                  $self->{filters}->{$g}->{preferred_luid}= $1;
                  $self->{write_luids}->{$1}= $g;
               }
               $g= $self->{filters}->{$g}->{cmds};
            }
            else {
               die unless $fs =~ s/(=(\?)?)?$//;
               $pt= defined($1) ? defined($2) ? 1 : 2 : 0;
               croak 'missing GUID' unless defined $g;
               $g->{$fs}= $pt;
            }
         }
      }
      else {
         croak "Unrecognized key '$key' in binding operation";
      }
   }
}


=head2 METHOD raise_error

Dies with an error message constructed from the passed message text,
the current line and column numbers (if any) and a dump of the input
text that triggered the error.

=cut
sub raise_error {
   my($self, $msg)= @_;
   my($es);
   $es= 'An error has been detected when processing an XSA-statement';
   if (defined $self->{buf}) {
      $es.= ' at column ' . ($self->{col} + 1);
      if (defined $self->{line}) {
         $es.= ' in line ' . ($self->{line} - 1) . ' of the input file';
      }
      else {
         $es.= ' in a buffer'
      }
   }
   if (defined $self->{buf}) {
      $es.= " with the following contents:\n<BEGIN>";
      $es.= Lib::StringConv::DumpString(
         substr $self->{buf}, 0, $self->{col}
      ) . '<ERROR>';
      $es.= Lib::StringConv::DumpString(
         substr $self->{buf}, $self->{col}
      ) . '<END>';
      $es.= "\nThe problem";
   }
   die unless $msg =~ s/^(.?)(.*?)[!.?]?$/\u$1$2/;
   $es.= ': ' . $msg;
   croak $es;
}


=head2 METHOD read

Read next line or next string within a line separated by XSA-marks.
Does not do any semantic validations in case of an XSA-mark,
only the correct syntax is checked.

=cut
sub read {
   my($self)= @_;
   if (!defined($self->{buf}) || $self->{col} >= length($self->{buf})) {
      # Fetch new a line.
      my($fh);
      return undef unless defined($fh= $self->{IN});
      return undef unless defined($self->{buf}= <$fh>);
      ++$self->{line} if defined $self->{line};
      $self->{col}= 0;
   }
   undef $self->{guid};
   undef $self->{luid};
   undef $self->{params};
   undef $self->{text_i};
   undef $self->{text};
   # Locate XSA-mark.
   my($i, $ms);
   $i= $self->{col};
   if ($i) {
      # Match next item in line.
      my $ss= substr($self->{buf}, $i);
      $ms= \$ss;
   }
   else {
      # Match complete line.
      $ms= \$self->{buf};
   }
   if (
      $$ms =~ m<
         # XSA opening tag.
         \$xsa
         # Signature start.
         \s*
         # UUID, shortcut or both (define alias).
         (?:
            # Shortcut $1 and UUID $2.
            ([1-9]\d*)\s*=\s*(
               {(?i:[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})}
            )
            # Shortcut only $3.
            |([1-9]\d*)
            # UUID only $4.
            |({(?i:[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})})
         )
         # Optional mark data $5.
         ([^\$]*)
         # Closing tag.
         \$
      >ox
   ) {
      if (length($`) == 0) {
         # XSA-mark.
         ($self->{luid}, $self->{guid})= ($1, $2) if defined $1;
         $self->{luid}= $3 if defined $3;
         $self->{guid}= $4 if defined $4;
         $self->{params}= $5 if defined $5;
         $self->{col}= $i + length($&);
         if (defined $self->{guid}) {
            $self->{guid}= Lib::StringConv::Str2GUID($self->{guid});
         }
      }
      else {
         # Text preceding XSA-mark.
         $self->{text_i}= $i;
         $self->{col}= $i + length($`);
      }
   }
   else {
      # Text only.
      $self->{text_i}= $i;
      $self->{col}= length($self->{buf});
   }
   1;
}


=head2 METHOD mark_follows

Returns C<1> if the current item will be followed by an XSA-mark
on the same line, or C<undef> otherwise.

This will only work if the current item is text and not a mark.

=cut
sub mark_follows {
   my($self)= @_;
   $self->{col} < length($self->{buf});
}


=head2 METHOD get_text

Returns the contents of the current item that has been obtained
with the last C<read>.

This will only work if the current item is I<not> an XSA-mark.

=cut
sub get_text {
   my($self)= @_;
   return $self->{text} if defined $self->{text};
   return undef unless defined $self->{text_i};
   $self->{text}
   = substr($self->{buf}, $self->{text_i}, $self->{col} - $self->{text_i})
   ;
}


=head2 METHOD get_shortcut

Returns the shortcut of the current item or C<undef> if there
is no shortcut currently associated with the XSA-statement.

=cut
sub get_shortcut {
   my($self)= @_;
   $self->{luid};
}


=head2 METHOD get_guid

Returns the guid of the current item.

=cut
sub get_guid {
   my($self)= @_;
   Lib::StringConv::GUID2Str($self->{guid});
}


=head2 METHOD get_parameters

Returns the parameters of the current item.

This includes any leading or trailing spaces, and commands are not
separated from arguments.

=cut
sub get_parameters {
   my($self)= @_;
   $self->{params};
}


=head2 METHOD set_text

Changes the type of the current item to I<normal text> and sets the text
contents.

=cut
sub set_text {
   my($self, $text)= @_;
   undef $self->{guid};
   undef $self->{luid};
   undef $self->{params};
   undef $self->{text_i};
   $self->{text}= $text;
}


=head2 METHOD set_shortcut

Changes the type of the current item to I<XSA mark> and sets the shortcut.

=cut
sub set_shortcut {
   my($self, $shortcut)= @_;
   undef $self->{text_i};
   undef $self->{text};
   $self->{luid}= $shortcut;
}


=head2 METHOD set_guid

Changes the type of the current item to I<XSA mark> and sets the GUID.

=cut
sub set_guid {
   my($self, $guid)= @_;
   $guid= Lib::StringConv::Str2GUID($guid);
   undef $self->{text_i};
   undef $self->{text};
   $self->{guid}= $guid;
}


=head2 METHOD set_parameters

Changes the type of the current item to I<XSA mark> and sets the optional
XSA-parameters, including any leading or trailing whitespace.

=cut
sub set_parameters {
   my($self, $parameters)= @_;
   if ($parameters =~ /\$\n/) {
      croak "'$' and newline not allowed in XSA parameters!";
   }
   undef $self->{text_i};
   undef $self->{text};
   $self->{params}= $parameters;
}


=head2 METHOD is_mark

Determines whether the current item is a syntacticly correct XSA mark.

This does not necessarily mean that the mark is semantically correct
or that it is a supported mark.

=cut
sub is_mark {
   my($self)= @_;
   not defined $self->{text_i} || defined $self->{text};
}


=head2 METHOD write

Writes the current XSA item out to the associated output file.

If no output file has been bound to the XSA object, the string to be
written is returned instead.

This behaviour can also be enforced by passing the value C<1> as
optional argument.

=cut
sub write {
   my($self, $doret)= @_;
   $doret= 1 unless defined $self->{OUT};
   if ($self->is_mark) {
      if (exists $self->{filters}) {
         if (defined $self->{guid} && !exists $self->{guids}->{$self->{guid}}) {
            # A new GUID has been added.
            $self->{guids}->{$self->{guid}}= undef;
         }
         if (defined $self->{luid}) {
            # A shortcut has been specified.
            unless (exists $self->{write_luids}->{$self->{luid}}) {
               # A new shortcut has been added.
               $self->{write_luids}->{$self->{luid}}= undef;
            }
         }
      }
      # Compose XSA mark.
      my($tag);
      $tag = '$xsa';
      $tag.= $self->{luid} if defined $self->{luid};
      $tag.= '=' if defined($self->{luid}) && defined($self->{guid});
      $tag.= $self->get_guid if defined $self->get_guid;
      $tag.= $self->{params} . '$';
      return $tag if $doret;
      my $fh= $self->{OUT};
      print $fh $tag;
   }
   else {
      # Text item.
      return $self->get_text if $doret;
      my $fh= $self->{OUT};
      print $fh $self->get_text;
   }
}


=head2 METHOD filtered_transport_mark

Returns the command keyword of a supported XSA mark as
C<filtered_mark> does, but also replaces any shortcuts
by their associated GUIDs.

The resulting output can be merged with any other source file
without a danger of shortcut collisions.

=cut
sub filtered_transport_mark {
   my($self)= @_;
   return undef unless $self->is_mark;
   my $cmd= $self->filtered_mark;
   $self->enforce_guid;
   $self->set_shortcut;
   $cmd;
}


=head2 METHOD filtered_update_mark

Returns the command keyword of a supported XSA mark as
C<filtered_mark> does, but replaces the shortcuts as
necessary to compensate for new GUID definitions that
may have been added.

Use this rather than C<filtered_mark> when additional
XSA marks will be added to the output file.

=cut
sub filtered_update_mark {
   my($self)= @_;
   my($cmd);
   return undef unless $self->is_mark;
   $cmd= $self->filtered_mark;
   if ($self->is_new_guid) {
      if ($self->get_shortcut) {
         # Change shortcut definition.
         $self->define_shortcut_current_or_preferred_or_automatic;
      }
   }
   elsif ($self->get_defined_shortcut) {
      $self->set_defined_shortcut;
   }
   $cmd;
}


=head2 METHOD new_update_mark

Creates a new mark based on the current GUID.
If the current mark is the first one using the GUID, an appropriate
shortcut will automatically defined.

Later invocations will then only reference the GUID using that shortcut.

=cut
sub new_update_mark {
   my($self)= @_;
   $self->enforce_guid;
   my $g= $self->get_guid;
   $self->new_mark;
   $self->set_guid($g);
   if ($self->get_defined_shortcut) {
      $self->set_defined_shortcut;
      $self->set_guid;
   }
   else {
      $self->define_shortcut_preferred_or_automatic;
   }
}


=head2 METHOD guid_known

Returns C<1> if the current GUID - if any - has already been encountered
while reading the input. This is always true for GUIDs that have
just been read. You may only use this function in filter mode.

Returns C<undef> otherwise.

=cut
sub guid_known {
   my($self)= @_;
   defined $self->{guid} && exists $self->{guids}->{$self->{guid}};
}


=head2 METHOD get_defined_shortcut

Returns the shortcut (for output) that has been associated with
the effective GUID of the current XSA mark.

Returns C<undef> if no shortcut has been associated yet.

=cut
sub get_defined_shortcut {
   my($self)= @_;
   my $g;
   $g= $self->lookup_guid unless defined($g= $self->{guid});
   $self->{guids}->{$g};
}


=head2 METHOD lookup_guid

Returns the GUID associated with the current shortcut.
The association must exist and is based on the shortcut definitions
of the input source, not on that of the output.

=cut
sub lookup_guid {
   my($self)= @_;
   unless (exists $self->{filters}) {
      croak "Operation supported only in filter mode";
   }
   croak "Undefined shortcut" unless defined $self->{luid};
   unless (exists $self->{read_luids}->{$self->{luid}}) {
      croak "Cannot look up undefined XSA shortcut " . $self->{luid};
   }
   $self->{read_luids}->{$self->{luid}};
}


=head2 METHOD enforce_guid

Looks up the GUID if only a shortcut has been specified
and sets it into the current XSA mark.

=cut
sub enforce_guid {
   my($self)= @_;
   $self->{guid}= $self->lookup_guid unless defined $self->{guid};
}


=head2 METHOD define_shortcut_preferred_or_current_or_automatic

Associates the current GUID with a new shortcut
and sets it as the shortcut for the current XSA mark.
If a preferred shortcut exists for the GUID, then that is used.
If a shortcut is currently set, then that is used.
Otherwise, an appropriate shortcut is created automatically.

=cut
sub define_shortcut_preferred_or_current_or_automatic {
   my($self)= @_;
   my($sc);
   $self->enforce_guid;
   if (
      exists $self->{filters}->{$self->{guid}}
      && ($sc= $self->{filters}->{$self->{guid}}->{preferred_luid})
   ) {
      return if $self->define_shortcut($sc);
   }
   if ($sc= $self->{luid}) {
      return if $self->define_shortcut($sc);
   }
   $self->define_shortcut_automatic;
}


=head2 METHOD define_shortcut_current_or_preferred_or_automatic

Associates the current GUID with a new shortcut
and sets it as the shortcut for the current XSA mark.
If a shortcut is currently set, then that is used.
If a preferred shortcut exists for the GUID, then that is used.
Otherwise, an appropriate shortcut is created automatically.

=cut
sub define_shortcut_current_or_preferred_or_automatic {
   my($self)= @_;
   my($sc);
   $self->enforce_guid;
   if ($sc= $self->{luid}) {
      return if $self->define_shortcut($sc);
   }
   $self->define_shortcut_preferred_or_automatic;
}


=head2 METHOD define_shortcut_preferred_or_automatic

Associates the current GUID with a new shortcut
and sets it as the shortcut for the current XSA mark.
If a preferred shortcut exists for the GUID, then that is used.
Otherwise, an appropriate shortcut is created automatically.

=cut
sub define_shortcut_preferred_or_automatic {
   my($self)= @_;
   my($sc);
   $self->enforce_guid;
   if (
      exists $self->{filters}->{$self->{guid}}
      && ($sc= $self->{filters}->{$self->{guid}}->{preferred_luid})
   ) {
      return if $self->define_shortcut($sc);
   }
   $self->define_shortcut_automatic;
}


=head2 METHOD define_shortcut_automatic

Associates the current GUID with a new appropriate automatically generated
shortcut and sets it as the shortcut for the current XSA mark.

=cut
sub define_shortcut_automatic {
   my($self)= @_;
   my $sc= 1;
   ++$sc while exists $self->{write_luids}->{$sc};
   die unless $self->define_shortcut($sc);
}


=head2 METHOD define_shortcut

Associates the current GUID with the specified positive integer as a
shortcut and also sets it as the shortcut for the current XSA mark.

If no GUID is currently set, it will be looked up before.

Returns the shortcut if the shortcut has successfully been associated,
or C<undef> if the shortcut is already in use.

IMPORTANT: Note the difference between C<set_shortcut> and C<define_shortcut> -
C<set_shortcut> is use to set an already-defined shortcurt, while
C<defined_shortcut> defines a new, unique shortcut.

=cut
sub define_shortcut {
   my($self, $sc)= @_;
   $self->enforce_guid;
   if (
      exists $self->{write_luids}->{$sc}
      && $self->{write_luids}->{$sc} eq $self->{guid}
   ) {
      delete $self->{write_luids}->{$sc};
   }
   return undef if exists $self->{write_luids}->{$sc};
   $self->{write_luids}->{$sc}= undef;
   $self->{guids}->{$self->{guid}}= $sc;
   $self->{luid}= $sc;
}


=head2 METHOD set_defined_shortcut

Sets the shortcut that has previously been defined for the GUID of the
current XSA mark as its shortcut and clears the GUID.

Before that, this method performs an internal lookup in order to
locate the associated GUID of the current mark if necessary.

=cut
sub set_defined_shortcut {
   my($self)= @_;
   my($g);
   $g= $self->lookup_guid unless defined($g= $self->{guid});
   unless (defined $self->{guids}->{$g}) {
      $self->raise_error(
         'No shortcut has been associated with effective GUID '
         . Lib::StringConv::GUID2Str($g)
      );
   }
   $self->set_shortcut($self->{guids}->{$g});
   $self->set_guid;
}


=head2 METHOD filtered_mark

Checks whether the current item is a supported XSA-mark.

Returns C<undef> if not.

Otherwise, the command keyword is returned, possibly including an empty
string if such an empty keyword has been defined as a valid command.

IMPORTANT: This function also does standard shortcut processing even
on unsupported marks internally. That means, it remembers any shortcut
definitions that are encountered internally and prepares later GUID/LUID
lookups.

You MUST use this function rather or one of its relatives
C<filtered_update_mark> and C<filtered_transport_mark> if you
want to set, change or lookup shortcuts!

=cut
sub filtered_mark {
   my($self)= @_;
   my($g, $sc)= ($self->{guid}, $self->{luid});
   undef $self->{command};
   undef $self->{argument};
   undef $self->{new_guid};
   undef $self->{new_luid};
   if (exists $self->{filters} && $self->is_mark) {
      # It's an XSA mark and filtering is active.
      if (defined $g) {
         # GUID with or without a shortcut.
         unless (exists $self->{guids}->{$g}) {
            # A new GUID has been encountered.
            $self->{new_guid}= 1;
            $self->{guids}->{$g}= undef;
         }
         if (defined $sc) {
            # GUID and Shortcut. Shortcut definition.
            if (exists $self->{read_luids}->{$sc}) {
               # Shortcut definition already exists.
               $self->raise_error(
                  "XSA-shortcut $sc has already been defined for GUID "
                  . Lib::StringConv::GUID2Str($self->{read_luids}->{$sc})
               );
            }
            # Shortcut definition does not yet exist.
            $self->{new_luid}= 1;
            # Create association from shortcut to GUID.
            $self->{read_luids}->{$sc}= $g;
         }
      }
      elsif (defined $sc) {
         # Shortcut without GUID. Shortcut lookup.
         unless (exists $self->{read_luids}->{$sc}) {
            # Shortcut has not yet been defined.
            $self->raise_error("undefined XSA-shortcut $sc encountered");
         }
         # Shortcut definition exists.
         $g= $self->{read_luids}->{$sc};
      }
      else {
         # Impossible: Neither GUID nor shortcut. Pattern should not have matched.
         die;
      }
      # GUID and optional shortcut are ok, check parameters.
      if (exists $self->{filters}->{$g}) {
         # Supported GUID.
         my($p);
         $p= $self->{params};
         $p= '' unless defined $p;
         # Remove colon and leading/trailing whitespace.
         $p =~ s<
            ^\s*
            (?:
               \:\s*
               (.+?)
            )?
            \s*$
         ><$1>x;
         # Extract any assignment value and isolate keyword.
         $self->{argument}= $2 if $p =~ s/^([^=]*)\s*(?:=\s*(.*))$/$1/;
         if (exists $self->{filters}->{$g}->{cmds}->{$p}) {
            # Supported command.
            if (defined $self->{argument}) {
               # Argument has been specified.
               if ($self->{filters}->{$g}->{cmds}->{$p} == 0) {
                  $self->raise_error(
                     "command '$p' of GUID " . Lib::StringConv::GUID2Str($g)
                     . " does not allow argument '$self->{argument}'"
                  );
               }
            }
            else {
               # No argument has been specified.
               if ($self->{filters}->{$g}->{cmds}->{$p} == 2) {
                  $self->raise_error(
                     "missing required argument for command '$p' of GUID "
                     . Lib::StringConv::GUID2Str($g)
                  );
               }
            }
            $self->{command}= $p;
         }
         else {
            # Unsupported command.
            my($c, $first);
            $first= 1;
            $p= "usupported command '" . $p . "' for GUID "
            . Lib::StringConv::GUID2Str($g) . ": must be one of ("
            ;
            foreach $c (keys %{$self->{filters}->{$g}->{cmds}}) {
               if ($first) {
                  undef $first;
               }
               else {
                  $p.= ', ';
               }
               $p.= "'" . $c . "'";
            }
            $self->raise_error($p . ')');
         }
      }
   }
   # Return command keyword, if any.
   $self->{command};
}


=head2 METHOD require_command

Verifies that the current command keyword of an XSA-mark is
the same as the specified argument.

Otherwise an appropriate error is raised.

=cut
sub require_command {
   my($self, $req_cmd)= @_;
   if ($self->{command} ne $req_cmd) {
      $self->raise_error(
         "command '$req_cmd' was expected, "
         . "but command '$self->{command}' has been found instead"
      );
   }
}


=head2 METHOD is_new_guid

Determines whether the GUID has been used for the first time
in this statement.

=cut
sub is_new_guid {
   my($self)= @_;
   $self->{new_guid};
}


=head2 METHOD is_new_shortcut

Determines whether the shortcut has been defined in this statement.

=cut
sub is_new_shortcut {
   my($self)= @_;
   $self->{new_luid};
}


=head2 METHOD set_cmd_arg

Sets the argument associated with the command of the current XSA-mark.

=cut
sub set_cmd_arg {
   my($self, $cmd, $arg)= @_;
   croak "invalid command keyword" unless $cmd =~ s/\s*(.*?)\s*/$1/;
   $cmd= ':' . $cmd if $cmd gt '';
   if (defined $arg) {
      $arg =~ s/\s*(.*?)\s*/$1/;
      $cmd.= '=' . $arg;
   }
   $self->{argument}= $arg;
   $self->set_parameters($cmd);
}


=head2 METHOD get_cmd_arg

Returns the argument associated with the command of the current XSA-mark.

=cut
sub get_cmd_arg {
   my($self)= @_;
   $self->{argument};
}


=head2 METHOD new_mark

Clears all settings of the current item so that properties for a new
XSA-mark can be set without a need to clear any unused properties.

=cut
sub new_mark {
   my($self)= @_;
   undef $self->{text_i};
   undef $self->{text};
   undef $self->{guid};
   undef $self->{luid};
   undef $self->{params};
   undef $self->{text_i};
   undef $self->{argument};
   undef $self->{command};
}


1;


__END__


=head1 NOTES

=head2 NOTES - CONSTRUCTOR new

C<new> creates a new XSA object.

            $xsa= new XSA;

The new() method of the XSA class creates an XSA object
that is not yet bound to any file.

=head2 NOTES - METHOD set

C<set> sets or unsets an XSA object's properties.

            $xsa= new XSA;
            open IN, '<infile';
            open OUT, '>outfile';
            $xsa->set(-in => *IN{FILEHANDLE}, -out => *OUT{FILEHANDLE});
            ...
            close OUT;
            close IN;

The C<set> arguments are actually a list with optional entries of the form

   key => value

where each I<key, value>-pair has its own meaning depending on I<key>.

The list entries are processed in the same order as they have been specified.

=over 4

=item key C<-in>/C<-out>

Binds a file to the XSA object to be used in input/output operations.

=item key C<-in>

Binds the input file.

=item key C<-out>

Binds the output file.

=item key C<-in>/C<-out> value I<filehandle>

Specifies a reference to the file handle to be bound.

If the file handle has the name 'FOO', then use '*FOO{FILEHANDLE}'
as the argument in order to obtain a reference to it.

=item key C<-line>

Sets the number of the next line for the input source.

=item key C<-line> value I<integer>

I<integer> is the line number of the next line to be read.

This property will have been preset to 1 when the object is created.

=item key C<-line> value C<undef>

Specifies that no line numbers should be used.

=item key C<-filter>

This activates the XSA B<filter mode>.

=item key C<-filter> I<value list>

The argument of C<-filter> is an anonymous list of options
explained below. A syntax similar to the following example should be used:

            $xsa->set(
               -filter => [
                  '{8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}',
                  'title=?',
                  'end',
                  '10={85FE2343-F327-11D4-97BF-0050BACC8FE1}',
                  'insertion mark='
               ]
            );

When the C<-filter> property has been set, XSA switches to I<filter mode>.

In this mode, GUIDs and shortcuts are automatically processed due to the XSA
specification, and errors such as duplicate or missing definitions will
automatically be reported.

In order to use that functionality, C<filtered_mark> should be used instead
of C<is_mark> which is different in the way that the former method supports
filters where the latter one does not.

=item key C<-filter> I<value list> entry type I<GUID>

Each argument list entry that ends on '}' specifies a GUID that is
actually processed by the current parser.

The GUID can optionally be prefixed by 'I<integer>C<=>' which defines
a I<preferred> shortcut for that GUID.

Following this GUID definition, the recognized command keywords follow.

If no command is specified, then each XSA-mark with that GUID will produce
an error.

If the the I<empty command> should be supported, an empty string must be
defined as one of the command keywords.

Filtered XSA-statements always have one of the following forms:

            $xsa7$
            $xsa7=$
            $xsa7=argument$
            $xsa7:command$
            $xsa7:command=$
            $xsa7:command=argument$

The C<7> here is just a placeholder for any allowed GUID/shortcut combination
as allowed in the XSA-specification.

The first three cases have the same meaning as the last three cases, but
they use the I<empty> string as a command keyword which does not require
a terminating colon.

In all cases, leading and trailing spaces before and after C<command> and
C<argument> will be silently removed when extracting both.

C<command> is the command keyword that specifies what the statement
should do, and has the following restrictions: It must not start with
an opening curly brace and it may not contain the characters C<=> and C<$>
or leading or trailing whitespaces.

Commands can be qualified by appending suffix strings that specify whether
or not they allow or require an argument.

The C<argument> is the commands only argument, and its interpretation is
local to the command.

If an argument is present, it is always following an equals sign, even
if nothing follows which means an argument is present but its contents
are an empty string.

=item key C<-filter> I<value list> entry type I<command without argument>

A command that does not allow an argument is defined by a string
that just contains the command keyword, such as in

            $xsa->set(
               -filter => [
                  '{8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}',
                  'command'
               ]
            );

=item key C<-filter> I<value list> entry type I<command with optional argument>

A command that allows an optional argument is defined by a string
that contains the command keyword with C<=?> appended, such as in

            $xsa->set(
               -filter => [
                  '{8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}',
                  'command=?'
               ]
            );

=item key C<-filter> I<value list> entry type I<command with mandatory argument>

A command that requires an argument is defined by a string
that contains the command keyword with C<=> appended, such as in

            $xsa->set(
               -filter => [
                  '{8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}',
                  'command='
               ]
            );

=back

=head2 NOTES - METHOD read

            while ($xsa->read) {}

This method reads the next item from the input file position to the file
that is currently bound to the XSA object.

An item is either a complete line of text, an XSA mark, or a section of text.

The latter case is only possible if one or more XSA marks are present in the
current line of text, and represents the text before/after/between the marks.

=head2 NOTES - METHOD get_text

            while ($xsa->read) {
               unless ($xsa->is_mark) {
                  $string= $xsa->get_text;
               }
            }

This function should only be used if the current item is not an XSA mark
but rather normal text.

In this case, the text returned is the text before, after or between
XSA marks in the same line, or the complete contents of a line if the
line does not contain any XSA marks.

It is not necessary to call this method for just copying the line
to the output file; C<write> alone is enough in that case.

The main purpose of this function is used to process normal text that
is contained between two known XSA marks.

Any terminating line-feed characters will be returned as part of the string.

=head2 NOTES - METHOD get_shortcut

            while ($xsa->read) {
               if ($xsa->is_mark) {
                  $shortcut= $xsa->get_shortcut;
               }
            }

This function should only be called for C<read> items that are
actually XSA-statements.

It returns the integer shortcut of the current XSA statement.

=head2 NOTES - METHOD get_guid

            while ($xsa->read) {
               if ($xsa->is_mark) {
                  $guid_string= $xsa->get_guid;
               }
            }

This function should only be called for C<read> items that are
actually XSA-statements.

It returns the string representation of the GUID of the current
XSA statement.

=head2 NOTES - METHOD get_parameters

            while ($xsa->read) {
               if ($xsa->is_mark) {
                  $parameters= $xsa->get_parameters;
               }
            }

In an XSA statement such as

            $xsa7 begin$

the parameter string will be C<' begin'>, including the leading space.

If an XSA-statement does not have any parameters, an empty string is returned.

Note that the XSA specification allows parameters only consisting of
whitespaces (except linefeed characters).

This function should only be called for C<read> items that are
actually XSA-statements.

It returns the optional parameter string of the current
XSA statement.

=head2 NOTES - METHOD get_cmd_arg

            $arg= $xsa->get_cmd_arg;

Returns the contents of the current argument, if any. This may also be an empty
string, if a statement such as C<$xsa7:command=$> is used.

If no C<=> has been specified in the XSA parameters at all, then C<undef>
will be returned, such as in C<$xsa7:command$>

Note that each command 'knows' whether or not it supports an argument and
whether or not this argument is mandatory, because of its definition
in the C<filter> option list.

=head2 NOTES - METHOD filtered_mark

            $xsa->set(
               filter => [
                  '{8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}',
                  'title=',
                  'end'
               ]
            );
            my $cmd;
            while ($xsa->read) {
               if ($cmd= $xsa->filtered_mark) {
                  print "Command '$cmd' found, argument is '", $xsa->get_cmd_arg, "'\n";
               }
               $xsa->write;
            }

This method returns C<undef> if the current item is either normal text
or an XSA mark that has not been defined in the C<filter> option list.

Otherwise the matching command keyword of the C<filter> option list
is returned, without any trailing C<=> or C<=?>.

This method has two purposes:

Firstly, it enforces the C<filter_policy> policy on the current XSA mark, if any.

That is, it changes shortcuts to GUIDs or vice versa, or it assigns new
shortcuts to GUIDs that do not already have one.

Secondly, it checks whether an XSA mark is I<supported> by the current
application, and if it is, which command and argument the current mark has.

In order to make this possible, C<filtered_mark> internally performs any
lookups of shortcuts and GUIDs as necessary to associate the current XSA
item with one of the GUIDs that have been defined in the C<filter> option list.

If C<filtered_mark> determines that the XSA mark of the current item is in
the C<filter> option list, its parses the optional parameters of the
XSA-statement and enforces one of the following formats:

            $xsa7$

The C<7> ist just a placeholder for any shortcut in this example, and works
the same if a GUID or GUID-shortcut-assignment was used instead. The
point is, that this statement represents the I<empty> command, which
does not require a colon to be present.

In order to allow the I<empty> command, the C<filter> list must contain
an empty string as a command.

            $xsa7:command$

This is the normal case of a command that does not have an argument.

            $xsa7:command=$

This is a command that does have an argument, but the argument is an empty
string.

            $xsa7:command=parameter$

This is a command that does have an argument, and the argument is I<parameter>.

In all cases, the method C<get_cmd_arg> can be used to retrieve the argument.

The careful reader of the XSA specification may have noted that XSA does not
require an XSA statement to contain a colon, an equals sign or any specific
interpretation of the mark's parameters.

While this is true, C<filtered_mark> does not support all possible XSA marks,
but only those that conform to the syntax in the above examples.

This is not a problem however, because C<filtered_mark> only examines
GUIDs more closely that are part of the C<filter> list - other GUIDs may
have any parameter structure and are not examined or supported by
C<filtered_mark>. But one is free to use use just C<read> and C<is_mark>
which do not have the restrictions of C<filtered_mark> - but also not its
power.

=head2 NOTES - METHOD write

            $xsa->open('<infile');
            open IN, '<infile';
            open OUT, '>outfile';
            $xsa->set(in => *IN{FILEHANDLE}, out => *OUT{FILEHANDLE});
            while ($xsa->read) {
               $xsa->write;
            }
            close OUT;
            close IN;

This function writes the current item to the bound file.

If no file has been bound to the XSA object, the item is returned
as a string ready for output instead.

            while ($xsa->read) {
               if ($xsa->is_mark) {
                  # process XSA mark
               }
               else {
                  # process normal text
               }
            }

This methods determines whether the item currently held within the XSA-object
is an XSA-mark or a normal text section.

It always reflects the current state of the item, which may change
due to changes applied to the item by other methods.

The main purpose of this method is to determine which kind of item
has been read by C<read>.

C<read> reads the next item, but does not return it.

This function can be used to determine the type of item actually read.

=head2 NOTES - METHOD set_parameters

            $xsa->set_parameters(':begin');

The argument is the string of optional parameters that will replace
any current XSA mark parameters.

This function can either be used to change the parameter string
of an XSA mark or to replace normal text by an XSA mark with
a specified parameter string.

Whatever has been C<read> as the current item, it will be changed
into an XSA mark.

If the current item has been a normal text section, the text
will be lost any a new, empty XSA mark will be set up; just the
the provided parameter string will be set.

See L<NOTES - METHOD set_shortcut> for details.

=head2 NOTES - METHOD set_guid

            $xsa->set_guid('{ACE69B40-F779-11d4-97C4-0050BACC8FE1}');

This function can either be used to change the GUID of an XSA mark
or to replace normal text by an XSA mark with a specified shortcut.

Whatever has been C<read> as the current item, it will be changed
into an XSA mark.

If the current item has been a normal text section, the text
will be lost any a new, empty XSA mark will be set up; just the
the provided GUID will be set.

See L<NOTES - METHOD set_shortcut> for details.

=head2 NOTES - METHOD set_shortcut

            $shortcut= 7;
            $xsa->set_shortcut($shortcut);

This function can either be used to change the shortcut of an XSA mark
or to replace normal text by an XSA mark with a specified shortcut.

Whatever has been C<read> as the current item, it will be changed
into an XSA mark.

If the current item has been a normal text section, the text
will be lost any a new, empty XSA mark will be set up; just the
the provided shortcut will be set.

This even works if there is no current item at all.

That is, this method can be used to create new XSA marks from scratch.

For example, the following text includes an XSA-mark with shortcut C<7>
after every line containing the string C<printf>:

            $xsa= new XSA;
            open IN, "<infile";
            open OUT, ">outfile";
            $xsa->set(in => *IN{FILEHANDLE}, out => *STDOUT{FILEHANDLE});
            my $add= undef;
            while ($xsa->read) {
               if (!$xsa->is_mark) {
                  my $item= $xsa->get_text;
                  $add= 1 if $item =~ /sub /;
                  if ($add && substr($item, -1) eq "\n") {
                     # Only append after the end of the line.
                     $xsa->write; # Write until line end.
                     $xsa->set_shortcut(7); # Create new XSA mark.
                     $add= 0;
                     $xsa->write; # Write mark.
                     $xsa->set_text("\n"); # Insert linefeed on next $xsa->write.
                  }
               }
               $xsa->write;
            }
            close OUT;
            close IN;

=head2 NOTES - METHOD set_text

            $xsa->set_text('replacement text');

This function can either be used to change normal text or to replace
an XSA mark by a normal text item.

Whatever has been C<read> as the current item, it will be changed
into a normal text section.

=head1 SEE ALSO

The official XSA-Specification from Guenther Brunthaler.

=head1 AUTHOR

Guenther Brunthaler
