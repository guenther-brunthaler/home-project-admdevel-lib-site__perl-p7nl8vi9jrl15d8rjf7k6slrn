# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision$
# $Date$
# $Author$
# $State$
# $xsa1$


use strict;


package Lib::XSA::SectionProcessor;
# Can be used to read or update XSA sections in source texts
# that will be broken down on line-boundaries.
our $VERSION= '1.1';


use Carp;
use Lib::HandleOptions_F467BD47_CBA4_11D5_9920_C23CC971FBD2;
use Lib::ReplacementFile_F467BD49_CBA4_11D5_9920_C23CC971FBD2;
use Lib::Workfile_F467BD48_CBA4_11D5_9920_C23CC971FBD2;
use Lib::XSA_8AEE1C25_CBA0_11D5_9920_C23CC971FBD2;


# Instance variables (hash key prefix is 'spf4_'):
# $self->{spf4_work}: Lib::Workfile object.
# $self->{spf4_rplc}: Lib::ReplacementFile object.
# $self->{spf4_xsa}: XSA underlying object.
# $self->{spf4_handle_indents}: Boolean for automatic indent handling.
# $self->{spf4_indent}: The prefix string to strip if present.
# $self->{spf4_prefix}: Line prefix fetched by reader before closing mark.
# $self->{spf4_section}->{$XSA_CMD} == {}: Only section closing command.
# $self->{spf4_section}->{$XSA_CMD}->{callback}: Client callback.


{
   package IO_Callback;


   # Returns next line of current section of undef.
   # The indentation of the opening XSA-command will have been stripped.
   sub read {
      my $self= shift;
      $self= $$self;
      my($t, $x)= ('', $self->{spf4_xsa});
      # Start reading a new line.
      while ($x->read) {
         if ($x->is_mark) {
            last if $x->filtered_mark; # End of section as been reached.
            # Convert any foreign marks to text.
            $t.= $x->write(1);
         }
         # Add another text segment.
         $t.= $x->get_text;
         if (substr($t, -1) eq "\n") {
            # End of line reached.
            if ($self->{spf4_handle_indents}) {
               $x= $self->{spf4_indent};
               if (substr($t, 0, length $x) eq $x) {
                  $t= substr $t, length $x;
               }
            }
            $self->{spf4_prefix}= '';
            return $t;
         }
      }
      # We encountered a filtered mark which ends the current section.
      # Save anything we have already read from the beginning of that line,
      # so the writer can write it out if it needs to.
      $self->{spf4_prefix}= $t;
      undef;
   }


   # Writes exactly one line of text to the current section.
   # No linefeeds are allowed in the string, except for
   # an optional trailing one which will silently removed.
   # The indentation of the opening XSA-command will be prepended if
   # automatic indent handling has been enabled.
   sub write {
      my($self, $text)= @_;
      $self= $$self;
      &croak if !defined $text;
      chomp $text;
      &croak if index($text, "\n") >= 0;
      if ($text gt '' && $self->{spf4_handle_indents}) {
         $text= $self->{spf4_indent} . $text;
      }
      $self->{spf4_xsa}->set_text($text . "\n");
      $self->{spf4_xsa}->write;
   }
}


sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->{spf4_work}= new Lib::Workfile;
   $self->{spf4_rplc}= new Lib::ReplacementFile;
   $self->{spf4_xsa}= new Lib::XSA;
   $self;
}


sub preprocess {
   my($self, $opt)= @_;
   my(%sdef, $k, $s);
   $s= $self->{spf4_section}= {};
   foreach (@{$opt->{sections}}) {
      ::Lib::HandleOptions(
         -source => $_, -target => \%sdef,
         -arguments => ['begin'],
         -options => [end => undef, handler => undef]
      );
      if (defined($k= $sdef{end})) {
         $s->{$k}= {} unless exists $s->{$k};
      }
      $s->{$k}= {} unless exists $s->{$k= $sdef{begin}};
      if (defined $sdef{handler}) {
         $s->{$k}->{callback}= $sdef{handler};
      }
   }
   $self->{spf4_handle_indents}= $opt->{spf4_handle_indents};
   [$opt->{uuid}, '', keys %$s];
}


# Read a file containing XSA sections. No update is possible.
# Options:
# -filename => filename
# -uuid => the UUID the client processor wants to implement.
# -sections => array reference with section processor definitions.
# -handle_indents => Automatic indent handling. Defaults to true.
# Section processor definition is a reference to a list of:
# -begin => Command which starts the section.
# -end => Command which ends the section (optional). In any case,
#  the start of a new section will end the previous one.
# -handler => A code-ref, of a list whose first element is one.
#  The remaining list elements are then passed as parameters to that sub.
#  The sub may optionally use the 'read' method of the reader object
#  that is passed as the first argument to read all or some lines
#  of the section.
#  If this option is missing, the section will simply be skipped.
sub read {
   my $self= shift;
   $self->reset;
   my(%opt, $k, $s, $x, $p, $hi, @a, $io);
   ::Lib::HandleOptions(
      -source => \@_, -target => \%opt,
      -arguments => [qw/filename uuid sections/],
      -options => [handle_indents => 1]
   );
   ($x= $self->{spf4_xsa})->set(
      -in => $self->{spf4_work}->open(-filename => $opt{filename}),
      -line => 1,
      -filter => $self->preprocess(\%opt)
   );
   $s= $self->{spf4_section};
   $hi= $opt{spf4_handle_indents};
   $p= '';
   $io= bless \$self, 'IO_Callback';
   while ($x->read) {
      if ($x->is_mark) {
         if (($k= $x->filtered_mark) && $k ne '') {
            $k= $s->{$k};
            if (exists $k->{callback}) {
               if ($hi) {
                  $p =~ s/^(\s*).*$/$1/;
                  $self->{spf4_indent}= $p;
               }
               while ($x->read) {
                  last if !$x->is_mark && substr($x->get_text, -1) eq "\n";
               }
               $k= [$k] if ref($k= $k->{callback}) ne 'ARRAY';
               @a= @$k;
               $k= shift @a;
               croak unless ref($k) eq 'CODE';
               $x->set_text('');
               eval {&$k($io, @a)};
               $x->raise_error($@) if $@;
               redo;
            }
         }
      }
      elsif ($hi && $x->mark_follows) {
         $p= $x->get_text;
      }
   }
   $self->{spf4_work}->commit;
}


# Update a file containing XSA sections.
# Options:
# -filename => filename
# -emulate => if specified, the original file will not be replaced.
#  Instead, an additional file with the same name as the original file
#  plus the extension '.new' added will be created.
# -uuid => the UUID the client processor wants to implement.
# -sections => array reference with section processor definitions.
# -handle_indents => Automatic indent handling. Defaults to true.
# Section processor definitions have same format as for <read_pass>.
# A difference is that the handler sub can now use an additional method
# 'write' on the update object it gets as its first argument.
# The 'write'-method takes only a single argument: A line to write.
# All lines not written to a section will be removed!
sub update {
   my $self= shift;
   $self->reset;
   my(%opt, $k, $s, $x, $p, $hi, @a, $io, $sc, $par);
   ::Lib::HandleOptions(
      -source => \@_, -target => \%opt,
      -arguments => [qw/filename uuid sections/],
      -options => [handle_indents => 1, emulate => undef]
   );
   ($s= $self->{spf4_rplc})->create(
      -original_name => $opt{filename}, -emulate => $opt{emulate}
   );
   ($x= $self->{spf4_xsa})->set(
      -in => $s->read_handle, -line => 1,
      -out => $s->write_handle,
      -filter => $self->preprocess(\%opt)
   );
   $s= $self->{spf4_section};
   $hi= $opt{spf4_handle_indents};
   $p= '';
   $io= bless \$self, 'IO_Callback';
   while ($x->read) {
      if ($x->is_mark) {
         if (($k= $x->filtered_update_mark) && $k ne '') {
            $k= $s->{$k};
            if (exists $k->{callback}) {
               # Section to process.
               if ($hi) {
                  # Remember indent.
                  $p =~ s/^(\s*).*$/$1/;
                  $self->{spf4_indent}= $p;
               }
               $x->write; # Write section opening mark.
               # Transfer rest of line containing opening mark.
               while ($x->read) {
                  $x->filtered_update_mark;
                  $x->write;
                  last if !$x->is_mark && substr($x->get_text, -1) eq "\n";
               }
               # At the beginning of the next line after the opening mark.
               $k= [$k] if ref($k= $k->{callback}) ne 'ARRAY';
               @a= @$k;
               $k= shift @a;
               croak unless ref($k) eq 'CODE';
               # Before calling the client, clear the current mark (it has already
               # been written) in order to be able to differentiate between whether
               # the client code did read nothing at all or whether the closing
               # mark has been reached.
               $x->set_text('');
               # Excute client callback.
               $self->{spf4_prefix}= ''; # Line prefix of closing mark.
               eval {&$k($io, @a)};
               $x->raise_error($@) if $@;
               # Find the end of the current section.
               until ($x->filtered_update_mark) {
                  $io->read;
               }
               # We have just read the closing mark, but not output anything so far.
               # Remember mark.
               $sc= $x->get_shortcut; $par= $x->get_parameters;
               # Write line prefix first.
               $x->set_text($self->{spf4_prefix});
               $x->write;
               # Restore mark.
               $x->set_shortcut($sc); $x->set_parameters($par);
               # Continue as whether mark had just been read.
               redo;
            }
         }
      }
      elsif ($hi && $x->mark_follows) {
         $p= $x->get_text;
      }
      $x->write;
   }
   $self->{spf4_rplc}->commit;
}


sub reset {
   my $self= shift;
   $self->{spf4_work}->commit;
   $self->{spf4_rplc}->rollback;
}


DESTROY {
   shift->reset;
}


1;
