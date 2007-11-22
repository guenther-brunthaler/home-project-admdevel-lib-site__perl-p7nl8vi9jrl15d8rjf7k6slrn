# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision$
# $Date$
# $Author$
# $State$
# $xsa1$


use strict;


package Lib::TOOLS::AutoGUI;
our $VERSION= '1.0';


use Carp;
use Tk;
use Tk::Font;
use Tk::Dialog;
use Tk::DialogBox;


=head1 NAME

Lib::TOOLS::AutoGUI - Standardized GUI for 'PERL_TOOLS'-utilities.

=head1 DESCRIPTION

This class provides a parameter-driven standardized GUI functionality
for most 'PERL_TOOLS'-utilities.

This class is all that is required if the following criteria apply to
a tool application program: The actual work of the tool does not
need a GUI, and the only use of the GUI is to obtain the input parameters,
such as file names.

=head1 METHODS

=cut


# Instance variables (hash key prefix is 'ag8a_'):
# $self->{ag8a_wnd}: Reference to the GUI main window object.


=head2 CONSTRUCTOR new

            use Lib::TOOLS::AutoGUI_8AEE1C23_CBA0_11D5_9920_C23CC971FBD2;
            $gui= new Lib::TOOLS::AutoGUI;

Constructs and returns a new C<Lib::TOOLS::AutoGUI> object.

=cut
sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self;
}


=head2 METHOD init

Resets an C<Lib::TOOLS::AutoGUI> object by removing any definitions
and other settings that may have already been added, and set up the
object as specified by the supplied options.

If the 'C<-run>'-option is true (which is the default), C<init> also runs
the GUI event loop. In this case C<init> will not return before the
user selects to quit.

See L<NOTES - METHOD init> for a list of all supported C<init> options.

=cut
sub init {
   my($self, %opt)= @_;
   foreach (keys %$self) {
      delete $self->{$_};
   }
   my($args, $argtype, $f, $cell, $e, @p1, $cols, @o);
   if (exists $opt{-title}) {
      @o= (-title => $opt{-title});
      $opt{-headline}= $opt{-title} unless exists $opt{-headline};
   }
   else {
      croak "Neither -title nor -headline!" unless exists $opt{-headline};
      $opt{-title}= $opt{-headline};
   }
   $self->{ag8a_wnd}= MainWindow->new(@o);
   $self->{ag8a_wnd}->Label(
      -text => $opt{-headline},
      -font => $self->{ag8a_wnd}->Font(-size => 16)
   )->pack;
   ($f= $self->{ag8a_wnd}->Frame)->pack qw(-fill x);
   $cols= 3; $cell= 0;
   while (defined($argtype= shift @{$opt{-arguments}})) {
      $args= shift @{$opt{-arguments}};
      if ($argtype eq '-input_file' || $argtype eq '-output_file') {
         $f->Label(-text => $args->{-prompt} . ':')
         ->grid(qw/-sticky e/, -row => int($cell / $cols), -col => $cell % $cols)
         ;
         ++$cell;
         $e= $f->Entry(-textvariable => $args->{-var}, -width => 40);
         $e->focus if $cell == 1;
         $e->grid(
            qw/-sticky ew/, -row => int($cell / $cols), -col => $cell % $cols
         );
         ++$cell;
         $f->Button(
            qw/-text .../,
            -command => [
               sub {
                  my($wnd, $var, $title, $exts, $ftype, $input)= @_;
                  my($file, @args);
                  @args= (
               	 -title => $title,
               	 -filetypes => [
                        [$title . 's', $exts],
                        ["All files",		'*']
               	 ]
               	);
               	$file= $input ? $wnd->getOpenFile(@args) : $wnd->getSaveFile(@args);
                  if (defined $file and $file ne '') {
                     $$var= $file;
                     chdir(
                        File::Spec->catpath(
                           (File::Spec->splitpath($file, 0))[0 .. 1]
                        )
                     );
                  }
               },
               $self->{ag8a_wnd}, $args->{-var}, $args->{-prompt}, $args->{-exts},
               defined $args->{-ftype_spec}
               ? $args->{-ftype_spec}
               :  $args->{-prompt} . 's',
               $argtype eq '-input_file'
            ]
         )->grid(qw/-pady .03c/, -row => int($cell / $cols), -col => $cell % $cols)
         ;
         ++$cell;
      }
      else {
         croak "unsupported argument type '$argtype'";
      }
   }
   ($f= $self->{ag8a_wnd}->Frame)->pack qw(-fill x -ipady .1c);
   @p1= qw/-side left -expand 1/;
   foreach $args (@{$opt{-action_buttons}}) {
      @o= (
         -text => $args->{-text},
         -command => [
            sub {
               my($self, $cmd)= @_;
               my($err, $result, @args);
               $self->{ag8a_wnd}->Busy;
               eval {
                  if (ref $cmd eq 'ARRAY') {
                     @args= @$cmd;
                     $cmd= shift @args;
                  }
                  elsif (ref $cmd ne 'CODE') {
                     croak "Invalid command argument for GUI action button!";
                  }
                  $result= &$cmd(@args);
                  $self->{ag8a_wnd}->Unbusy;
                  if (defined $result) {
                     if ($result eq '') {
                        $result= 'Operation has successfully been completed.';
                     }
                     $self->{ag8a_wnd}->messageBox(
                        -message => $result, qw/-title Success -icon info -type OK/
                     );
                  }
               };
               $err= $@;
               if ($err) {
                  $self->{ag8a_wnd}->Unbusy;
                  $self->{ag8a_wnd}->messageBox(
                     -message => $err, qw/-title Error -icon error -type OK/
                  );
               }
            },
            $self, $args->{-command}
         ]
      );
      $f->Button(@o)->pack(@p1);
   }
   $f->Button(
      qw/-text Quit/, -command => [$self->{ag8a_wnd} => 'destroy']
   )->pack(@p1);
   $self->run if !exists $opt{-run} || $opt{-run};
}


=head2 METHOD run

Runs the main loop of the GUI window that has been created by C<init>.

Note that is normally not necessary to call this method directly,
because it is invoked by C<init> unless the C<-run> option has been
set to a I<false> value.

=cut
sub run {
   my($self)= @_;
   MainLoop;
}


=head2 METHOD get_wnd

Returns a reference to the GUI main window.

This may be required for creating child windows.

=cut
sub get_wnd {
   shift->{ag8a_wnd};
}


1;


__END__


=head1 NOTES


=head2 NOTES - METHOD init

The arguments to C<init> are a list of (I<option> => I<value>)-pairs.

The following options are supported:

=over 4

=item -title

The option value is the caption string to be displayed
in the title bar of the main window of the GUI.

Defaults to the same value as the value of the C<-headline>-option.

=item -headline

The option value is the headline string to be displayed
at the top of the client area of the main window of the GUI.

It should not be too long, because it is displayed in a larger font
than the rest of the window.

Defaults to the same value as the value of the C<-title>-option.

=item -arguments

The option value is a reference to another list of options which
specifies the actual values the application needs.

The GUI will create appropriate input widgets for each value
and store it in a defined variable.

A section with details follows later in this text.

=item -action_buttons

Defines a list of action buttons to be added to the GUI that execute
user-defined commands when pressed.

These commands should do the actual work of the application.

When the user code throws an error, it will be caught by the GUI
and an error message will be displayed.

A section with details follows later in this text.

=item -run

Defines whether of not C<init> should automatically invoke the
C<run>-method before returning, which runs the event loop of the
GUI main window.

Defaults to I<true>.

=back

The argument for the C<-arguments>-option is just a reference to
another list of (I<option> => I<value>)-pairs.

The following options are supported for C<-arguments>:

=over 4

=item -input_file

This option provides information for an input file name.

The option value is a reference to an option has which
specifies the actual parameters for this input file specification.

A section with details follows later in this text.

=item -output_file

This option provides information for an output file name.

It works nearly identically to C<-input_file> and it also supports
the same options, except that a "Save As..."-file selection dialog will
be displayed instead of an "Open..."-dialog.

=back

The argument for the C<-action_buttons>-option is just a reference to
list of action button definitions.

Each action button definition in this list is a reference to an option hash.

The option hash contains several (I<option> => I<value>)-associations.

The following options are supported for each option hash of the
C<-action_buttons>-list:

=over 4

=item -text

Contains the text to be displayed on the button.

=item -command

Contains a reference to a client C<sub> to be executed when the
action-button is pressed.

If the sub needs arguments, a reference to a list can be specified instead.
In this case, the first element of the list is the reference to the sub,
and the remaining list elements are the arguments to be passed to the sub
when it will be called.

In both cases, the reference to the sub can as well be the reference to an
anonymous sub, so the following examples have all the same effect in
each of these two sections:

Without arguments.

            -command => \&mysub,
            -command => sub {&mysub},
            -command => [\&mysub],
            -command => [sub {&mysub}],

With arguments.

            -command => sub {&mysub(3.14, 0, 25)},
            -command => [\&mysub, 3.14, 0, 25],
            -command => [sub {&mysub(3.14, 0, 25)}],
            -command => [
               sub {
                  my($a1, $a2, $a3)= @_;
                  &mysub($a1, $a2, $a3);
               },
               3.14, 0, 25
            ]

No matter which of the above variants is chosen, when the GUI framework
finally calls the client function, it is run inside of an error handler.

This allows the GUI to catch any errors and display them before returning
to the GUI main window event loop.

The return value of the client-supplied function is used to display a
success message box unless it is the C<undef> value - in this case
no message is displayed.

If the client function returns an empty string, a generic default completion
message will be displayed.

Otherwise, the client function must return a text string which will be
displayed as the textual contents of a 'success' message box.

=back

The option file hash sub-argument of the C<-input_file>-option argument
supports the following option keys:

=over 4

=item -prompt

The option value is the prompt for the file which is used in the
GUI, such as C<'Functions definition file'>.

Important: As described in more detail in the C<-ftype_spec>-option,
the value of this option is also used to create the selection list in
the 'open file' dialog by appending the letter 's' to the value of that
option, unless the C<-ftype_spec>-option is also specified.

=item -ftype_spec

The option value is used to create the selection list
in the 'open file' dialog.

If this option is not specified, the value of the C<-prompt>-option is
used to create the selection list in the 'open file' dialog by appending
the letter 's' to the value of that option.

So, as in the above example, the selection list entry will be
C<'Functions definition files'> if the C<-ftype_spec>-option is omitted
and the C<-prompt>-option has been C<'Functions definition file'>.

=item -var

The option value is a reference to the variable which is to
be used to store the result.

=item -exts

The option value is a reference to a list of possible file name
extensions for the appropriate types of files, such as

            ['.txt', '.asc', '.dat']

or

            [qw/.txt .asc .dat/]

=back

=head1 EXAMPLE

The following example demonstrates how to use this object:

            use strict;
            use Lib::TOOLS::AutoGUI_8AEE1C23_CBA0_11D5_9920_C23CC971FBD2;
            my(%arg);
            ...
            Lib::TOOLS::AutoGUI->new->init(
               -title => "'Useful Tool",
               -headline => 'Useful Tool Program',
               -arguments => [
                  -input_file => {
                     -prompt => 'Text file',
                     -var => \$arg{fdfile}, -exts => ['.txt']
                  },
                  -input_file => {
                     -prompt => 'Header file',
                     -var => \$arg{fxfile}, -exts => ['.h']
                  }
                  -input_file => {
                     -prompt => 'Some other file',
                     -var => \$arg{somefile}, -exts => [qw(.dat .bin .sav)]
                  }
               ],
               -action_buttons => [
                  {
                     -text => 'Do Something',
                     -command => [
                        sub {
                           my($arg)= @_;
                           ...
                           "A report has been written!";
                        },
                        \%arg
                     ]
                  }
               ]
            );
