# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib::ReplacementFile;
# This object controls two files where one the contents of one
# should replace the contents of the other one on successful completion
# of the intended operation.
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;
# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 2673 $';


use Carp;
use Workfile_F467BD48_CBA4_11D5_9920_C23CC971FBD2;


# Instance variables (hash key prefix is 'rf_'):
# $self->{rf_original}: Lib::Workfile object.
# $self->{rf_new}: Lib::Workfile object.
# $self->{rf_emulate}.


# Create a new instance in idle mode.
sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->{rf_original}= new Lib::Workfile;
   $self->{rf_new}= new Lib::Workfile;
   undef $self->{rf_emulate};
   $self;
}


# Returns the file handle of the original (input) file.
sub read_handle {
   shift->{rf_original}->file_handle;
}


# Returns the file handle of the newly created output file.
sub write_handle {
   shift->{rf_new}->file_handle;
}


# Returns the file name of the original (input) file.
sub original_name {
   shift->{rf_original}->original_name;
}


# Opens the original file for reading and creates a new file for writing.
# The new file has the same name as the original file with the extension
# '.new' added. Any already existing file with that name will be overwritten.
# Unless 'commit' is called, the new file will be deleted after both
# files have been closed when the object is destroyed or reused.
# Returns a list of file handles: (write_handle, read_handle).
# Arguments:
# -original_name => The name of the original file.
# Options:
# -warn => If an error occurs, will only print a warning and return
#  (undef, undef) instead of dying if possible.
# -emulate => Will not replace the original file on commit, but rather
#  leave the original untouched and create an additional file with the
#  extension '.new' instead.
sub create {
   my($self, %opt)= @_;
   my($e, $nfname, $fname);
   $self->rollback;
   if (!defined($fname= $opt{-original_name}) || $fname eq '') {
      $e= "Missing name of file to be opened for reading";
      fail:
      croak $e unless $opt{-warn};
      warn $e;
      return undef, undef;
   }
   if (!-f $fname || !-r _) {
      $e= "Cannot open file '$fname' for reading: $!";
      goto fail;
   }
   if (
      !($self->{rf_emulate}= $opt{-emulate}) && -e ($nfname= $fname . '.bak')
   ) {
      if (unlink($nfname) != 1) {
         $e= "Backup file '$nfname' already exists and cannot be deleted: $!";
         goto fail;
      }
   }
   if (-e ($nfname= $fname . '.new')) {
      if (unlink($nfname) != 1) {
         $e= "Temporary file '$nfname' already exists and cannot be deleted: $!";
         goto fail;
      }
   }
   $self->{rf_original}->open(-filename => $fname);
   $self->{rf_new}->create(-filename => $nfname);
   $self->{rf_new}->file_handle, $self->{rf_original}->file_handle;
}


# Closes both files, renames the original file by adding the extension
# '.bak' (overwriting any already existing file with that name), and
# renames the new file to the name of the original file.
# Then the object is put into the idle state.
sub commit {
   my $self= shift;
   my $fname= $self->{rf_original}->original_name;
   unless ($self->{rf_emulate}) {
      $self->{rf_original}->rename_on_close($fname . '.bak');
   }
   $self->{rf_original}->commit;
   if ($self->{rf_emulate}) {
      $self->{rf_new}->remain_on_close;
   }
   else {
      $self->{rf_new}->rename_on_close($fname);
   }
   $self->{rf_new}->commit;
}


# Closes both files and deletes the new file unless 'commit' has already
# been called or the object is idle, in which case nothing is done.
sub rollback {
   my $self= shift;
   my $e;
   eval {$self->{rf_original}->commit};
   $e= $@;
   $self->{rf_new}->commit;
   croak $e if $e;
}


DESTROY {
   shift->rollback;
}


1;
