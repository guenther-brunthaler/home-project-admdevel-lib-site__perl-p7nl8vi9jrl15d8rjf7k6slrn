# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib::RIFF;
# A Lib::RIFF represents an instance of a RIFF file.
#
# RIFF is an acronym for "Resource Interchange File Format".
# It is a generic container format that is heavily used on the Windows plaform,
# where it represents the underlying file format for .wav and .avi files.
#
# All data is organized in chunks up to 4 GB in size, including subchunks.
# The OpenDML format, as used for Mini-DV video files, however does the trick
# of concatenating multiple root chunks into the same file. This allows to
# overcome the total 4 GB limit per file.
#
# Each chunk consists of a 4-character-code ("FOURCC") tag as the chunk name,
# a 32-bit octet count for the chunk's contents, and the chunk contents itself.
# Chunks named 'RIFF' and 'LIST' may contain subchunks, and every RIFF-file
# must start with a 'RIFF' chunk.
#
# 'LIST' and 'RIFF' chunks are the same, except that 'RIFF' chunks can only
# appear at the outermost level in the file, while 'LIST' chunks must be
# nested within another 'LIST' or 'RIFF' chunk.
#
# 'RIFF' as well as 'LIST' contain the following chunk data: a FOURCC
# describing its contents, followed by a sequence of any number of arbitrary
# chunks including further 'LIST' chunks, but no 'RIFF' chunks.
#
# Regarding chunk names, names registered by some RIFF naming authority must
# be made up of all uppercase characters. Names for private use must be all
# lowercase.
#
# Names shorter than 4 characters should be right-padded
# with ASCII "SP" characters (character code 0x20).
#
# All chunks containing an odd octet-count will be padded with a single zero
# octet that is not included in its size field.
#
# Important: The methods in this class all know about that padding requirement
# and will write/expect the padding octets automatically where required.
# The client of the class thus does not need to care about the padding.
#
# (C) 2004 Guenther Brunthaler


our $VERSION= '1.0';


use Carp;
use IO::File;


# Instance variables (hash key prefix is 'ri_'):
# $self->{ri_filename}: Name of the RIFF file.
# $self->{ri_fh}: Handle of the RIFF file.
# $self->{ri_writing}: File is open for writing.
# $self->{ri_frame}: One entry for each nesting level; at least 1.
# $self->{ri_frame}->[$i]->{base}: getpos() file position of chunk size field.
# $self->{ri_frame}->[$i]->{size}:
#  Current contents octet count of the chunk. Never undef inside a chunk.
# $self->{ri_frame}->[$i]->{remaining}:
#  content octets remaining to be processed. This can be undef when writing
#  a new chunk whose size is not yet known at the end of the known file data.
#  If this is larger than {size}, then a new chunk without known size is
#  currently being written that has this value as its upper size limit.
our $maxseekdist;


# Internally used.
sub init {
   # Shared initialization for reset() and new();
   my $self= shift;
   undef $self->{ri_fh};
   undef $self->{ri_filename};
   undef $self->{ri_writing};
   $self->{ri_frame}= [{size => 0, remaining => 0}]; # File level frame.
}


# Returns the current chunk nesting level.
# 0 is outermost (file) level, outside of any chunk.
# 1 is toplevel within the RIFF chunk.
# 2 is within the first nested LIST.
# And so on.
sub nesting {
   @{shift->{ri_frame}} - 1;
}


# Returns the file name that is currently bound to the object.
# Returns undef if no open file is currently bound to the object.
sub filename {
   shift->{ri_filename};
}


# Creates a new object.
sub new {
   my($self, @open_options)= @_;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   if (@open_options) {$self->open(@open_options)}
   else {$self->init}
   $self;
}


# Internally used.
sub reset {
   # Closes a the current file if any is open and re-initializes the object
   # for processing another file.
   my $self= shift;
   my $err;
   eval {
      if (defined $self->{ri_fh}) {
         # Finish all nested frames that still may be open.
         while ($self->nesting) {
            $self->leave;
         }
         $self->finish; # Fix up the file level frame also if required.
         unless ($self->{ri_fh}->close) {
            croak "Error closing RIFF file '$self->{ri_filename}': $!";
         }
      }
   };
   $err= $@;
   $self->init;
   croak $err if $err;
}


# Close the currently open RIFF file and leave all nested chunks
# that might be open.
# Arguments:
# -preempt => 1:
#  Automatically skips over all chunks not yet enumerated. In read-only mode
#  (the standard mode) this is the default - but not for write mode.
sub close {
   my($self, %opt)= @_;
   if (defined $self->{ri_fh}) {
      if ($opt{-preempt} || !$self->{ri_writing}) {
         while ($self->nesting) {
            $self->skip if $self->remaining;
            $self->leave;
         }
         $self->skip if $self->remaining;
      }
      $self->reset;
   }
   else {
      croak "Cannot close RIFF file - no file is open";
   }
}


# Opens a RIFF file or attaches an already open file.
# Argument: Name of the file to open. The file will be closed
#  as soon as the object is destroyed or re-used.
# The remaining arguments are key/value option pairs:
# Supported options:
# -writemode => $open_args: Open the file for writing. The arguments will
#  be passed through to Perl's open() function (typically '>' or '+>').
#  It this is not specified, the file will only be opened for reading.
sub open {
   my($self, $filename, %opt)= @_;
   my($fh);
   $self->reset;
   $self->{ri_writing}= defined $opt{-writemode};
   unless (
      defined(
         $fh= new IO::File (
            $filename, $self->{ri_writing} ? $opt{-writemode} : '<'
         )
      )
   ) {
      my $opm= $self->{ri_writing} ? 'open/create' : 'open';
      croak "Cannot $opm RIFF file '$filename': $!";
   }
   unless (binmode $fh) {
      croak "Cannot open RIFF file '$filename' for octet-level access: $!";
   }
   $self->{ri_fh}= $fh;
   $self->{ri_filename}= $filename;
}


# This non-member function converts a binary FOURCC (4-octet binary string)
# into a human-readible ASCII string.
sub format_FOURCC {
   my $fourcc= shift;
   $fourcc =~ s{ [^[:print:]] }{ sprintf "\\x%02X", unpack "C", $_ }xge;
   "'$fourcc'";
}


# enter():
#  Enter a 'RIFF' or 'LIST' chunk for which an enumeration method
#  has just been called.
#  Returns the contents description FOURCC of the chunk as an ASCII string.
# enter($fourcc):
#  Like enter(), but verifies that the 'LIST' or 'RIFF' chunk has the specified
#  contents description FOURCC. Raises an exception otherwise. Returns nothing.
# For all variants, the next enum() will start enumerating the nested chunks.
sub enter {
   my($self, $fourcc)= @_;
   # Read container's contents description FOURCC.
   my $type= $self->read(4);
   if (defined($fourcc) && $type ne $fourcc) {
      croak 'RIFF container contents description FOURCC ' . format_FOURCC($type)
      . " was encountered where FOURCC " . format_FOURCC($fourcc)
      . " was actually required in RIFF file '$self->{ri_filename}'"
      ;
   }
   # Create a new nested frame as the current one. Preset to an empty chunk.
   push @{$self->{ri_frame}}, {size => 0, remaining => 0};
   return if defined $fourcc;
   $type;
}


# Leave the current chunk nesting level and return to the next outer level.
# This is the opposite of enter().
# Returns the RIFF chunk nesting level where processing returns to,
# where 0 is the file level and 1 is the RIFF top level.
# Important: leave() just re-interprets the container chunk representing the
# current nesting level as a data chunk (of the next outer nesting level)
# again. This means you have to call skip() before you can enumerate the next
# item of that higher nesting level, unless all subchunks have already been
# enumerated (or, as a special case, if none have been enumerated at all).
sub leave {
   my $self= shift;
   $self->finish;
   if ($self->nesting == 0) {
      croak "Cannot leave current nesting level in RIFF file"
      . " '$self->{ri_filename}' - already processing at top level"
      ;
   }
   pop @{$self->{ri_frame}}; # Drop current nesting level.
   $self->nesting;
}


# Internally used.
sub intern_seek_helper {
   # Perform a single relative seek with error checking.
   # Does not allow huge seeks - only what Perl's seek() provides.
   my($self, $delta)= @_;
   unless ($self->{ri_fh}->seek($delta, 1)) {
      croak "Cannot set I/O position in RIFF file '$self->{ri_fh}': $!";
   }
}


# Internally used.
sub intern_seek {
   # Seeks to a specific relative $to position, assuming that the current
   # file i/o position is relative position $from.
   # Allows huge seeks by performing multiple smaller seeks where necessary.
   my($self, $from, $to)= @_;
   return if $from == $to;
   my($end, $req);
   if ($from < $to) {
      $req= $to - $from;
      while ($req > $maxseekdist) {
         $self->intern_seek_helper($maxseekdist);
         $req-= $maxseekdist;
      }
      $self->intern_seek_helper($req);
   }
   else {
      $req= $from - $to;
      while ($req > $maxseekdist) {
         $self->intern_seek_helper(-$maxseekdist);
         $req-= $maxseekdist;
      }
      $self->intern_seek_helper(-$req);
   }
}


# Internally used.
sub intern_getpos {
   my $self= shift;
   my $pos= $self->{ri_fh}->getpos;
   unless (defined $pos) {
      croak "Cannot determine current position"
      . " within RIFF file '$self->{ri_filename}': $!"
      ;
   }
   $pos;
}


# Internally used.
sub intern_setpos {
   my($self, $pos)= @_;
   unless (defined $self->{ri_fh}->setpos($pos)) {
      croak "Cannot change current file position as required"
      . " within RIFF file '$self->{ri_filename}': $!"
      ;
   }
}


# Internally used.
sub intern_write {
   # write($data): Write string.
   # write($buf, $length, $offset): Write substr($buf, $offset, $length).
   my $self= shift;
   unless (defined $self->{ri_writing}) {
      croak "Cannot write to RIFF file '$self->{ri_filename}' that has been"
      . 'opened for reading only'
      ;
   }
   my($len, $off)= @_[1, 2];
   ($len, $off)= (length $_[0], 0) unless defined $off;
   unless ($self->{ri_fh}->write($_[0], $len, $off)) {
      croak "Writing to RIFF file '$self->{ri_filename} failed': $!";
   }
}


# Internally used.
sub intern_read {
   # read($count): Read binary string of specified length.
   # read($buf, $count, $offset): Read into substr($buf, $offset, $count).
   # $offset defaults to 0.
   my $self= shift;
   my($len, $off)= @_[1, 2];
   ($len, $off)= ($_[0], 0) unless defined $len;
   my($read, $result);
   for (;;) {
      $read= $self->{ri_fh}->read(defined($_[1]) ? $_[0] : $result, $len, $off);
      unless (defined $read) {
         croak "Reading from RIFF file '$self->{ri_filename} failed': $!";
      }
      last if $read == $len;
      if ($read == 0 && $self->{ri_fh}->eof()) {
         croak "Encountered unexpected end of RIFF file '$self->{ri_filename}'";
      }
      $off+= $read;
      $len-= $read;
   }
   return if defined $_[1];
   $result;
}


# Internally used.
sub finish {
   # Finishes processing of the current chunk.
   # Assumes i/o position is at the end of the chunk's contents data.
   # When the current chunk has yet unknown size, writes a pad octet if necessary
   # at the current position and then seeks back to the chunk header and updates
   # its chunk's size field there. Then it seeks forward beyond the end of the
   # chunk (and also beyond the padding octet, if any) and sets the number of
   # remaining chunk octets to 0.
   # When the current chunk has a known size, it verifies that the remaining
   # octets are zero. Then it skips any padding octet that may be present after
   # the end of the actual contents data.
   # In the special case that there is a known size and no chunk contents data
   # have been processed, this function seeks beyond the end of the contents
   # octets and any padding octet.
   # After doing that, the remaining parent octets are reduced by the final size
   # of the chunk, if a parent frame should exist.
   my $self= shift;
   my $f= $self->{ri_frame}->[-1];
   if (defined($f->{remaining}) && $f->{remaining} <= $f->{size}) {
      # Chunk size is already set and chunk cannot grow.
      if ($f->{size} > 0 && $f->{size} == $f->{remaining}) {
         # Special case.
         $self->skip;
      }
      if ($f->{remaining} != 0) {
         croak 'Too few octets have been processed in RIFF file'
         . " '$self->{ri_filename}': $f->{remaining} remaining chunk octets"
         . ' require processing'
         ;
      }
      if ($f->{size} & 1) {
         # Skip pad octet.
         $self->intern_read(1);
      }
   }
   else {
      # Size not yet updated in chunk header.
      if ($f->{size} & 1) {
         $self->intern_write(pack "x"); # Add padding.
      }
      my $eoc= $self->intern_getpos;
      $self->intern_setpos($f->{base}); # Seek to chunk "size" header field.
      $self->intern_write(pack "V", $f->{size}); # Update "size" field.
      $self->intern_setpos($eoc);
      $f->{remaining}= 0;
   }
   if ($self->nesting) {
      # The current chunk is also a child of some parent container chunk.
      my $p= $self->{ri_frame}->[-2]; # Parent frame.
      # Include consumed space for child's contents data into parent's offset.
      $self->intern_advance($p, $f->{size});
      if ($f->{size} & 1) {
         # Also include consumed space for child's padding octet.
         $self->intern_advance($p, 1);
      }
   }
}


# Enumerate the chunks in the current container ('RIFF' or 'LIST').
# enum():
#  Returns a list ($fourcc, $is_group) where $fourcc is the FOURCC name of the
#  chunk as an ASCII string, and $is_group indicates whether it is allowed
#  to call enter() for that chunk (it is a 'LIST' or 'RIFF' chunk).
#  Returns just undef if there are no more chunks to be enumerated.
# enum($fourcc):
#  Like enum() but verifies that another chunk actually follows and that
#  its FOURCC is the same as the specified one.
#  Raises an error otherwise. Returns nothing.
# enum($fourcc, $count):
#  Like enum($fourcc) but also requires the chunk's data contents size to
#  match the specified $count. An error will be reported otherwise.
# As a special case, this function may also be called for the outermost (file)
# level, outside of any RIFF chunks: In this case, a valid 'RIFF' chunk
# *must* be next or an error will be raised. So, only call enum at file level
# when you definitely know that another RIFF chunk has to follow (typically
# used for multi-gigaoctet OpenDML AVI files).
# Important: enum() requires that all data in the current chunk has been
# processed (i. e. the current i/o position must be the beginning of the
# new chunk - EXCEPT that no data AT ALL has been read/written from/to
# the previous chunk so far. In this case, enum() calls skip() automatically.
# In all other situations, it is up to the caller to call skip() in order to
# skip over any unprocessed octets within the current chunk.
# A special situation arises when writing a new chunk with yet unknown size:
# In this case, enum() assumes that the chunk ends at the current i/o position
# and fixes up its size before continuing. Note that even in this case, enum()
# requires that the beginning of another chunk or the end of the current
# container will be next.
sub enum {
   my($self, $fourcc, $count)= @_;
   $self->finish;
   my $f= $self->{ri_frame}->[-1];
   if ($self->nesting) {
      # The current chunk is also a child of some parent container chunk.
      my $p= $self->{ri_frame}->[-2]; # Parent frame.
      # Check whether there is space for another chunk within parent container.
      if ($p->{remaining} == 0 && !defined $fourcc) {
         # No more chunks at this nesting level!
         # Prepare for the case the client calls enum() again even though
         # undef has been returned from the previous call.
         $f->{size}= 0; # Pretend we are at the beginning of a zero-sized chunk.
         return;
      }
      # Include consumed space for next RIFF chunk header to be read from child
      # into parent.
      $self->intern_advance($p, 4 + 4);
   }
   my $ch4cc= $self->intern_read(4);
   $f->{base}= $self->intern_getpos;
   $f->{size}= $f->{remaining}= unpack "V", $self->intern_read(4);
   # At this point, the parent's frame remaining octets should be synchronized
   # with the child frame's remaining octets if such a parent frame exists.
   my $is_group;
   if ($is_group= !$self->nesting) {
      # At outermost (file) level.
      if ($ch4cc ne 'RIFF') {
         croak "A chunk of FOURCC " . format_FOURCC($ch4cc) . " has been"
         . " encountered at top-level of RIFF-file '$self->{ri_filename}'"
         . " where only a FOURCC of 'RIFF' is allowed"
         ;
      }
   }
   elsif ($ch4cc eq 'RIFF') {
      # Nested and RIFF.
      croak "Nested 'RIFF'-chunk encountered in RIFF file"
      . " '$self->{ri_filename}': RIFF syntax error"
      ;
   }
   else {
      # Nested and not RIFF.
      $is_group= $ch4cc eq 'LIST';
   }
   if (defined $fourcc) {
      unless ($ch4cc eq $fourcc) {
         croak "FOURCC " . format_FOURCC($ch4cc) . " has been encountered where"
         . " " . format_FOURCC($fourcc) . " was required - file layout mismatch"
         . " in RIFF file '$self->{ri_filename}'"
         ;
      }
      if (defined($count) && $f->{size} ne $count) {
         croak "A chunk with FOURCC " . format_FOURCC($ch4cc) . " and size"
         . "$f->{size} has been encountered where a chunk size of $count was"
         . " required - chunk size mismatch in RIFF file '$self->{ri_filename}'"
         ;
      }
      return;
   }
   ($ch4cc, $is_group);
}


# For consistence reasons, enum() requires that a chunk has completely been
# processed before it can enumerate the next chunk (except when no contents at
# all have been processed in the chunk).
# In cases where only a part of the chunk must be processed, skip() can be used
# to skip over the unprocessed remainder of the chunk in order to allow
# enum() to be called for the next chunk.
sub skip {
   my($self, $count)= @_;
   $count= $self->{ri_frame}->[-1]->{remaining} unless defined $count;
   unless (defined $count) {
      croak "Cannot skip towards end of chunk - not within any nested chunk"
      . " and file-level chunk size not yet known"
      ;
   }
   $self->advance($count);
   $self->intern_seek(0, $count);
}


# Internally used.
sub intern_advance {
   # Same as advance but allows to specify the frame to work on.
   my($self, $f, $count)= @_;
   if (defined $f->{remaining}) {
      # Chunk cannot grow unrestricted.
      if ($count > $f->{remaining}) {
         # Limit exceeded.
         if ($f->{remaining} > $f->{size}) {
            croak "Chunk growth limit exceeded by " . ($count - $f->{remaining})
            . " octets while processing RIFF file '$self->{ri_filename}'"
            ;
         }
         else {
            croak "Chunk contents too short by " . ($count - $f->{remaining})
            . " octets while processing RIFF file '$self->{ri_filename}'"
            ;
         }
      }
      # Reduce distance towards limit.
      $f->{remaining}-= $count;
   }
   if (!defined($f->{remaining}) || $f->{remaining} > $f->{size}) {
      # Growing chunk, either unlimited or bounded.
      $f->{size}+= $count; # Grow.
   }
}


# Advance does the same as skip, except it does not change the actual file i/o
# position.
# It allows direct file i/o, bypassing the read/write/skip interfaces.
# *Before* a direct read/write/seek forward is done, this function should be
# called in order to keep track and verify the validity of the file pointer
# movement to be performed.
# Actually, read(), write() and skip() are all internally implemented by
# calling advance(), followed by the appropriate direct file access operation.
sub advance {
   my $self= shift;
   $self->intern_advance($self->{ri_frame}->[-1], @_);
}


# Read some data octets from the current chunk.
# read(count):
#  Reads that many octets and moves the new current position to the first
#  octet after the last one just read. Returns the octets read as a string.
# read(string_var, count, offset):
#  Same as read(count) except that the string is not returned, but will be
#  instead be assigned as substr(<string_var>, <offset>, <count>)= result.
#  Specifying <offset> is optional and defaults to 0.
sub read {
   my $self= shift;
   $self->advance(defined($_[1]) ? $_[1] : $_[0]);
   $self->intern_read(@_);
}


# Write some data octets to the current chunk.
# Only allowed for objects that have been opened (also) for writing.
# write($data):
#  Writes that many octets and moves the new current position to the first
#  octet after the last one just written.
# write(string_var, count, offset):
#  Same as write(count) except that the string is not passed directly, but will
#  be extracted as substr(<string_var>, <offset>, <count>).
# Note that trying to write beyond the end for chunks of a known size will
# fail.
sub write {
   my $self= shift;
   $self->advance(defined($_[1]) ? $_[1] : length $_[0]);
   $self->intern_write(@_);
}


# Reset the current position where the next read/write operation
# for the current chunk will occur to the beginning of the chunk.
# When writing a new chunk with a size not yet known, this function
# will forget what has written to the chunk and assume the chunk is
# still empty.
# However, the data actually written to the file will not be discarded
# by this; they will be overwritten/skipped as write/advance is called.
# Attention: When doing this directly within 'RIFF'/'LIST' chunks (rather
# than within data chunks nested within 'RIFF'/'LIST'), the content type
# specification will then be the next octet to be overwritten!
sub rewind {
   my($self)= @_;
   my $f= $self->{ri_frame}->[-1];
   $self->intern_setpos($f->{base}); # Seek to chunk "size" header field.
   if (defined $f->{remaining}) {
      # Reading or writing a chunk of known size.
      $f->{remaining}= $f->{size};
   }
   else {
      # Writing a growing chunk.
      $f->{size}= 0;
   }
   $self->intern_seek(0, 4);
}


# Returns the number of contents data octets in the current chunk.
# This is the number of octets that need to be processed before enum() can
# be called for enumerating the next chunk.
# Returns undef for newly created chunks without a size known yet.
# Note: The returned value refers to the chunk just enumerated.
# enter() does *not* enumerate any chunk!
sub size {
   my $self= shift;
   my $f= $self->{ri_frame}->[-1];
   defined($f->{remaining}) # Not unknown size.
   && $f->{size}
   ;
}


# Returns the number of contents data octets between the current position
# and the end of the chunk.
# This is also the number of octets that are left for sequential reading,
# starting at the current position.
# A return value of 0 thus indicates 'EOF' for the current chunk.
# Returns undef for newly created chunks without a size known yet.
# Note: The returned value refers to the chunk just enumerated.
# enter() does *not* enumerate any chunk!
sub remaining {
   shift->{ri_frame}->[-1]->{remaining};
}


# Internally used.
sub check_fourcc {
   my($self, $fourcc)= @_;
   return if length($fourcc) == 4;
   croak "A FOURCC with a length of " . length($fourcc)
   . " octets instead of 4 octets has been specified"
   ;
}


# Creates a new chunk starting at the current position. May be called in the
# same situations where enum() is allowed, except that it creates a new chunk
# instead of enumerating an existing one.
# Can only create new chunks within an existing container chunk.
# Only allowed for objects that have been opened (also) for writing.
# Required argument: The FOURCC for the new chunk as an ASCII string.
# Optional second argument: The contents size for the chunk if known in
# advance. (This makes processing more efficient.)
# For chunks with initially unknown size (the default), the actual chunk size
# will be determined (and the size field will be updated) as soon as leave(),
# enum(), create() or create_and_enter() is called the next time, or when the
# object is destroyed (before closing the internally maintained file).
sub create {
   my($self, $fourcc, $fixed_size)= @_;
   $self->check_fourcc($fourcc);
   $self->finish; # Some frame already exists.
   my $f= $self->{ri_frame}->[-1]; # Current frame.
   if ($self->nesting) {
      my $p= $self->{ri_frame}->[-2]; # Parent frame.
      # Include child's new header within parent's contents.
      $self->intern_advance($p, 4 + 4);
      # Restrict child to parent's growth limit (if any).
      $f->{remaining}= $p->{remaining};
   }
   else {
      undef $f->{remaining}; # Unrestricted growth.
   }
   if (defined $fixed_size) {
      if (defined($f->{remaining}) && $f->{remaining} < $f->{size}) {
         croak "Not enough space within container for writing chunk"
         . " FOURCC '" . format_FOURCC($fourcc) . "' of size " . $f->{size}
         . " octets: Only " . $f->{remaining} . " octets are available"
         . " within parent container"
         ;
      }
      $f->{size}= $f->{remaining}= $fixed_size;
   }
   else {
      $f->{size}= 0;
   }
   if (!$self->nesting) {
      if ($fourcc ne 'RIFF') {
         croak "Only chunks of FOURCC 'RIFF' can be created at top level in RIFF"
         . " files, but FOURCC " . format_FOURCC($fourcc) . " has been specified"
         . " for RIFF file '$self->{ri_filename}' instead"
         ;
      }
   }
   else {
      if ($fourcc eq 'RIFF') {
         croak "Chunks with FOURCC 'RIFF' can only be created at top level in RIFF"
         . " files, but FOURCC 'RIFF' has been specified for RIFF file"
         . " '$self->{ri_filename}' for a nested chunk instead"
         ;
      }
   }
   if (
      defined($fixed_size) && defined($f->{remaining})
      && $fixed_size > $f->{remaining}
   ) {
      croak "Cannot create chunk FOURCC " . format_FOURCC($fourcc)
      . " of fixed size $fixed_size octets: An enclosing container chunk limits"
      . " the maximum size to $f->{remaining} octets within RIFF file"
      . " '$self->{ri_filename}'"
      ;
   }
   # Determine size to write.
   my $stw= $fixed_size;
   if (!defined($stw) && $self->nesting) {
      # Use the whole remaining space in the parent container.
      $stw= $self->{ri_frame}->[-2]->{remaining}
   }
   # As a last resort, use maximum possible RIFF chunk size
   # for unrestricted growing chunks.
   $stw= 0xffffffff unless defined $stw;
   # Write the header of the new chunk.
   $self->intern_write($fourcc);
   if (defined $fixed_size) {
      undef $f->{base};
   }
   else {
      $f->{base}= $self->intern_getpos;
   }
   # Write chunk size.
   $self->intern_write(pack 'V', $stw);
}


# Enumerate all chunks in the current container starting at the current
# position until a chunk with the specified FOURCC is encountered.
# Stops then at the first octet of the chunk contents.
# First argument: FOURCC to find.
# The remaining arguments are key/value option pairs:
# -recurse => 1:
#  A recursive search is started which includes deeper nested lists also.
# -report_success => 1:
#  Normally an exception will be raised if the chunk is not found.
#  If the option is enabled, a true/false value is returned
#  in order to indicate success rather than raising an exception.
sub find {
   my($self, $fourcc, %opt)= @_;
   $self->check_fourcc($fourcc);
   my($ch4cc, $ig);
   while (($ch4cc, $ig)= $self->enum) {
      if ($ch4cc eq $fourcc) {
         success:
         return 1 if $opt{-report_success};
         return;
      }
      if ($opt{-recurse} && $ig) {
         $self->enter;
         goto success if $self->find($fourcc, %opt, -report_success => 1);
         $self->leave;
      }
   }
   return if $opt{report_success};
   croak "Could not find required chunk FOURCC " . format_FOURCC($fourcc)
   . " in RIFF file '$self->{ri_filename}'"
   ;
}


# Enumerate all chunks in the current container starting at the current
# position until a 'LIST' container with the specified
# contents description FOURCC is encountered.
# Then enters that container and stops before enumerating its first chunk.
# First argument: Contents description FOURCC to find.
# The remaining arguments are key/value option pairs:
# -recurse => 1:
#  A recursive search is started which includes deeper nested lists also.
# -report_success => 1:
#  Normally an exception will be raised if the container is not found.
#  If the option is enabled, a true/false value is returned
#  in order to indicate success rather than raising an exception.
sub find_and_enter {
   my($self, $fourcc, %opt)= @_;
   $self->check_fourcc($fourcc);
   my($ch4cc, $ig);
   while (($ch4cc, $ig)= $self->enum) {
      if ($ig) {
         if ($self->enter eq $fourcc) {
            success:
            return 1 if $opt{-report_success};
            return;
         }
         if ($opt{-recurse}) {
            goto success if $self->find_and_enter($fourcc, %opt, -report_success => 1);
         }
         $self->leave;
      }
   }
   return if $opt{report_success};
   croak "Could not find required 'LIST' chunk with contents description FOURCC "
   . format_FOURCC($fourcc) . " in RIFF file '$self->{ri_filename}'"
   ;
}


# Like create(), but creates a container chunk instead of a plain data chunk.
# Also performs an implicit enter() on that chunk.
# The first argument this is the 'RIFF'/'LIST' contents description subtype;
# the correct primary chunk type ('RIFF' or 'LIST') will be chosen
# automatically based on the current chunk processing nesting level.
# The second argument (the optional chunk size) will usually not be specified,
# except when literally copying complete container chunks with all of its
# contents from one place to another.
# There is no return value.
sub create_and_enter {
   my($self, $fourcc, $fixed_size)= @_;
   $self->check_fourcc($fourcc);
   $self->create($self->nesting ? 'LIST' : 'RIFF', $fixed_size);
   $self->write($fourcc);
   # Create a new nested frame as the current one.
   push @{$self->{ri_frame}}, {size => 0, remaining => 0};
}


DESTROY {
   eval {shift->reset}; # Ignore any errors.
}


# Setup code.
{
   use Config;
   # No more than 32 bit offsets can be used for RIFF chunk sizes.
   # Find maximum number of bits for unsigned integer arithmetic.
   $maxseekdist= 1;
   my $i= 1;
   while ($i << 1 > $i && $maxseekdist < 32 + 1) {
      $i<<= 1;
      ++$maxseekdist;
   }
}
# Assume maximum absolute signed number has one bit less.
$maxseekdist= ((1 << $maxseekdist - 2) - 1 << 1) + 1;


1;
