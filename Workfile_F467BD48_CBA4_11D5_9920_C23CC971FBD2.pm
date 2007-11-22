# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2675 $
# $Date: 2006-09-28T11:17:02.382148Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib::Workfile;
# An Lib::Workfile is a new file to open or create that will be closed when
# (and will optionally also be deleted or renamed) when the object is
# destroyed or re-used.
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;
# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 2675 $';


use HandleOptions_F467BD47_CBA4_11D5_9920_C23CC971FBD2;
use Carp;


# Instance variables (hash key prefix is 'wf_'):
# $self->{wf_object}: Name of work file or pipe command.
# $self->{wf_type}: "file" or "pipe".
# $self->{wf_file}: whether wf_object refers to a file.
# $self->{wf_pipe}: whether wf_object refers to a pipe.
# $self->{wf_newname}: Name to which it should be renamed, if any.
# $self->{wf_fh}: File handle or undef if object is idle.
# $self->{wf_transaction}: Method for reuse/destruction after closing file.
# $self->{wf_read_write}.


# Creates a new object.
sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   undef $self->{wf_transaction};
   undef $self->{wf_fh};
   $self;
}


# Internally used.
sub arghelper {
   my($self, $args)= @_;
   Lib::HandleOptions(
      -source => $args, -target => $self, -prefix => 'wf_'
      , -arguments => [qw/filename pipe/], -options => [read_write => 0]
      , -mutual_exclusions => [[qw/pipe read_write/]]
      , -rename => [filename => 'object', pipe => 'object']
   );
   $self->{wf_type}= $self->{wf_pipe} ? 'pipe' : 'file';
}


# Creates a new work file in the 'delete' transactional state
# and returns its file handle.
# If the -pipe option is uses instead of -filename, the pipe
# is opened in transactional state 'remain' instead.
# Arguments:
# -filename => name of the file to be created.
# -pipe => output pipe to be created.
# Options:
# -read_write => file will be created read/writable (default: write only).
sub create {
   my $self= shift;
   $self->commit;
   $self->arghelper(\@_);
   local *FH;
   if ($self->{wf_pipe}) {
      $self->remain_on_close;
      unless (open FH, '| ' . $self->{wf_object}) {
         croak "Cannot create pipe to command '$self->{wf_object}': $!";
      }
   } else {
      $self->delete_on_close;
      unless (
         open FH, $self->{wf_read_write} ? '+>' : '>', $self->{wf_object}
      ) {
         croak "Cannot create file '$self->{wf_object}': $!";
      }
   }
   return $self->{wf_fh}= *FH{IO};
}


# Opens an existing work file in the 'remain' transactional state
# and returns its file handle.
# Instead of a file, also an input pipe can be opened.
# Arguments:
# -filename => name of the file to be created.
# -pipe => input pipe to be opened.
# Options:
# -read_write => file will be opened read/writable (default: read only).
sub open {
   my $self= shift;
   $self->commit;
   $self->arghelper(\@_);
   $self->remain_on_close;
   local *FH;
   if ($self->{wf_pipe}) {
      unless (open FH, $self->{wf_object} . ' |') {
         croak "Cannot open pipe from command '$self->{wf_object}': $!";
      }
   } else {
      unless (
         open FH, $self->{wf_read_write} ? '+<' : '<', $self->{wf_object}
      ) {
         croak "Cannot open file '$self->{wf_object}': $!";
      }
   }
   return $self->{wf_fh}= *FH{IO};
}


# Returns the name of the original file.
# In case of a pipe, returns the command from which the pipe was created.
sub original_name {
   shift->{wf_object};
}


# Returns the name of the file into which the original file should be
# renamed when the object is committed, destroyed or reused.
# Only allowed when 'rename_on_close' or 'replace_on_close' is in effect.
sub new_name {
   shift->{wf_newname};
}


# Returns the file (or pipe) handle of the work file (or pipe)
# or undef if the object is currently in the idle state.
sub file_handle {
   shift->{wf_fh};
}


sub deleting_transactor {
   my $self= shift;
   if (unlink($self->{wf_object}) != 1) {
      croak "Cleanup failed - cannot delete $self->{wf_type}"
         . " '$self->{wf_object}': $!"
      ;
   }
}


# Changes the transactional state to 'delete'.
# This means the workfile will be closed and deleted when the object
# is destroyed or reused.
sub delete_on_close {
   my $self= shift;
   $self->{wf_transaction}= \&deleting_transactor;
}


sub renaming_transactor {
   my $self= shift;
   unless (rename($self->{wf_object}, $self->{wf_newname})) {
      croak "Cannot rename $self->{wf_type} '$self->{wf_object}' "
         . "into '$self->{wf_newname}': $!"
      ;
   }
}


# Changes the transactional state to 'rename'.
# This means the workfile will be closed and renamed to the
# specified name when the object is destroyed or reused.
# Argument: The name to which the file should be renamed to.
# Options:
# -replace => Any file which already exists under the new name will be
#  silently deleted *immediately*' instead of complaining.
#  Enabled by default.
#  Note that this is different from 'replace_on_close', because the deletion
#  is optional and will be performed immediately, and not after the file
#  has been closed.
sub rename_on_close {
   my $self= shift;
   my %opt;
   ($self->{wf_newname}, %opt)= @_;
   if (
      (!exists $opt{-replace} || $opt{-replace}) && -e $self->{wf_newname}
      && unlink($self->{wf_newname}) != 1
   ) {
      croak "Cannot delete old $self->{wf_type} which already "
         . "has the name '$self->{wf_newname}': $!"
      ;
   }
   $self->{wf_transaction}= \&renaming_transactor;
}


sub replacing_transactor {
   my $self= shift;
   if (unlink($self->{wf_newname}) != 1) {
      croak "Cleanup failed - cannot delete old $self->{wf_type}"
         . " '$self->{wf_newname}': $! - "
         . "The $self->{wf_type} which should have been renamed"
         . " to that name has been saved "
         . "with the replacement name '$self->{wf_object}' instead"
      ;
   }
   $self->renaming_transactor;
}


# Changes the transactional state to 'replace'.
# This means the workfile will be closed and renamed to the
# specified name when the object is destroyed or reused, after
# deleting a file with that name which must already exist.
# Argument: The name to which the file should be renamed to.
sub replace_on_close {
   my $self= shift;
   $self->{wf_newname}= shift;
   $self->{wf_transaction}= \&replacing_transactor;
}


# Changes the transactional state to 'remain'.
# This means the workfile will just be closed and neither be deleted
# nor renamed when the object is destroyed or reused.
sub remain_on_close {
   undef shift->{wf_transaction};
}


# Closes the workfile and perform any action determined by the current
# transactional state.
# The object will be in the idle state after this.
# Does nothing if the object is already in the idle state.
sub commit {
   my $self= shift;
   my $fh;
   return unless defined($fh= $self->{wf_fh});
   undef $self->{wf_fh};
   unless (close $fh) {
      croak "Transaction aborted - cannot close $self->{wf_type}"
         . " '$self->{wf_object}': $!"
      ;
   }
   &{$self->{wf_transaction}}($self) if defined $self->{wf_transaction};
}


DESTROY {
   shift->commit;
}


1;
