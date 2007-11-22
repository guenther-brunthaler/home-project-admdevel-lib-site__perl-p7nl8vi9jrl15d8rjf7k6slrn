# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2680 $
# $Date: 2006-09-03T11:52:19.969648Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


# Simple object for calling the 'system()'-function
# with error checking, dry-run and logging.


package Lib::ShellCmd;


use Carp;
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 2680 $';


# Instance data hash key prefix is 's7x1_'.
#
# $self->{s7x1_log}: undef if logging is disabled; filehandle otherwise
# $self->{s7x1_noop}: true if command execution should be suppressed
# $self->{s7x1_warn}: true if command should not croak on nonzero exit code


# Construct a new instance of a ShellCmd object.
# Any parameters specified will be passed through directly to method set().
# By default, the settings are: No logging, silent command execution,
# and calling croak() if a command fails.
sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->set(@_);
   return $self;
}


# Set or change the current settings for the object.
# Can be called at any time, not only at the beginning after object creation.
# Only the settings specified will be changed; all other settings do not
# change and keep their current settings.
# Options:
#  -log => 1
#   logs the command to STDERR before executing it. Any errors return codes
#   will also be logged before a croak() is performed.
#  -log => *FILE{IO}
#   same as above, but logs to file 'FILE' instead of to STDERR.
#  -noop => 1
#   The commands will be logged if requested, but they will not be executed.
#   Useful for testing purposes when the external commands issued by the
#   program should be checked by the developer before actually allowing
#   them to run.
sub set {
   my($self, %opt)= @_;
   if (exists $opt{-log}) {
      $self->{s7x1_log}=
         !ref($opt{-log}) && $opt{-log} ? *STDERR{IO} : $opt{-log}
      ;
   }
   $self->{s7x1_noop}= $opt{-noop} if exists $opt{-noop};
}


# Changes the behaviour of call() for the next invocation:
# It the command launches sucessfully, but returns a return code not
# equal to zero, then that return code will be returned by call()
# instead of croak()'ing as usually.
# The standard behavious will be restored after the next call() has
# returned.
# Also that call() will still croak if the command cannot be launched
# or if the command died by a signal rather than terminating by itself.
sub try_next {
   shift()->{s7x1_warn}= 1;
}


# Internally used.
sub quote_command(@) {
   return join(
      ' '
      , map {
         /[\s"]|^$/
         ? do {
            my $s= $_;
            $s =~ s/"/\\"/g;
            qq'"$s"';
         }
         : $_
      } @_
   );
}


# Internally used.
sub fail($@) {
   my $msg= shift;
   croak "$msg while executing command '", quote_command(@_), "'";
}


# Same as the builtin system() function, but operates according to the
# settings specified for the constructor.
# If called with a single string as the argument, passes the whole
# string to the shell.
# Otherwise, if the arguments are a list, uses the first list element
# as a program name, and the remaining list arguments as the program
# arguments. (No word splitting or quote processing will occur.)
# In any case, it never returns in case of a failure, but raises an
# exception via croak() instead (which may be caught via eval{}).
# Important: This function can be used as an object member function or
# as a stand-alone function.
# When called as a member function, call() operates as describes above.
# When called directly, it operates according to the defaults as specified
# for new(). Thus you never need to create an object if the defaults
# are good enough for you.
sub call {
   my $self= shift;
   return __PACKAGE__->new->call($self, @_) unless ref $self;
   croak "No command specified for execution" unless @_;
   my $fh= $self->{s7x1_log};
   print $fh 'Executing command: ', quote_command(@_), "\n" if $fh;
   unless ($self->{s7x1_noop}) {
      my $warn= $self->{s7x1_warn};
      undef $self->{s7x1_warn};
      if (system(@_) == 0) {
         if ($warn && $fh) {
            print $fh
               'Command has completed successfully: ', quote_command(@_), "\n"
            ;
         }
      } elsif ($? == -1) {
         fail $!, @_;
      } elsif ($? & 127) {
         fail
            sprintf(
               "Child process died with signal %d, %s coredump"
               , $? & 127, $? & 128 ? 'with' : 'without'
            )
            , @_
         ;
      } else {
         my $rc= $? >> 8;
         my $msg= sprintf "Child process exited with value %d", $rc;
         fail $msg, @_ unless $warn;
         if ($fh) {
            eval {fail $msg, @_};
            $msg= $@;
            chomp $msg;
            print $fh "$msg!\n";
         }
         return $rc;
      }
   }
   return 0;
}


1;
